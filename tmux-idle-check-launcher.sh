#!/bin/bash

# 既に起動しているかチェック
if ! pgrep -f "tmux-idle-check.sh" > /dev/null 2>&1; then
    # nohupを使って完全に独立したプロセスとして起動
    nohup ~/.local/bin/tmux-idle-check.sh > /dev/null 2>&1 &
    disown
fi
