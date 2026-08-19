#!/bin/zsh

set -u

result="$(curl --silent --show-error --max-time 60 \
  --header 'Content-Type: application/json' \
  --header 'X-Demo-Client: cologne-showcase-ios' \
  --data '{"system":"Reply briefly.","messages":[{"role":"user","content":"Reply with exactly LIVE_AGENT_OK."}],"max_tokens":32}' \
  --write-out '\n\nHTTP status: %{http_code}\n' \
  'http://localhost:8787/agent')"

print "Sending a live AI test through the local proxy..."
print
print -r -- "$result"

result_pipe="/tmp/cologne-openai-test-result.fifo"
if [[ -p "$result_pipe" ]]; then
  print -rn -- "$result" > "$result_pipe"
fi

print
print "Test finished. You can close this window."
print "Press Return to exit."
IFS= read -r
