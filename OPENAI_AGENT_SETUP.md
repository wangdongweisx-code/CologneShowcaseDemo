# CozyAI DeepSeek connection

The iOS app calls a local proxy rather than storing an API key in the app bundle.

The current Xcode build settings use:

`AI_PROXY_URL=http://192.168.50.154:8787/agent`

That address lets both the iOS Simulator and an iPhone on the same Wi-Fi network reach
the proxy running on this Mac. If the Mac's Wi-Fi address changes, update
`AI_PROXY_URL` in the target build settings.

## Safe local start

Double-click `Backend/OpenAIProxy/start-local.command`, paste the DeepSeek API key into
the hidden Terminal prompt, and press Return. The key exists only in that proxy process
and is never written to the project. Keep the Terminal window open while testing.

Health check: `http://127.0.0.1:8787/health`

The default model is `deepseek-v4-flash`. Set `DEEPSEEK_MODEL=deepseek-v4-pro` before
starting the proxy if higher quality is more important than response speed.

## Production

1. Deploy `Backend/OpenAIProxy/server.mjs` behind HTTPS.
2. Store `DEEPSEEK_API_KEY` only in the server environment.
3. Point `AI_PROXY_URL` to the deployed HTTPS `/agent` endpoint.
4. Add authentication, per-device rate limits, request-size limits, redacted logging,
   and spend alerts before public deployment.

Without a reachable proxy, CozyAI remains interactive and uses its local exhibition-safe
fallback responses.
