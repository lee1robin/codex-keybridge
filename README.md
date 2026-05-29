# Codex KeyBridge

**Keep the Codex login. Bring your own model keys.**

Codex KeyBridge is a local routing harness for Codex Desktop. It lets Codex keep its normal account login and desktop experience, while actual model calls are routed through your own LiteLLM proxy, API keys, and providers.

In practice, this means Codex can show one model name while your local router sends the request somewhere else:

```text
Codex model picker -> local LiteLLM -> your OpenAI / Gemini / other provider keys
```

The useful trick: Codex can be configured, from inside Codex itself, to call a local provider. Once that local provider is LiteLLM, you get cross-key and cross-provider routing without changing the way you sign in to Codex.

## The Core Idea

Codex Desktop has two separate concerns:

- The user account session that powers the app experience.
- The model provider endpoint that receives inference requests.

Codex KeyBridge keeps the first one intact and changes the second one.

```text
Codex Desktop
  keeps normal login
  keeps normal UI
  keeps normal history
        |
        v
Local LiteLLM proxy
  maps Codex model slugs
  chooses provider keys
  records token usage
        |
        +--> OpenAI API key
        +--> Gemini API key
        +--> other LiteLLM-supported providers
```

## Example Routing

| Codex model slug | Actual upstream model | API key used |
|---|---|---|
| `gpt-5.5` | `openai/gpt-5.5` | `OPENAI_API_KEY` |
| `gpt-5.4` | `openai/gpt-5.4` | `OPENAI_API_KEY` |
| `gpt-5.4-mini` | `openai/gpt-5.4-mini` | `OPENAI_API_KEY` |
| `gpt-5.3-codex` | `openai/gpt-5.3-codex` | `OPENAI_API_KEY` |
| `gpt-5.2` | `gemini/gemini-3-flash-preview` | `GEMINI_API_KEY` |

That last row is the point: Codex still selects `gpt-5.2`, but your local router sends the call to Gemini.

## Why It Is Useful

- Use Codex with your own API keys.
- Route different Codex model choices to different providers.
- Keep a local, inspectable usage ledger.
- See prompt tokens, completion tokens, total tokens, spend, upstream model, provider, and endpoint.
- Keep the setup local to your Mac.
- Restart cleanly: PostgreSQL and LiteLLM can auto-start after login.

## What This Installs

Default local paths:

```text
~/codex-litellm
~/.codex/config.toml
~/Library/LaunchAgents/com.codex-keybridge.litellm.plist
```

Default local ports:

```text
LiteLLM:    127.0.0.1:4000
PostgreSQL: 127.0.0.1:5432
```

## Quick Start

```zsh
git clone https://github.com/lee1robin/codex-keybridge.git
cd codex-keybridge
cp templates/env.example .env
```

Edit `.env`:

```zsh
OPENAI_API_KEY=your-openai-api-key
GEMINI_API_KEY=your-gemini-api-key
LITELLM_MASTER_KEY=sk-codex-local
```

Install:

```zsh
./scripts/install-macos.sh
```

Restart Codex Desktop, then verify:

```zsh
./scripts/verify.sh
```

Open LiteLLM UI:

```text
http://127.0.0.1:4000/ui
```

Default login:

```text
Username: admin
Password: value of LITELLM_MASTER_KEY
```

## What The Installer Does

The macOS installer:

1. Installs `postgresql@16` with Homebrew.
2. Creates a local `litellm` database.
3. Creates `~/codex-litellm`.
4. Installs LiteLLM into a Python virtual environment.
5. Writes LiteLLM model routing config.
6. Writes a startup script that waits for PostgreSQL before launching LiteLLM.
7. Installs a macOS LaunchAgent for LiteLLM.
8. Patches `~/.codex/config.toml` to add a local LiteLLM provider.
9. Leaves your real API keys in a local `.env` file that is ignored by Git.

## Codex Config Shape

Codex KeyBridge adds a provider like this:

```toml
model = "gpt-5.5"
model_provider = "litellm"
model_reasoning_effort = "medium"

[model_providers.litellm]
name = "LiteLLM"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
requires_openai_auth = true
experimental_bearer_token = "sk-codex-local"
```

The important part is that Codex still expects its normal account login, while the model endpoint becomes local.

## Token And Spend Visibility

When LiteLLM is connected to PostgreSQL, requests are written to:

```text
LiteLLM_SpendLogs
```

Useful query:

```zsh
psql -d litellm -c 'select "startTime", model, model_group, custom_llm_provider, total_tokens, prompt_tokens, completion_tokens, spend, status from "LiteLLM_SpendLogs" order by "startTime" desc limit 8;'
```

For example, you can verify that Codex's `gpt-5.2` route actually used Gemini:

```text
model                         model_group  provider
gemini/gemini-3-flash-preview gpt-5.2      gemini
```

## Project Files

```text
scripts/install-macos.sh       full macOS installer
scripts/verify.sh              health, routing, and token logging checks
scripts/uninstall.sh           removes the LiteLLM LaunchAgent
scripts/patch_codex_config.py  safe Codex config patcher
templates/                     env, LiteLLM, LaunchAgent, and Codex templates
docs/architecture.md           how the bridge works
docs/troubleshooting.md        common failure modes
docs/pitch.md                  short launch copy and positioning
```

## Safety

Do not commit real API keys.

This repository includes only templates. Your local `.env` is ignored by Git.

Also avoid committing LiteLLM logs. They may contain prompts or tool output.

## Known Limitation

Simple requests and token tracking work well with cross-provider routes. Complex Codex agent workflows that involve tool-call history may expose compatibility gaps when LiteLLM translates Codex's Responses API calls to Gemini. See `docs/troubleshooting.md`.

## License

MIT

