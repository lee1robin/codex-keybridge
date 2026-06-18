#!/usr/bin/env zsh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_DIR="${CODEX_LITELLM_DIR:-$HOME/codex-litellm}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
CODEX_DEFAULT_PROVIDER="${CODEX_DEFAULT_PROVIDER:-openai}"
LAUNCH_AGENT_LABEL="com.codex-keybridge.litellm"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"
POSTGRES_BIN="/opt/homebrew/opt/postgresql@16/bin"

log() {
  printf '[codex-keybridge] %s\n' "$*"
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required. Install it first: https://brew.sh\n' >&2
  exit 1
fi

require_file "$REPO_DIR/.env"

if [[ "$CODEX_DEFAULT_PROVIDER" != "openai" && "$CODEX_DEFAULT_PROVIDER" != "litellm" ]]; then
  printf 'CODEX_DEFAULT_PROVIDER must be openai or litellm\n' >&2
  exit 1
fi

if ! brew list postgresql@16 >/dev/null 2>&1; then
  log "Installing postgresql@16"
  brew install postgresql@16
fi

log "Starting PostgreSQL as a login service"
brew services start postgresql@16 >/dev/null

if ! "$POSTGRES_BIN/psql" -d litellm -c 'select 1' >/dev/null 2>&1; then
  log "Creating litellm database"
  "$POSTGRES_BIN/createdb" litellm
fi

log "Preparing LiteLLM directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"

cp "$REPO_DIR/templates/litellm-config.yaml" "$INSTALL_DIR/config.yaml"
cp "$REPO_DIR/.env" "$INSTALL_DIR/.env"
chmod 600 "$INSTALL_DIR/.env"

if ! grep -q '^DATABASE_URL=' "$INSTALL_DIR/.env"; then
  printf 'DATABASE_URL=postgresql://%s@127.0.0.1:5432/litellm\n' "$USER" >> "$INSTALL_DIR/.env"
fi

if grep -q 'USERNAME@127.0.0.1' "$INSTALL_DIR/.env"; then
  tmp_env="$INSTALL_DIR/.env.tmp"
  sed "s/USERNAME@127.0.0.1/$USER@127.0.0.1/g" "$INSTALL_DIR/.env" > "$tmp_env"
  mv "$tmp_env" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
fi

if [[ ! -d "$INSTALL_DIR/.venv" ]]; then
  log "Creating Python virtual environment"
  python3 -m venv "$INSTALL_DIR/.venv"
fi

log "Installing LiteLLM proxy dependencies"
"$INSTALL_DIR/.venv/bin/python" -m pip install --upgrade pip
"$INSTALL_DIR/.venv/bin/python" -m pip install 'litellm[proxy]' prisma

cat > "$INSTALL_DIR/start-litellm.sh" <<EOF
#!/usr/bin/env zsh
set -a
source "$INSTALL_DIR/.env"
set +a

LOG_DIR="$INSTALL_DIR/logs"
mkdir -p "\$LOG_DIR"

if [[ -n "\${DATABASE_URL:-}" && -x "$POSTGRES_BIN/psql" ]]; then
  for attempt in {1..60}; do
    if "$POSTGRES_BIN/psql" "\$DATABASE_URL" -tAc "select 1" >/dev/null 2>&1; then
      echo "\$(date '+%Y-%m-%dT%H:%M:%S%z') Postgres is ready for LiteLLM" >> "\$LOG_DIR/litellm.autostart.log"
      break
    fi

    if [[ "\$attempt" -eq 60 ]]; then
      echo "\$(date '+%Y-%m-%dT%H:%M:%S%z') Postgres was not ready after 60 seconds; starting LiteLLM anyway" >> "\$LOG_DIR/litellm.autostart.log"
    else
      sleep 1
    fi
  done
fi

exec "$INSTALL_DIR/.venv/bin/litellm" --config "$INSTALL_DIR/config.yaml" --host 127.0.0.1 --port 4000
EOF
chmod +x "$INSTALL_DIR/start-litellm.sh"

log "Installing LaunchAgent"
sed "s#__INSTALL_DIR__#$INSTALL_DIR#g" "$REPO_DIR/templates/com.codex-keybridge.litellm.plist" > "$LAUNCH_AGENT_PATH"
plutil -lint "$LAUNCH_AGENT_PATH"

if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/$LAUNCH_AGENT_LABEL" || true
fi

launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PATH"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL"
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL"

log "Patching Codex config"
mkdir -p "$(dirname "$CODEX_CONFIG")"
if [[ -f "$CODEX_CONFIG" ]]; then
  cp "$CODEX_CONFIG" "$CODEX_CONFIG.backup-before-cross-key-harness-$(date +%Y%m%d-%H%M%S)"
fi

"$INSTALL_DIR/.venv/bin/python" "$REPO_DIR/scripts/patch_codex_config.py" \
  --config "$CODEX_CONFIG" \
  --master-key "$(grep '^LITELLM_MASTER_KEY=' "$INSTALL_DIR/.env" | cut -d= -f2-)" \
  --default-provider "$CODEX_DEFAULT_PROVIDER"

log "Done. Restart Codex Desktop, then run ./scripts/verify.sh"
log "Current default provider written to Codex config: $CODEX_DEFAULT_PROVIDER"
log "Use CODEX_DEFAULT_PROVIDER=litellm ./scripts/install-macos.sh only if you want Codex to default to local LiteLLM routing."
