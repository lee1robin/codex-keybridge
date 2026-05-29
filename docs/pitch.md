# Codex KeyBridge Pitch

## One-Liner

Keep the Codex login. Bring your own model keys.

## Short Description

Codex KeyBridge is a local LiteLLM harness that lets Codex Desktop keep its normal account login while routing actual model calls through your own API keys, providers, and usage ledger.

## Longer Description

Codex Desktop has a great app experience, but model routing is usually tied to the models shown in the app. Codex KeyBridge separates the account session from the inference endpoint. Codex keeps its normal login, while a local LiteLLM proxy receives model calls, maps Codex model slugs to upstream providers, and records token usage in PostgreSQL.

The result is a practical cross-key setup: one Codex model choice can use an OpenAI key, another can use Gemini, and every request can be inspected locally.

## Launch Post

I built Codex KeyBridge: a local harness for routing Codex Desktop model calls through your own LiteLLM proxy.

The fun part: Codex keeps its normal login and UI, but actual inference calls go through a local provider that you control.

That makes cross-key routing possible:

- `gpt-5.5` -> OpenAI key
- `gpt-5.4` -> OpenAI key
- `gpt-5.2` -> Gemini key
- everything logged to PostgreSQL with prompt/completion/total tokens and spend

It is basically a small bridge between Codex's model provider config and LiteLLM's routing layer.

Repo: https://github.com/lee1robin/codex-keybridge

## GitHub Description

Keep Codex Desktop login intact while routing model calls through your own LiteLLM proxy, API keys, and token ledger.

## Suggested Topics

- codex
- litellm
- openai
- gemini
- model-routing
- bring-your-own-key
- ai-agents
- macos
- token-tracking

