# v0.2.0 - Official Provider Split

## Important Notice

The original Codex KeyBridge approach was created before Codex exposed a stable official custom provider configuration path. That older approach depended on more invasive provider replacement behavior and should now be treated as legacy.

New Codex releases support user-level `model_providers` in `~/.codex/config.toml`, so the recommended setup has changed.

## What Changed

- Codex now defaults to the official provider: `model_provider = "openai"`.
- LiteLLM is registered as a separate optional provider: `model_providers.litellm`.
- Users can switch between official Codex token usage and local LiteLLM API-key routing by changing `model_provider`.
- The installer no longer defaults Codex to LiteLLM unless explicitly requested.
- The old internal provider/YAML replacement approach is no longer recommended.

## Recommended Setup

Use this by default:

```toml
model_provider = "openai"

[model_providers.litellm]
name = "LiteLLM Local"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
experimental_bearer_token = "sk-codex-local"
```

Switch to LiteLLM mode only when you want local API-key routing:

```toml
model_provider = "litellm"
```

## Migration Guidance

If you installed an older version, restore your Codex config so the default provider is `openai`, then keep LiteLLM as a separate provider block.

Do not continue editing Codex internal provider YAML/config files.

See `docs/current-deployment-guide.md` for the current fresh-install flow.
