# Troubleshooting

## LiteLLM UI Says "Not connected to DB"

Check:

```zsh
brew services list
curl -s -S --max-time 8 http://127.0.0.1:4000/health/readiness
```

If health does not show `db: connected`, check your `.env`:

```zsh
grep '^DATABASE_URL=' ~/codex-litellm/.env
```

Then verify Postgres:

```zsh
/opt/homebrew/opt/postgresql@16/bin/psql -d litellm -c 'select 1;'
```

## LiteLLM Starts Before PostgreSQL

The generated `start-litellm.sh` waits up to 60 seconds for Postgres.

Check:

```zsh
tail -n 20 ~/codex-litellm/logs/litellm.autostart.log
```

## Codex Keeps Reconnecting With Gemini Route

Simple chat calls may work while complex agent calls fail. Check:

```zsh
tail -n 160 ~/codex-litellm/logs/litellm.err.log
```

If you see:

```text
Missing corresponding tool call for tool response message
```

the likely issue is Responses API tool-call history translation between Codex, LiteLLM, and Gemini. This is not a key or database problem.

## Token Counts Are Missing

Confirm LiteLLM is connected to the DB:

```zsh
curl -s -S --max-time 8 http://127.0.0.1:4000/health/readiness
```

Then check:

```zsh
/opt/homebrew/opt/postgresql@16/bin/psql -d litellm -c 'select count(*) from "LiteLLM_SpendLogs";'
```

## `gh` Cannot Push

Log in:

```zsh
gh auth login
```

Then create the remote repository:

```zsh
gh repo create lee1robin/codex-keybridge --public --source=. --remote=origin --push
```
