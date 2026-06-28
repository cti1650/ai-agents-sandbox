# Security

このドキュメントでは、AI Agents Sandbox のセキュリティモデルと実装されている対策について説明します。

## セキュリティモデル

このsandbox環境は、AIコーディングエージェント（Claude Code, Codex CLI, Antigravity CLI）を**隔離された環境**で実行するために設計されています。

### 脅威モデル

1. **AIエージェントの暴走**: AIが意図しないコマンドを実行する可能性
2. **機密情報の漏洩**: APIキーやシークレットの誤コミット
3. **サプライチェーン攻撃**: 悪意のあるnpm/PyPIパッケージ
4. **権限昇格**: コンテナからホストへの脱出

## 実装されている対策

### コンテナ隔離

| 対策 | 説明 |
|------|------|
| 非rootユーザー | `vscode` (UID 1000) で実行 |
| Capability削除 | `cap_drop: ALL` + 最小限の追加 (CHOWN, SETUID, SETGID) |
| 特権昇格禁止 | `no-new-privileges: true` |
| プロセス数制限 | `pids: 256` でフォークボム防止 |
| リソース制限 | メモリ4GB、CPU 2コア |
| ヘルスチェック | 30秒間隔でコンテナ状態を監視 |

### シークレット保護

| ツール | 用途 |
|--------|------|
| [secretlint](https://github.com/secretlint/secretlint) | APIキー・トークンの検出 |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Git履歴とステージ変更のスキャン |
| [lefthook](https://github.com/evilmartians/lefthook) | pre-commitフック管理 |

コミット時に自動でスキャンが実行され、シークレットが検出されるとコミットがブロックされます。

### サプライチェーン対策

| 対策 | 説明 |
|------|------|
| [Takumi Guard for npm](https://shisho.dev/docs/ja/t/guard/quickstart/npm/) | 悪性パッケージをインストール前にブロック |
| [Takumi Guard for PyPI](https://shisho.dev/docs/ja/t/guard/quickstart/pypi/) | 悪性パッケージをブロック + 72時間隔離 |
| `min-release-age=3` | npm: 公開3日未満のバージョンを隔離 |
| ピン留めバージョン | Dockerfile内のCLIツールはバージョン固定 |
| ダイジェスト固定 | ベースイメージはSHA256ダイジェストで固定 |

### SSH/Git セキュリティ

- **SSHキーはコンテナにコピーしない**: VS Codeのssh-agentフォワードを使用
- **認証データの分離**: 各AIツールの認証は named volume に保存
- **設定の読み取り専用マウント**: ホストの設定ファイルは `:ro` でマウント

## セキュリティスキャン

### ローカルスキャン

```bash
# secretlint でリポジトリ全体をスキャン
npm run secretlint

# gitleaks でスキャン
gitleaks detect --source .
```

### CI/CD

- `devcontainer-ci.yml`: コンテナビルドと検証テスト
- `pin-check.yml`: GitHub Actionのコミット固定を検証
- `gitleaks-scan.yml`: プッシュ時にシークレットスキャン

## 脆弱性の報告

セキュリティ上の問題を発見した場合は、Issue ではなくプライベートな手段で報告してください。

1. リポジトリの [Security Advisories](../../security/advisories) から報告
2. または、メンテナーに直接連絡

## 制限事項

このsandbox環境は以下を**提供しません**:

- ネットワークレベルのファイアウォール（CAP_NET_ADMIN が必要なため）
- AppArmor/Seccompプロファイル（ホスト依存のため）
- Docker Socket Proxy（追加のセットアップが必要）

これらが必要な場合は、追加の設定をご検討ください。

## 参考資料

- [OWASP Agentic Top 10](https://genai.owasp.org/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [DevContainer Security](https://code.visualstudio.com/docs/devcontainers/containers#_devcontainer-security)
