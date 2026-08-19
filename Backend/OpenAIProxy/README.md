# Air 1 Agent Proxy + Local RAG

This folder runs the server-side DeepSeek connection used by the iOS demo. The API key stays on the Mac and is never packaged into the app.

## Start

1. Double-click `start-local.command`.
2. Paste the DeepSeek API key when Terminal asks for it. The input is hidden.
3. Keep that Terminal window open while using the Agent in the app.
4. Open `http://127.0.0.1:8787/health` on the Mac. A healthy response includes `provider`, `model`, `knowledgeVersion`, and `knowledgeChunks`.

The Xcode project currently points the app to `http://192.168.50.154:8787/agent`. If the Mac's Wi-Fi address changes, update `AI_PROXY_URL` in the Xcode target build settings.

## Knowledge base

`knowledge/air1-knowledge.json` contains local, searchable excerpts created from:

- Air 1 Quick Start Guide V1.9
- Air 1 User Manual V2.0, model BP334

The proxy retrieves the five most relevant chunks for each question and sends only those excerpts to DeepSeek. Replies include local source labels with the guide/manual page and section. The original PDF files are not packaged into the app or served over the network.

## Security

- Never put a DeepSeek key in Swift, Xcode build settings, Info.plist, or the knowledge JSON.
- `start-local.command` keeps the key only in the server process environment.
- The Agent endpoint accepts requests only from the demo client's expected header.
- Stop the Terminal process when the exhibition demo is not in use.
- If a key was shared in chat or another non-secret channel, rotate it after testing.
