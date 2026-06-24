#!/usr/bin/env bash
# UserPromptSubmit hook for Claude Code AND GitHub Copilot CLI — capture the live
# model into the file bn's detect_model() reads, so the branch note's `models` list
# records mid-session model switches (the model isn't in the env; harness hooks don't
# carry it). Reads the hook JSON on stdin. Always exits 0 — never block a prompt.
#
#   Claude Code: payload has .transcript_path + .session_id; the newest assistant
#     message in the transcript carries .message.model. Keyed by session id
#     (bn reads via $CLAUDE_CODE_SESSION_ID).
#   Copilot CLI: payload has .sessionId + .cwd; the newest assistant.message in
#     ~/.copilot/session-state/<sessionId>/events.jsonl carries .data.model. Copilot
#     exposes no session id to its tool env, so key by cwd (bn reads via its own cwd).

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

# bn state dir: BN_STATE_DIR wins; else ask bn (resolves <personal_root>/<machine>/state).
if [ -n "${BN_STATE_DIR:-}" ]; then state="$BN_STATE_DIR"
else state=$(bn --state-dir 2>/dev/null); fi
[ -n "$state" ] || exit 0

write_model() { # <basename> <model>
    [ -n "$2" ] || return 0
    mkdir -p "$state" 2>/dev/null || return 0
    printf '%s' "$2" > "$state/$1" 2>/dev/null || true
}

# --- Claude Code: model from the transcript, keyed by session id ---
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$tp" ] && [ -f "$tp" ]; then
    sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
    model=$(tac "$tp" 2>/dev/null | grep -m1 '"type":"assistant"' \
        | jq -r '.message.model // empty' 2>/dev/null)
    [ -n "$sid" ] && write_model "model-$sid" "$model"
    exit 0
fi

# --- Copilot CLI: model from the session events, keyed by cwd ---
sid=$(printf '%s' "$input" | jq -r '.sessionId // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
ev="$HOME/.copilot/session-state/$sid/events.jsonl"
if [ -n "$sid" ] && [ -n "$cwd" ] && [ -f "$ev" ]; then
    model=$(tac "$ev" 2>/dev/null | grep -m1 '"type":"assistant.message"' \
        | jq -r '.data.model // empty' 2>/dev/null)
    write_model "model-cwd-$(printf '%s' "$cwd" | tr '/' '_')" "$model"
fi
exit 0
