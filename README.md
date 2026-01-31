# tmux-idle-notification

iTerm2とtmuxでアイドル状態を検出し、macOS通知を送信するシステムです。

## 概要

このプロジェクトは2つの通知システムを提供します：

1. **tmuxアイドル監視** - tmuxセッションがアイドル状態になったときに通知
2. **Claude Code完了通知** - Claude Codeがタスクを完了したときに通知

どちらもiTerm2の`TMUX_IDLE_NOTIFICATION:`プレフィックスを使用して、macOS通知センターに通知を表示します。

## 機能

### 1. tmuxアイドル監視

- tmuxセッションの最終アクティビティを監視
- 指定時間（デフォルト60秒）アイドル状態が続くと通知
- アクティブに戻ると通知フラグをリセット
- セッション単位で動作

### 2. Claude Code完了通知

- Claude Codeがタスク完了後、60秒間アイドル状態になると通知
- Claude Code hookシステムと統合
- tmux環境でのみ動作（現在の実装）

## ファイル構成

```
tmux-idle-notification/
├── README.md                          # このファイル
├── tmux-idle-check.sh                 # アイドル監視メインスクリプト
└── tmux-idle-check-launcher.sh        # ランチャースクリプト

~/.local/bin/
└── claude-complete-notify.sh          # Claude Code hook用スクリプト

~/.claude/
└── settings.json                       # Claude Code設定ファイル
```

## セットアップ

### 前提条件

- macOS
- iTerm2（通知機能に必要）
- tmux
- Claude Code（Claude Code通知機能を使う場合）

### インストール

#### 1. tmuxアイドル監視のセットアップ

```bash
# スクリプトを実行可能にする
chmod +x tmux-idle-check.sh
chmod +x tmux-idle-check-launcher.sh

# スクリプトを~/.local/binにコピー（オプション）
mkdir -p ~/.local/bin
cp tmux-idle-check.sh ~/.local/bin/
cp tmux-idle-check-launcher.sh ~/.local/bin/
```

#### 2. Claude Code通知のセットアップ

```bash
# スクリプトを~/.local/binに配置
chmod +x claude-complete-notify.sh
cp claude-complete-notify.sh ~/.local/bin/

# Claude Code設定にhookを追加
# ~/.claude/settings.jsonに以下を追加：
```

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/home/sugimoto/.local/bin/claude-complete-notify.sh"
          }
        ]
      }
    ]
  }
}
```

### iTerm2設定の確認

iTerm2で通知機能が有効になっていることを確認：

1. iTerm2 > Preferences > Profiles > Terminal
2. "Notifications" セクションで通知設定を確認

## 使い方

### tmuxアイドル監視

#### 自動起動（推奨）

`.tmux.conf`に以下を追加して、tmux起動時に自動実行：

```bash
# tmux起動時にアイドルチェックを開始
set-hook -g after-new-session 'run-shell "~/.local/bin/tmux-idle-check-launcher.sh"'
```

#### 手動起動

```bash
# ランチャー経由で起動（重複起動を防ぐ）
~/.local/bin/tmux-idle-check-launcher.sh

# または直接起動
nohup ~/.local/bin/tmux-idle-check.sh > /dev/null 2>&1 &
```

#### プロセス確認

```bash
# 実行中のアイドルチェックプロセスを確認
pgrep -f "tmux-idle-check.sh"

# プロセス詳細を確認
ps aux | grep tmux-idle-check
```

### Claude Code通知

Claude Codeで作業を完了後、60秒間何も入力しないと自動的に通知が届きます。

#### 手動テスト

```bash
# tmux内で実行
/home/sugimoto/.local/bin/claude-complete-notify.sh
```

macOS通知が表示されれば正常に動作しています。

## スクリプト詳細

### tmux-idle-check.sh

tmuxセッションの最終アクティビティを監視するメインスクリプト。

**設定可能なパラメータ:**

- `IDLE_THRESHOLD`: アイドル判定時間（秒）デフォルト: 60秒
- `sleep`: チェック間隔（秒）デフォルト: 30秒

**動作:**

1. 30秒ごとにtmuxセッションのアクティビティをチェック
2. 60秒以上アイドル状態が続くと通知
3. アクティブに戻るとフラグをリセット
4. セッションが終了すると自動終了

### tmux-idle-check-launcher.sh

アイドルチェックスクリプトの重複起動を防ぐランチャー。

**動作:**

1. 既に起動中かチェック（`pgrep`を使用）
2. 起動していなければ`nohup`で独立プロセスとして起動
3. `disown`でシェルから切り離し

### claude-complete-notify.sh

Claude Code hook用の通知スクリプト。

**動作:**

- tmux環境内: 現在のペインに`TMUX_IDLE_NOTIFICATION:`を送信
- tmux外: `echo`で出力（現在は通知されない）

**環境検出:**

- `$TMUX`環境変数の有無でtmux環境を判定
- 現在のペインIDを自動取得

## 通知の仕組み

### TMUX_IDLE_NOTIFICATION: プレフィックス

iTerm2はtmuxの`display-message`出力を監視し、`TMUX_IDLE_NOTIFICATION:`プレフィックスを検出すると自動的にmacOS通知に変換します。

**例:**

```bash
tmux display-message -t $PANE_ID "TMUX_IDLE_NOTIFICATION: Session idle for 1 minutes"
```

↓

macOS通知センターに「Session idle for 1 minutes」が表示される

## トラブルシューティング

### 通知が届かない

**原因1: iTerm2を使用していない**
- 解決策: iTerm2でtmuxを起動してください

**原因2: tmux環境ではない**
- 解決策: tmux内でスクリプトを実行してください

**原因3: macOS通知設定**
- 解決策: システム環境設定 > 通知 > iTerm2で通知が有効か確認

### アイドルチェックが動作しない

**原因1: プロセスが起動していない**

```bash
# プロセス確認
pgrep -f "tmux-idle-check.sh"

# 再起動
~/.local/bin/tmux-idle-check-launcher.sh
```

**原因2: セッション名が取得できない**

```bash
# 現在のセッション名を確認
tmux display-message -p '#S'
```

### Claude Code通知が動作しない

**原因1: hook設定が反映されていない**

```bash
# Claude Code設定を確認
cat ~/.claude/settings.json

# Claude Codeを再起動
```

**原因2: スクリプトの実行権限がない**

```bash
# 実行権限を付与
chmod +x ~/.local/bin/claude-complete-notify.sh
```

**原因3: スクリプトパスが間違っている**

```bash
# パスを確認
ls -la ~/.local/bin/claude-complete-notify.sh
```

## カスタマイズ

### アイドル時間を変更

`tmux-idle-check.sh`の`IDLE_THRESHOLD`を編集：

```bash
# 例: 120秒（2分）に変更
IDLE_THRESHOLD=120
```

### 通知メッセージを変更

各スクリプトの`tmux display-message`コマンドのメッセージ部分を編集：

```bash
# 例:
tmux display-message -t "$PANE_ID" "TMUX_IDLE_NOTIFICATION: カスタムメッセージ"
```

### チェック間隔を変更

`tmux-idle-check.sh`の`sleep`を編集：

```bash
# 例: 10秒ごとにチェック
sleep 10
```

## 今後の改善案

### Claude Code通知の改善

現在の`claude-complete-notify.sh`はtmux環境でのみ動作します。以下の環境にも対応する改善案があります：

1. **iTerm2のみ（tmuxなし）**: エスケープシーケンス`\e]9;メッセージ\a`を使用
2. **その他の環境**: `osascript`でmacOS通知を直接送信

詳細は`~/.claude/plans/starry-enchanting-creek.md`を参照してください。

## ライセンス

MIT License

## 作者

sugimoto

## 参考資料

- [iTerm2 Proprietary Escape Codes](https://iterm2.com/documentation-escape-codes.html)
- [tmux man page](https://man.openbsd.org/tmux)
- [Claude Code Documentation](https://code.claude.com/docs)
