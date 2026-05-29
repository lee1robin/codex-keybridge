#!/usr/bin/env zsh
set -euo pipefail

LABEL="com.codex-keybridge.litellm"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/$LABEL"
fi

rm -f "$PLIST"

cat <<'MSG'
LiteLLM LaunchAgent removed.

This script did not delete:
- ~/codex-litellm
- PostgreSQL
- the litellm database
- ~/.codex/config.toml backups

Remove those manually if you are sure you no longer need them.
MSG
