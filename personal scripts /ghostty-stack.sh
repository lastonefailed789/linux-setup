#!/usr/bin/env bash
#
# ghostty-stack.sh
#
# Watches niri's IPC event stream. Whenever a *new* Ghostty window opens
# and the currently-active column has fewer than MAX_STACK windows in it,
# the new window is consumed left into that column. Once a column reaches
# MAX_STACK windows, the next new Ghostty window starts a fresh column
# instead of piling in further.
#
# Requires: niri, jq
#
# Usage: run this as a background daemon (see spawn-at-startup below).

set -euo pipefail

APP_ID="com.mitchellh.ghostty"   # change to com.mitchellh.ghostty-debug if you're on a debug build
CONSUME_DELAY="0.05"             # small delay so niri finishes placing the new column first
MAX_STACK=3                      # max Ghostty windows per column before starting a new one

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

declare -A known_ids   # tracks window ids we've already seen (any app)
declare -A ghostty_ids # tracks currently-open Ghostty window ids
ghostty_count=0        # total open ghostty windows (explicit counter avoids a bash nounset bug)
stack_count=0          # windows currently in the active/most-recent column (0 = no active column yet)

log "starting up — watching for app_id=$APP_ID (delay=${CONSUME_DELAY}s, max_stack=$MAX_STACK)"

while read -r line; do
    win_id=$(jq -r '.WindowOpenedOrChanged.window.id // empty' <<<"$line")
    win_app=$(jq -r '.WindowOpenedOrChanged.window.app_id // empty' <<<"$line")

    if [[ -n "$win_id" ]]; then
        is_new=0
        if [[ -z "${known_ids[$win_id]:-}" ]]; then
            is_new=1
            known_ids[$win_id]=1
        fi

        log "window event: id=$win_id app_id=${win_app:-<none>} new=$is_new"

        if [[ "$win_app" == "$APP_ID" ]]; then
            if [[ $is_new -eq 1 && -z "${ghostty_ids[$win_id]:-}" ]]; then
                ghostty_ids[$win_id]=1
                ghostty_count=$((ghostty_count + 1))
                log "ghostty window opened: id=$win_id (now tracking $ghostty_count ghostty window(s) total)"

                if [[ $stack_count -eq 0 ]]; then
                    stack_count=1
                    log "  -> starting a new column (stack 1/$MAX_STACK)"
                elif (( stack_count < MAX_STACK )); then
                    log "  -> consuming id=$win_id left into active column in ${CONSUME_DELAY}s (stack $stack_count/$MAX_STACK -> $((stack_count + 1))/$MAX_STACK)"
                    sleep "$CONSUME_DELAY"
                    if niri msg action consume-or-expel-window-left; then
                        stack_count=$((stack_count + 1))
                        log "  -> consume-or-expel-window-left succeeded"
                    else
                        log "  -> consume-or-expel-window-left FAILED (non-zero exit, ignored)"
                    fi
                else
                    log "  -> active column already at MAX_STACK ($MAX_STACK), starting a new column instead"
                    stack_count=1
                fi
            fi
        fi
        continue
    fi

    closed_id=$(jq -r '.WindowClosed.id // empty' <<<"$line")
    if [[ -n "$closed_id" ]]; then
        log "window closed: id=$closed_id"
        unset 'known_ids[$closed_id]'
        if [[ -n "${ghostty_ids[$closed_id]:-}" ]]; then
            unset 'ghostty_ids[$closed_id]'
            ghostty_count=$((ghostty_count - 1))
            if (( stack_count > 0 )); then
                stack_count=$((stack_count - 1))
            fi
            log "  -> was a tracked ghostty window (now tracking $ghostty_count total, active column ~$stack_count/$MAX_STACK)"
        fi
    fi
done < <(niri msg --json event-stream)
