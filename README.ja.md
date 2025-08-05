# Claude Memento v1.0 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/issues)
[![GitHub stars](https://img.shields.io/github/stars/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/stargazers)

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

Claude Codeの会話間でコンテキストを保持し、長期プロジェクトの継続性を確保するメモリ管理拡張機能です。

**📢 現在の状態**: 初期リリース - 積極的に改善中！体験を洗練させる中で、いくつかの粗い部分があることをご了承ください。

## Claude Mementoとは？ 🤔

Claude Mementoは、Claude Codeのコンテキスト喪失問題を以下の機能で解決します：
- 💾 **自動メモリバックアップ**: 重要な作業状態とコンテキストを自動保存
- 🔄 **セッション継続性**: 前回の作業をシームレスに再開
- 📝 **知識の蓄積**: プロジェクトの決定事項を永続的に保存
- 🎯 **ネイティブClaude Code統合**: `/cm:` コマンドネームスペース経由
- 🔐 **非破壊的インストール**: 既存の設定を保持

## 現在の状態 📊

**うまく機能している機能:**
- コアメモリ管理システム
- 7つの統合されたClaude Codeコマンド
- クロスプラットフォームインストール（macOS、Linux、Windows）
- 自動圧縮とインデックス化
- カスタマイズ用のフックシステム

**既知の制限事項:**
- 初期リリースで予期されるバグ
- ローカルストレージに限定（クラウド同期は予定）
- 現在は単一プロファイルのみサポート
- 手動チェックポイント管理

## 主な機能 ✨

### コマンド 🛠️
メモリ管理のための7つの必須コマンド：

**メモリ操作:**
- `/cm:save` - 説明付きで現在の状態を保存
- `/cm:load` - 特定のチェックポイントをロード
- `/cm:status` - システムステータスを表示

**チェックポイント管理:**
- `/cm:list` - すべてのチェックポイントをリスト
- `/cm:last` - 最新のチェックポイントをロード

**設定:**
- `/cm:config` - 設定を表示/編集
- `/cm:hooks` - フックスクリプトを管理

### スマート機能 🎭
- **自動圧縮**: 大規模なコンテキストを効率的に保存
- **インテリジェントインデックス**: 高速なチェックポイント検索と取得
- **フックシステム**: 保存/ロードイベント用のカスタムスクリプト
- **増分バックアップ**: ストレージ最適化のため変更のみを保存
- **完全システムバックアップ**: インストール前に~/.claudeディレクトリの完全バックアップを作成
- **簡単な復元**: バックアップに含まれるワンコマンド復元スクリプト

## インストール 📦

Claude Mementoは単一のスクリプトでインストールできます。

### 前提条件
- Claude Codeがインストール済み（または `~/.claude/` ディレクトリが存在）
- Bash環境（WindowsではGit Bash、WSL、またはPowerShell）

### クイックインストール

**macOS / Linux:**
```bash
# クローンとインストール
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# Claude Codeで確認
# /cm:status
```

**Windows (PowerShell):**
```powershell
# リポジトリをクローン
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 必要に応じて実行ポリシーを設定
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# インストーラーを実行
.\install.ps1
```

**Windows (Git Bash):**
```bash
# クローンとインストール
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh
```

## 動作原理 🔄

1. **状態キャプチャ**: Claude Mementoが現在の作業コンテキストをキャプチャ
2. **圧縮**: 大規模なコンテキストをインテリジェントに圧縮
3. **保存**: メタデータとタイムスタンプ付きでチェックポイントを保存
4. **取得**: 任意のチェックポイントをロードして完全なコンテキストを復元
5. **統合**: シームレスなワークフローのためのネイティブClaude Codeコマンド

### アーキテクチャ概要

```
Claude Codeセッション
    ↓
/cm:saveコマンド
    ↓
コンテキスト処理 → 圧縮 → 保存
                         ↓
                    チェックポイント
                         ↓
                 ~/.claude/memento/
                         ↓
/cm:loadコマンド ← 解凍 ← 取得
    ↓
復元されたセッション
```

## 使用例 💡

### 基本的なワークフロー
```bash
# 新機能を開始
/cm:save "初期機能セットアップ完了"

# 重要な進捗後
/cm:save "APIエンドポイント実装"

# 翌日 - コンテキストを復元
/cm:last

# または特定のチェックポイントをロード
/cm:list
/cm:load checkpoint-20240119-143022
```

### 高度な使用法
```bash
# 自動保存間隔を設定
/cm:config set autoSave true
/cm:config set saveInterval 300

# カスタムフックを追加
/cm:hooks add post-save ./scripts/backup-to-cloud.sh
/cm:hooks add pre-load ./scripts/validate-checkpoint.sh

# システムヘルスをチェック
/cm:status --verbose
```

## 設定 🔧

デフォルト設定（`~/.claude/memento/config/default.json`）:
```json
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
```

## プロジェクト構造 📁

```
claude-memento/
├── src/
│   ├── core/          # コアメモリ管理
│   ├── commands/      # コマンド実装
│   ├── utils/         # ユーティリティとヘルパー
│   └── bridge/        # Claude Code統合
├── templates/         # 設定テンプレート
├── commands/          # コマンド定義
├── docs/             # ドキュメント
└── examples/         # 使用例
```

## トラブルシューティング 🔍

### よくある問題

**コマンドが動作しない:**
```bash
# コマンドがインストールされているか確認
ls ~/.claude/commands/cm/

# ステータスコマンドを確認
/cm:status
```

**インストールが失敗する:**
```bash
# 権限を確認
chmod +x install.sh
./install.sh --verbose
```

**メモリロードエラー:**
```bash
# チェックポイントの整合性を確認
/cm:status --check
# 必要に応じて修復
./src/utils/repair.sh
```

**インストール後のパス構造の問題:**
```bash
# "file not found"エラーでコマンドが失敗する場合
# これは不正なインストールが原因の可能性があります
# 更新されたスクリプトで再インストール:
./uninstall.sh && ./install.sh
```

**権限エラー:**
```bash
# "permission denied"エラーが発生する場合
# ファイル権限を確認
ls -la ~/.claude/memento/src/**/*.sh

# 必要に応じて手動で権限を修正
find ~/.claude/memento/src -name "*.sh" -type f -exec chmod +x {} \;
```

## 貢献 🤝

貢献を歓迎します！詳細は[貢献ガイド](CONTRIBUTING.md)をご覧ください。

1. リポジトリをフォーク
2. 機能ブランチを作成（`git checkout -b feature/amazing-feature`）
3. 変更をコミット（`git commit -m 'Add amazing feature'`）
4. ブランチにプッシュ（`git push origin feature/amazing-feature`）
5. プルリクエストを開く

## ロードマップ 🗺️

**バージョン 1.1:**
- [ ] クラウドバックアップサポート
- [ ] 複数プロファイル管理
- [ ] リアルタイム同期機能

**バージョン 2.0:**
- [ ] Web UIダッシュボード
- [ ] チームコラボレーション機能
- [ ] 高度な検索とフィルタリング
- [ ] 他のAIツールとの統合

## FAQ ❓

**Q: 私のデータは安全ですか？**
A: すべてのデータはホームディレクトリにローカルで保存されます。クラウド機能には暗号化が含まれる予定です。

**Q: 複数のプロジェクトで使用できますか？**
A: はい！チェックポイントはプロジェクトコンテキストごとに自動的に整理されます。

**Q: Claude Codeが更新されたらどうなりますか？**
A: Claude MementoはClaude Codeの更新と前方互換性を持つように設計されています。

## ライセンス 📄

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 謝辞 🙏

フィードバックと貢献をいただいたClaude Codeコミュニティに特別な感謝を捧げます。

---

**ヘルプが必要ですか？** [ドキュメント](docs/README.md)を確認するか、[イシューを開いてください](https://github.com/claude-memento/claude-memento/issues)。

**Claude Mementoが気に入りましたか？** [GitHub](https://github.com/claude-memento/claude-memento)で⭐を付けてください！

## Star History

<a href="https://www.star-history.com/#claude-memento/claude-memento&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
 </picture>
</a>