#!/bin/bash

# Claude Code completion notification script
# This script sends a notification when Claude Code task is completed

# Check if running inside tmux
if [ -n "$TMUX" ]; then
    # Use tmux display-message to send notification (same as tmux-idle-check.sh)
    PANE_ID=$(tmux display-message -p '#{pane_id}')
    tmux display-message -t "$PANE_ID" "TMUX_IDLE_NOTIFICATION: Claude Code task completed"
else
    # Fallback to echo if not in tmux
    echo "TMUX_IDLE_NOTIFICATION: Claude Code task completed"
fi
