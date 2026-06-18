# Current Deployment Guide

This is the current recommended Codex KeyBridge setup for a fresh Mac.

It replaces the old provider-replacement approach with the official Codex custom provider configuration path.

## Target Result

After deployment, Codex has two usable modes:

- Official mode: `model_provider = "openai"`.
- LiteLLM mode: `model_provider = "litellm"`.

Official mode keeps Codex using the normal logged-in Codex/OpenAI account.

LiteLLM mode keeps the Codex app login and UI, but sends model calls to local LiteLLM, where model aliases can use API keys from `.env`.

## Current Architecture

```text
Codex Desktop
  |
  +-- model_provider = "openai"
  |     official Codex/OpenAI path
  |
  +-- model_provider = "litellm"
        local LiteLLM on 127.0.0.1:4000
        |
        +-- gpt-5.5 -> openai/gpt-5.5 using OPENAI_API_KEY
        +-- gpt-5.4 -> openai/gpt-5.4 using OPENAI_API_KEY
        +-- gpt-5.2 -> gemini/gemini-3-flash-preview using GEMINI_API_KEY
```

## Fresh Install

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

Run the installer:

```zsh
./scripts/install-macos.sh
```

By default, this keeps Codex on the official provider:

```toml
model_provider = "openai"
```

It also registers a separate LiteLLM provider:

```toml
[model_providers.litellm]
name = "LiteLLM Local"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
experimental_bearer_token = "sk-codex-local"
```

Restart Codex Desktop after installation.

## Switch To LiteLLM Mode

Edit:

```text
~/.codex/config.toml
```

Change:

```toml
model_provider = "openai"
```

to:

```toml
model_provider = "litellm"
```

Restart Codex Desktop.

## Switch Back To Official Mode

Edit:

```text
~/.codex/config.toml
```

Set:

```toml
model_provider = "openai"
```

Restart Codex Desktop.

## Install With LiteLLM As Default

Only use this if you want Codex to immediately default to local LiteLLM routing after installation:

```zsh
CODEX_DEFAULT_PROVIDER=litellm ./scripts/install-macos.sh
```

For most users, the safer default is the normal installer without this variable.

## Verify

```zsh
./scripts/verify.sh
```

Manual service checks:

```zsh
launchctl print gui/$(id -u)/com.codex-keybridge.litellm
curl -sS --max-time 8 http://127.0.0.1:4000/health/readiness
```

Expected readiness:

```json
{"status":"healthy","db":"connected"}
```

List LiteLLM models:

```zsh
source ~/codex-litellm/.env
curl -sS --max-time 8 \
  -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
  http://127.0.0.1:4000/v1/models
```

Expected aliases include:

```text
gpt-5.5
gpt-5.4
gpt-5.2
gemini-3-flash-preview
```

## Legacy Warning

Do not use the old approach that modifies or replaces Codex internal provider YAML/config files.

The supported path is now:

```text
~/.codex/config.toml + model_providers.litellm + LiteLLM config.yaml
```

The old approach remains in project history for reference only.
