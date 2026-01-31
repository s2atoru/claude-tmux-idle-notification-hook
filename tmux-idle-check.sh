#!/bin/bash

IDLE_THRESHOLD=60
NOTIFIED=false  # 通知済みフラグ
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#{pane_id}')

while true; do
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        LAST_ACTIVITY=$(tmux list-clients -t "$SESSION_NAME" -F "#{client_activity}" 2>/dev/null | head -1)
        CURRENT_TIME=$(date +%s)
        
        if [ -n "$LAST_ACTIVITY" ] && [ "$LAST_ACTIVITY" -gt 0 ]; then
            IDLE_SECONDS=$((CURRENT_TIME - LAST_ACTIVITY))
            
            # idle状態になった
            if [ $IDLE_SECONDS -gt $IDLE_THRESHOLD ]; then
                # まだ通知していなければ通知
                if [ "$NOTIFIED" = "false" ]; then
                    tmux display-message -t "$PANE_ID" "TMUX_IDLE_NOTIFICATION: Session '$SESSION_NAME' idle for $((IDLE_SECONDS / 60)) minutes"
                    NOTIFIED=true
                fi
            else
                # アクティブに戻ったらフラグをリセット
                NOTIFIED=false
            fi
        fi
    else
        exit 0
    fi
    sleep 30
done
