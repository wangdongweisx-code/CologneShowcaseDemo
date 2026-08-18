#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
cd "$script_dir"

export AI_PROVIDER="${AI_PROVIDER:-deepseek}"

if [[ "$AI_PROVIDER" == "deepseek" && -z "${DEEPSEEK_API_KEY:-}" ]]; then
  print "Enter your DeepSeek API key (input is hidden):"
  IFS= read -r -s DEEPSEEK_API_KEY
  print
  if [[ -z "$DEEPSEEK_API_KEY" ]]; then
    print "No API key entered. Proxy was not started."
    exit 1
  fi
  export DEEPSEEK_API_KEY
elif [[ "$AI_PROVIDER" == "openai" && -z "${OPENAI_API_KEY:-}" ]]; then
  print "Enter your OpenAI API key (input is hidden):"
  IFS= read -r -s OPENAI_API_KEY
  print
  if [[ -z "$OPENAI_API_KEY" ]]; then
    print "No API key entered. Proxy was not started."
    exit 1
  fi
  export OPENAI_API_KEY
fi

print "Starting the local CozyAI $AI_PROVIDER proxy..."
print "Keep this window open while testing the app in Xcode."
exec /usr/bin/env node "$script_dir/server.mjs"
