# Architecture

Codex KeyBridge registers LiteLLM as a separate Codex provider. The current recommended setup keeps Codex's official provider as the default, and uses LiteLLM only when the user explicitly switches to it.

```text
Codex Desktop
  normal account login remains intact
  default provider remains official openai
  |
  +--> Official Codex/OpenAI provider
  |
  +--> LiteLLM Local provider
  |
       OpenAI-compatible Responses API
       |
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

## Current Codex Config Shape

```toml
model = "gpt-5.5"
model_provider = "openai"
model_reasoning_effort = "medium"

[model_providers.litellm]
name = "LiteLLM Local"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
experimental_bearer_token = "sk-codex-local"
```

Use `model_provider = "openai"` for official Codex token usage. Use `model_provider = "litellm"` for local API-key routing through LiteLLM.

## Cross-Key Routing

When the `litellm` provider is active, the Codex model picker still emits familiar Codex model slugs, for example `gpt-5.2`.

LiteLLM receives that model name and resolves it through `config.yaml`:

```yaml
- model_name: gpt-5.2
  litellm_params:
    model: gemini/gemini-3-flash-preview
    api_key: os.environ/GEMINI_API_KEY
```

That means the UI name and the upstream model do not need to match. The local bridge decides which provider and key to use.

## Why The Old Provider Replacement Is Legacy

The original implementation existed before Codex exposed a supported custom provider path. It replaced or repurposed provider configuration more aggressively. New Codex releases support user-level `model_providers`, so the recommended approach is now a clean split: keep the official provider and add LiteLLM as a separate provider.

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
