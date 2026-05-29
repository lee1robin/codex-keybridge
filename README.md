# Codex Cross-Key Harness

Run Codex with its normal account login, while routing actual model calls through your own LiteLLM proxy and API keys.

This project packages the setup pattern proven in a local Codex Desktop environment:

- Keep Codex signed in normally.
- Add a local LiteLLM provider to Codex.
- Map Codex model slugs to different upstream keys and providers.
- Track prompt tokens, completion tokens, total tokens, spend, model, provider, and endpoint in PostgreSQL.
- Start the whole stack automatically after macOS login.

The sharp idea is simple: use Codex to modify Codex's own provider configuration, then let LiteLLM become the cross-key routing layer.

## Why This Exists

Codex Desktop normally presents model choices as Codex/OpenAI models. With this harness, those same local model slugs can be routed through a local LiteLLM proxy:

| Codex model slug | Upstream model | Upstream key |
|---|---|---|
| `gpt-5.5` | `openai/gpt-5.5` | `OPENAI_API_KEY` |
| `gpt-5.4` | `openai/gpt-5.4` | `OPENAI_API_KEY` |
| `gpt-5.4-mini` | `openai/gpt-5.4-mini` | `OPENAI_API_KEY` |
| `gpt-5.3-codex` | `openai/gpt-5.3-codex` | `OPENAI_API_KEY` |
| `gpt-5.2` | `gemini/gemini-3-flash-preview` | `GEMINI_API_KEY` |

That last row is the cross-provider trick: Codex still sees `gpt-5.2`, but LiteLLM sends it to Gemini.

## What This Project Contains

- `scripts/install-macos.sh`  
  Installs PostgreSQL, creates the LiteLLM environment, writes config files, installs the LaunchAgent, and patches Codex config.

- `scripts/verify.sh`  
  Checks Postgres, LiteLLM health, model routing, UI login, and token/spend database records.

- `scripts/uninstall.sh`  
  Stops and unloads the LiteLLM LaunchAgent. It does not delete your database or keys unless you do that manually.

- `templates/`  
  Clean config templates for `.env`, LiteLLM, LaunchAgent, and Codex.

- `docs/`  
  Design notes, troubleshooting, and the cross-key routing explanation.

## Quick Start

```zsh
git clone https://github.com/lee1robin/codex-cross-key-harness.git
cd codex-cross-key-harness
cp templates/env.example .env
```

Edit `.env` and fill in your real keys:

```zsh
OPENAI_API_KEY=...
GEMINI_API_KEY=...
LITELLM_MASTER_KEY=sk-codex-local
```

Then run:

```zsh
./scripts/install-macos.sh
./scripts/verify.sh
```

Open LiteLLM UI:

```text
http://127.0.0.1:4000/ui
```

Default UI login:

```text
Username: admin
Password: the value of LITELLM_MASTER_KEY
```

## What Gets Installed

Default paths:

```text
~/codex-litellm
~/.codex/config.toml
~/Library/LaunchAgents/com.codex-cross-key-harness.litellm.plist
```

Default ports:

```text
LiteLLM: 127.0.0.1:4000
PostgreSQL: 127.0.0.1:5432
```

## Verification

Health check:

```zsh
curl -s -S --max-time 8 http://127.0.0.1:4000/health/readiness
```

Expected:

```json
{"status":"healthy","db":"connected"}
```

Check recent spend logs:

```zsh
psql -d litellm -c 'select "startTime", model, model_group, custom_llm_provider, total_tokens, prompt_tokens, completion_tokens, spend, status from "LiteLLM_SpendLogs" order by "startTime" desc limit 8;'
```

## Important Safety Notes

Do not commit real API keys.

This repo includes only templates. Your local `.env` is ignored by Git.

Codex and LiteLLM both evolve quickly. Treat this harness as a practical setup scaffold, not a permanent compatibility guarantee.

## Known Limitation

Simple requests and token tracking work well with the cross-provider route. Complex Codex agent workflows that involve tool-call history may expose LiteLLM compatibility gaps when translating the Responses API to Gemini. See `docs/troubleshooting.md`.

## License

MIT

