# Claude Memento v1.0.1 🧠

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

## Claude Code エージェント統合 🤖

Claude Mementoには、複数のエージェント間の高度なコンテキスト管理のための**Context-Manager-Memento**エージェントが含まれています。

### エージェント機能
- **自動コンテキストキャプチャ**: リアルタイム監視とチェックポイント作成
- **スマートチャンキング**: セマンティック境界検出による10K以上のトークンのコンテキスト処理
- **マルチエージェント協調**: 専門エージェント間のシームレスなハンドオフ
- **インテリジェント圧縮**: 精度を保持しながら30-50%のトークン削減

### 主要エージェントコマンド
```bash
# コア操作
/cm:save "プロジェクトマイルストーン完了"
/cm:load checkpoint-id
/cm:last

# スマート検索
/cm:chunk search "認証"
/cm:chunk graph --depth 2

# 設定
/cm:config auto-save.interval 15
/cm:status
```

### エージェントの利点
- **40-60%トークン使用量削減** - スマートコンテキストローディングによる
- **自動セッション継続性** - 永続的なチェックポイントによる
- **エージェント間メモリ共有** - 複雑なマルチステップワークフローのため
- **パフォーマンス最適化** - インテリジェントキャッシングによる

詳細なエージェント使用方法については、[エージェント使用ガイド](docs/AGENT_USAGE.md)をご覧ください。

## インストール 📦

Claude Mementoは単一のスクリプトでインストールできます。

### 前提条件
- Claude Codeがインストール済み（または `~/.claude/` ディレクトリが存在）
- Bash環境（WindowsではGit Bash、WSL、またはPowerShell）
- Node.js（グラフデータベースとベクトル化機能用）
- jq（JSON処理用 - 不足している場合は自動インストール）

### クイックインストール

**macOS / Linux:**
```bash
# クローンとインストール
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# インストールの確認
/cm:status
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

### インストール機能
- ✅ **自動バックアップ**: インストール前に完全なバックアップを作成
- ✅ **非破壊的**: 既存のCLAUDE.mdコンテンツを保持
- ✅ **クロスプラットフォーム**: macOS、Linux、Windowsで動作
- ✅ **依存関係チェック**: 不足している依存関係を検証・インストール
- ✅ **ロールバック対応**: 必要に応じて簡単に復元可能

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

### 設定構造（`~/.claude/memento/config/settings.json`）

```json
{
  "autoSave": {
    "enabled": true,        // Boolean: 自動保存の有効化
    "interval": 60,         // Number: 保存間隔（秒）
    "onSessionEnd": true    // Boolean: セッション終了時の保存
  },
  "chunking": {
    "enabled": true,        // Boolean: チャンクシステムの有効化
    "threshold": 10240,     // Number: チャンク化の閾値（バイト）
    "chunkSize": 2000,      // Number: 個別チャンクサイズ
    "overlap": 50           // Number: チャンク間のオーバーラップ
  },
  "memory": {
    "maxSize": 1048576,     // Number: 最大メモリ使用量
    "compression": true     // Boolean: 圧縮を有効化
  },
  "search": {
    "method": "tfidf",      // String: 検索方法（tfidf/simple）
    "maxResults": 20,       // Number: 最大検索結果数
    "minScore": 0.1         // Number: 最小類似度スコア
  }
}
```

**⚠️ 重要**: 実際のboolean/number型を使用してください（`"true"`ではなく`true`）。

### 設定コマンド
```bash
# 現在の設定を表示
/cm:config

# 60秒間隔で自動保存を有効化
/cm:auto-save enable
/cm:auto-save config interval 60

# システムステータスを確認
/cm:status
```

## プロジェクト構造 📁

```
claude-memento/
├── src/
│   ├── commands/      # コマンド実装
│   ├── core/          # コアメモリ管理
│   ├── chunk/         # グラフDB & チャンク化システム
│   ├── config/        # 設定管理
│   ├── hooks/         # フックシステム
│   └── bridge/        # Claude Code統合
├── commands/cm/       # コマンド定義
├── test/             # テストスクリプト
├── docs/             # ドキュメント
└── examples/         # 使用例

実行時構造（~/.claude/memento/）:
├── checkpoints/      # 保存されたチェックポイント
├── chunks/           # グラフDB & チャンクストレージ
├── config/           # 実行時設定
└── src/              # インストール済みシステムファイル
```

## 高度な機能 🚀

### グラフデータベースシステム
Claude Mementoには高度なグラフベースのチャンク管理システムが含まれています：

- **TF-IDFベクトル化**: セマンティック類似検索
- **グラフ関係性**: 自動コンテンツ関係性発見
- **スマートローディング**: クエリベースの選択的コンテキスト復元
- **パフォーマンス**: 50ms以下の検索時間

### チャンク管理
```bash
# キーワードでチャンクを検索
/cm:chunk search "API実装"

# すべてのチャンクをリスト
/cm:chunk list

# セマンティック関係性を構築
/cm:chunk build-relations

# システム統計を取得
/cm:chunk stats
```

## アンインストール 🗑️

### 安全な削除オプション

Claude Mementoはデータ保持オプション付きの包括的なアンインストールを提供します：

**完全削除：**
```bash
# すべてを削除（永続的データ削除）
./uninstall.sh
```

**データ保持：**
```bash
# チェックポイントとチャンクを保持
./uninstall.sh --keep-data

# PowerShell版
.\uninstall.ps1 -KeepData
```

**強制モード（確認をスキップ）：**
```bash
# 自動削除
./uninstall.sh --force

# データ保持付き
./uninstall.sh --keep-data --force
```

### 削除される内容
- ✅ **実行中プロセス**: グレースフルシャットダウンで自動停止
- ✅ **Claude Mementoセクション**: CLAUDE.mdから削除（ファイルは保持）
- ✅ **コマンドファイル**: すべての`/cm:`コマンドを削除
- ✅ **インストールファイル**: システムの完全クリーンアップ
- ✅ **一時ファイル**: PIDファイルとキャッシュをクリア

### データ保持
`--keep-data`使用時：
- チェックポイントを`~/claude-memento-backup-[タイムスタンプ]/`にバックアップ
- 設定ファイルを保持
- グラフデータベースとチャンクを維持
- アクティブコンテキストファイルを保存

## トラブルシューティング 🔍

**コマンドが動作しない:**
```bash
# インストールを確認
/cm:status

# コマンドファイルを確認
ls ~/.claude/commands/cm/
```

**自動保存が動作しない:**
```bash
# 設定を確認
/cm:auto-save status

# 必要に応じて有効化
/cm:auto-save enable
/cm:auto-save config interval 60
```

**グラフシステムエラー:**
```bash
# システムテストを実行
cd ~/.claude/memento/test/
./test-chunk-system.sh

# Node.jsインストールを確認
node --version
```

### パフォーマンス問題

**検索が遅い:**
```bash
# 検索インデックスを再構築
/cm:chunk build-relations

# システムパフォーマンスを確認
/cm:status --verbose
```

### 復旧オプション

**バックアップから復元:**
```bash
# 利用可能なバックアップをリスト
ls ~/.claude_backup_*/

# 復元スクリプトを実行
~/.claude_backup_[タイムスタンプ]/restore.sh
```

**設定をリセット:**
```bash
# デフォルトにリセット
rm ~/.claude/memento/config/settings.json
/cm:status  # デフォルトが再作成されます
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
- [ ] チャンク可視化のためのWebインターフェース
- [ ] 高度な検索フィルターとクエリ
- [ ] 多言語コンテンツサポート

**バージョン 2.0:**
- [ ] クラウドバックアップ統合
- [ ] チームコラボレーション機能
- [ ] 高度な分析ダッシュボード
- [ ] 他のAIツールとの統合

**最近のアップデート（v1.0.1）:**
- ✅ プロセス管理付きアンインストールスクリプトの強化
- ✅ 適切なデータ型を持つ設定システムの改善
- ✅ セマンティック検索機能付きグラフデータベースシステム
- ✅ バックグラウンドデーモン付き自動保存機能
- ✅ パフォーマンス検証付き包括的テストスイート

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