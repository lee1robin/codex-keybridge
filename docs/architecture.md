# Architecture

Codex KeyBridge inserts LiteLLM between Codex Desktop and upstream model providers.

```text
Codex Desktop
  normal account login remains intact
  |
  | OpenAI-compatible Responses API
  v
Local LiteLLM proxy
  model alias routing
  cross-key dispatch
  spend/token logging
  |
  +--> OpenAI API key -> GPT models
  |
  +--> Gemini API key -> Gemini models
  |
  v
PostgreSQL
  LiteLLM_SpendLogs
```

## Cross-Key Routing

The Codex model picker still emits familiar Codex model slugs, for example `gpt-5.2`.

LiteLLM receives that model name and resolves it through `config.yaml`:

```yaml
- model_name: gpt-5.2
  litellm_params:
    model: gemini/gemini-3-flash-preview
    api_key: os.environ/GEMINI_API_KEY
```

That means the UI name and the upstream model do not need to match. The local bridge decides which provider and key to use.

## Why Keep `requires_openai_auth = true`

Codex Desktop still expects its normal account session for UI behavior, history, and desktop integration. The harness keeps that login flow intact, while changing the model provider endpoint to local LiteLLM.

## Token Tracking

When `database_url` is configured in LiteLLM, the proxy writes request records to PostgreSQL. The most useful table is:

```text
LiteLLM_SpendLogs
```

It includes:

- upstream model
- Codex-facing model group
- provider
- total tokens
- prompt tokens
- completion tokens
- spend
- endpoint
- request status
