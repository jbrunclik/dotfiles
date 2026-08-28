#!/usr/bin/env bash
# Claude Code Notification hook (matcher: idle_prompt).
# Fires a macOS notification when Claude Code is idle waiting for input.
# Prompt-only / observability: exit code and output are ignored by Claude Code.
#
# The message is hard-coded on purpose — the event JSON on stdin is untrusted,
# and interpolating it into osascript would be an injection vector.

osascript -e 'display notification "Claude Code is waiting for your input" with title "Claude Code" sound name "Glass"' >/dev/null 2>&1 || true
