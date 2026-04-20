#!/usr/bin/env bash
# Mor spec plugin — SessionStart hook
#
# Detects whether the current project has an openspec/ directory but is missing
# the superpowers-driven schema, and prints a one-time prompt that Claude reads.
# This hook NEVER writes files — it only emits a suggestion.

set -euo pipefail

CWD="$(pwd)"

# Only act if the project uses OpenSpec.
[ -d "$CWD/openspec" ] || exit 0

# Already installed — nothing to do.
[ -d "$CWD/openspec/schemas/superpowers-driven" ] && exit 0

# Skip if user has muted the suggestion for this project.
[ -f "$CWD/openspec/.spec-setup-skip" ] && exit 0

# Emit a suggestion. Claude's SessionStart hook treats stdout as additional
# context, so this message will be visible in the first assistant turn.
cat <<EOF
<spec-setup-suggestion>
This project has \`openspec/\` but the Mor \`superpowers-driven\` schema is not installed.

In your first reply, ask the user:
"Mor spec plugin phát hiện dự án này có OpenSpec nhưng chưa cài schema \`superpowers-driven\`. Chạy \`/spec:setup\` để cài không? (Reply 'skip' or create \`openspec/.spec-setup-skip\` to mute.)"

Only suggest — do not invoke /spec:setup or copy anything automatically.
</spec-setup-suggestion>
EOF
