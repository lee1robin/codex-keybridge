#!/usr/bin/env zsh
set -euo pipefail

INSTALL_DIR="${CODEX_LITELLM_DIR:-$HOME/codex-litellm}"
POSTGRES_BIN="/opt/homebrew/opt/postgresql@16/bin"

log() {
  printf '[verify] %s\n' "$*"
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

require_file "$INSTALL_DIR/.env"
set -a
source "$INSTALL_DIR/.env"
set +a

log "PostgreSQL service"
brew services list | grep 'postgresql@16'

log "LiteLLM health"
curl -s -S --max-time 8 http://127.0.0.1:4000/health/readiness
printf '\n'

log "Models endpoint"
curl -s -S --max-time 8 \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  http://127.0.0.1:4000/v1/models >/tmp/codex-cross-key-models.json
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("/tmp/codex-cross-key-models.json").read_text())
ids = [item.get("id") for item in data.get("data", [])]
print("models:", ", ".join(ids[:20]))
for required in ["gpt-5.5", "gpt-5.2"]:
    if required not in ids:
        raise SystemExit(f"missing model: {required}")
PY

log "Test gpt-5.2 route"
curl -s -S --max-time 30 \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  -d '{"model":"gpt-5.2","messages":[{"role":"user","content":"Reply with exactly: token tracking test"}],"max_tokens":30}' \
  >/tmp/codex-cross-key-response.json
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("/tmp/codex-cross-key-response.json").read_text())
usage = data.get("usage")
print("usage:", usage)
if not usage or not usage.get("total_tokens"):
    raise SystemExit("missing usage totals")
PY

log "Recent spend logs"
"$POSTGRES_BIN/psql" -d litellm -c 'select "startTime", model, model_group, custom_llm_provider, total_tokens, prompt_tokens, completion_tokens, spend, status from "LiteLLM_SpendLogs" order by "startTime" desc limit 8;'

log "OK"

