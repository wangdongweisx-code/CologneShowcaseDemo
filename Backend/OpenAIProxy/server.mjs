import http from "node:http";
import { readFileSync } from "node:fs";

const port = Number(process.env.PORT || 8787);
const host = process.env.HOST || "0.0.0.0";
const provider = (process.env.AI_PROVIDER || "deepseek").toLowerCase();
const providerConfig = {
  deepseek: {
    apiKey: process.env.DEEPSEEK_API_KEY,
    endpoint: process.env.DEEPSEEK_BASE_URL || "https://api.deepseek.com/chat/completions",
    model: process.env.DEEPSEEK_MODEL || "deepseek-v4-flash",
  },
  openai: {
    apiKey: process.env.OPENAI_API_KEY,
    endpoint: "https://api.openai.com/v1/responses",
    model: process.env.OPENAI_MODEL || "gpt-5.6-luna",
  },
};

const config = providerConfig[provider];
let requestCount = 0;
let lastRequestAt = null;
let lastUpstreamStatus = null;

if (!config) {
  throw new Error(`Unsupported AI_PROVIDER: ${provider}`);
}

const knowledgeBase = JSON.parse(
  readFileSync(new URL("./knowledge/air1-knowledge.json", import.meta.url), "utf8"),
);

const stopWords = new Set([
  "a", "an", "and", "are", "as", "at", "be", "can", "do", "does", "for",
  "from", "how", "i", "in", "is", "it", "my", "of", "on", "or", "the",
  "this", "to", "what", "when", "where", "with", "you", "your",
]);

const queryExpansions = [
  [/flange|fit|size|insert|法兰|喇叭罩|罩杯|尺寸|乳头/, "flange nipple measure size insert comfort alignment"],
  [/suction|vacuum|weak|吸力|负压|吸不动/, "suction vacuum seal valve diaphragm assembly air leakage"],
  [/clean|wash|disinfect|steriliz|清洗|清洁|消毒|微波/, "clean wash disinfect sterilize microwave milk contact parts dry"],
  [/charg|battery|power|充电|电池|电量|开机/, "charging battery indicator cable power on off"],
  [/connect|bluetooth|pair|app|连接|蓝牙|配对|应用/, "app connect bluetooth pairing official app"],
  [/pain|hurt|sore|疼|痛|红肿|不适/, "pain discomfort nipple flange size suction stop healthcare professional"],
  [/wear|align|bra|佩戴|对齐|文胸/, "wearing align nipple center flange no gap bra"],
  [/leak|spill|漏奶|漏气|洒|倒奶/, "milk leak air leakage transfer pour collector seal assembly"],
  [/mode|level|档位|模式|刺激|吸乳/, "mode stimulation expression mixed suction level controls"],
  [/store|storage|freeze|milk|储奶|母乳|冷藏|冷冻/, "breast milk storage refrigerator freezer thaw"],
];

function normalizeForSearch(value) {
  return String(value || "")
    .normalize("NFKC")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function tokenize(value) {
  const normalized = normalizeForSearch(value);
  const tokens = normalized.match(/[a-z0-9]+|[\p{Script=Han}]/gu) || [];
  return [...new Set(tokens.filter((token) => token.length > 1 && !stopWords.has(token)))];
}

const indexedKnowledge = knowledgeBase.chunks.map((chunk) => ({
  ...chunk,
  normalized: normalizeForSearch(`${chunk.section} ${chunk.text}`),
  titleNormalized: normalizeForSearch(chunk.section),
}));

function retrieveKnowledge(query, limit = 5) {
  const normalizedQuery = normalizeForSearch(query);
  const expanded = queryExpansions
    .filter(([pattern]) => pattern.test(normalizedQuery))
    .map(([, words]) => words)
    .join(" ");
  const queryTokens = tokenize(`${normalizedQuery} ${expanded}`);

  return indexedKnowledge
    .map((chunk) => {
      let score = 0;
      for (const token of queryTokens) {
        const bodyHits = chunk.normalized.split(token).length - 1;
        if (bodyHits > 0) score += Math.min(bodyHits, 4);
        if (chunk.titleNormalized.includes(token)) score += 3;
      }
      if (normalizedQuery.length > 5 && chunk.normalized.includes(normalizedQuery)) score += 8;
      if (chunk.source.includes("Quick Start")) score *= 1.08;
      return { chunk, score };
    })
    .filter((item) => item.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

function ragContext(matches) {
  if (matches.length === 0) return "";
  const excerpts = matches.map(({ chunk }, index) =>
    `[${index + 1}] ${chunk.source}, page ${chunk.page}, ${chunk.section}\n${chunk.text}`,
  );
  return [
    "Use the following Air 1 product documentation as the primary source for product facts.",
    "Answer in the user's language. Cite factual guidance inline using [1], [2], etc.",
    "If the excerpts do not support a product-specific claim, say that the supplied Air 1 materials do not confirm it.",
    "Do not invent specifications, medical advice, or troubleshooting steps.",
    "",
    ...excerpts,
  ].join("\n\n");
}

function escapeHTML(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

if (!config.apiKey) {
  const variable = provider === "deepseek" ? "DEEPSEEK_API_KEY" : "OPENAI_API_KEY";
  throw new Error(`Set ${variable} before starting the proxy.`);
}

function sendJSON(response, status, value) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  response.end(JSON.stringify(value));
}

function normalizedMessages(body) {
  if (Array.isArray(body.messages) && body.messages.length > 0) {
    return body.messages
      .filter((message) => message && typeof message.content === "string")
      .map((message) => ({
        role: ["system", "user", "assistant"].includes(message.role) ? message.role : "user",
        content: message.content,
      }));
  }

  const messages = [];
  if (typeof body.instructions === "string" && body.instructions.trim()) {
    messages.push({ role: "system", content: body.instructions });
  }
  if (typeof body.input === "string" && body.input.trim()) {
    messages.push({ role: "user", content: body.input });
  }
  return messages;
}

async function callDeepSeek(body) {
  const messages = normalizedMessages(body);
  const latestUserMessage = [...messages].reverse().find((message) => message.role === "user");
  const ragMatches = retrieveKnowledge(latestUserMessage?.content || "", 5);
  const documentation = ragContext(ragMatches);
  const systemParts = [];
  if (typeof body.system === "string" && body.system.trim()) {
    systemParts.push(body.system.trim());
  }
  if (documentation) systemParts.push(documentation);
  if (systemParts.length > 0) {
    messages.unshift({ role: "system", content: systemParts.join("\n\n") });
  }
  if (messages.length === 0) {
    throw new Error("At least one message is required.");
  }

  const upstream = await fetch(config.endpoint, {
    method: "POST",
    headers: {
      authorization: `Bearer ${config.apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: config.model,
      messages,
      stream: false,
      thinking: { type: "disabled" },
      max_tokens: Number(body.max_tokens || body.max_output_tokens || 600),
    }),
  });

  const text = await upstream.text();
  lastUpstreamStatus = upstream.status;
  if (!upstream.ok) {
    return { upstream, text: sanitizeUpstreamError(text) };
  }

  const result = JSON.parse(text);
  const answer = result.choices?.[0]?.message?.content?.trim();
  if (!answer) {
    throw new Error("DeepSeek returned an empty response.");
  }

  return {
    upstream,
    text: JSON.stringify({
      text: answer,
      sources: ragMatches.slice(0, 3).map(({ chunk }) => ({
        title: `${chunk.source} · p.${chunk.page} · ${chunk.section}`,
        url: `momcozy://air1-knowledge/${encodeURIComponent(chunk.id)}`,
      })),
      provider,
      model: result.model || config.model,
    }),
  };
}

function sanitizeUpstreamError(text) {
  let message = "The AI provider rejected the request.";
  try {
    const parsed = JSON.parse(text);
    message = parsed?.error?.message || message;
  } catch {
    if (typeof text === "string" && text.trim()) message = text.trim();
  }
  message = String(message).replace(/sk-[A-Za-z0-9_-]+/g, "[redacted]");
  return JSON.stringify({ error: { message } });
}

async function callOpenAI(body) {
  const upstream = await fetch(config.endpoint, {
    method: "POST",
    headers: {
      authorization: `Bearer ${config.apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const text = await upstream.text();
  lastUpstreamStatus = upstream.status;
  return { upstream, text };
}

const server = http.createServer(async (request, response) => {
  if (request.method === "GET" && request.url === "/health") {
    sendJSON(response, 200, {
      ok: true,
      provider,
      model: config.model,
      knowledgeVersion: knowledgeBase.version,
      knowledgeChunks: knowledgeBase.chunks.length,
      requestCount,
      lastRequestAt,
      lastUpstreamStatus,
    });
    return;
  }

  if (request.method !== "POST" || request.url !== "/agent") {
    sendJSON(response, 404, { error: { message: "Not found" } });
    return;
  }

  if (request.headers["x-demo-client"] !== "cologne-showcase-ios") {
    sendJSON(response, 403, { error: { message: "Unknown demo client" } });
    return;
  }

  try {
    requestCount += 1;
    lastRequestAt = new Date().toISOString();
    const chunks = [];
    let received = 0;
    for await (const chunk of request) {
      received += chunk.length;
      if (received > 1_000_000) throw new Error("Request too large");
      chunks.push(chunk);
    }

    const body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    const { upstream, text } = provider === "deepseek"
      ? await callDeepSeek(body)
      : await callOpenAI(body);

    process.stdout.write(
      `[${lastRequestAt}] iOS Agent request -> ${provider} ${upstream.status}\n`,
    );
    response.writeHead(upstream.status, {
      "content-type": upstream.ok ? "application/json; charset=utf-8" : (upstream.headers.get("content-type") || "application/json"),
      "cache-control": "no-store",
    });
    response.end(text);
  } catch (error) {
    sendJSON(response, 400, { error: { message: error.message } });
  }
});

server.listen(port, host, () => {
  process.stdout.write(`${provider} proxy listening at http://${host}:${port}/agent\n`);
  process.stdout.write(`Health check: http://127.0.0.1:${port}/health\n`);
});
