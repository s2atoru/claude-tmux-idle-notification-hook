#!/bin/bash

# Claude Code dynamic notification script
# This script sends customized notifications based on the notification type

# Check if running inside tmux
if [ -z "$TMUX" ]; then
    echo "TMUX_IDLE_NOTIFICATION: Claude Code notification"
    exit 0
fi

# Read hook input from stdin
INPUT=$(cat)

# Extract notification_type from JSON
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')

# Customize message based on notification_type
case "$NOTIFICATION_TYPE" in
  "idle_prompt")
    CUSTOM_MSG="Task completed - ready for input"
    ;;
  "permission_prompt")
    CUSTOM_MSG="Your response needed"
    ;;
  *)
    CUSTOM_MSG="$MESSAGE"
    ;;
esac

# Send notification via tmux
PANE_ID=$(tmux display-message -p '#{pane_id}')
tmux display-message -t "$PANE_ID" "TMUX_IDLE_NOTIFICATION: $CUSTOM_MSG"
