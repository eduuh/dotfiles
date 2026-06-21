#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook — capture the live model for bn.
#
# The model isn't in the environment and Claude Code hooks don't carry it past
# SessionStart, so mid-session switches (/model, fast-mode) are invisible to env.
# But the transcript records each assistant message's model. This hook reads the
# newest one and writes it to the per-session file bn's detect_model() reads
# (<state>/model-<session_id>), so the branch note's `models` list tracks switches.
#
# Wired as a UserPromptSubmit hook (fires every prompt). Always exits 0 — a capture
# failure must never block the prompt. No-op without jq or a usable transcript.

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0

# Newest assistant message wins (transcript is append-only JSONL).
model=$(tac "$tp" 2>/dev/null | grep -m1 '"type":"assistant"' \
    | jq -r '.message.model // empty' 2>/dev/null)
[ -n "${model:-}" ] || exit 0

# Mirror bn's state_dir(): BN_STATE_DIR → XDG_STATE_HOME/bn → ~/.local/state/bn.
if [ -n "${BN_STATE_DIR:-}" ]; then
    state="$BN_STATE_DIR"
elif [ -n "${XDG_STATE_HOME:-}" ]; then
    state="$XDG_STATE_HOME/bn"
else
    state="$HOME/.local/state/bn"
fi

mkdir -p "$state" 2>/dev/null || exit 0
printf '%s' "$model" > "$state/model-$sid" 2>/dev/null || true
exit 0
