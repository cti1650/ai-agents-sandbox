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

### 境界（boundary）と補助策（guard）の区別

セキュリティ対策には「突破されると守れなくなる**補助策**」と「権限的に突破できない**境界**」があります。両者を混同しないことが重要です。

| 種別 | 対策 | 位置づけ |
|------|------|----------|
| **境界** | `no-new-privileges:true` + 非rootユーザー | 実効的な権限境界。`vscode` には sudoers 上 `NOPASSWD:ALL` が付与されているが、`no_new_privs` により **setuid な `sudo` がカーネルレベルで昇格を拒否される**ため、ランタイムでの root 昇格は成立しない |
| **境界** | `cap_drop: ALL` | 追加した CHOWN/SETUID/SETGID 以外の特権操作（NET_ADMIN 等）は不可 |
| **補助策** | 各エージェントの `deny` ルール | `sudo *` / `rm -rf /` / `.env` 読み取り等の**パターンマッチ**による事故防止。`/usr/bin/sudo`・シェル経由・別名・インタプリタ経由などで原理的に回避されうるため、**敵対的入力に対する防壁ではない** |

> 補助策（deny ルール）は「うっかり事故」を減らす価値はありますが、**敵対的・暴走エージェントを止める役割は境界（隔離・権限制御）側が担う**設計です。deny パターンを増やすより、境界を厚くする方が効果的です。

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

- **ネットワークegress制御（外向き通信の許可リスト）** — 後述
- AppArmor/Seccompプロファイル（ホスト依存のため）
- Docker Socket Proxy（追加のセットアップが必要）

### egress制御を標準採用しない理由

「コンテナ内で iptables/ipset による許可リスト型ファイアウォールを張る」案も検討しましたが、**標準では採用しません**。

- **壊れやすい**: ipset は IP ベースで、GitHub / CDN / npm / PyPI の IP 変動により `npm install`・`pip install`・`gh`・GitHub Actions API が断続的に失敗する。依存先が増えるたびにメンテが必要。
- **Dev Containers と相性が悪い**: 本環境は `no-new-privileges` により sudo 昇格が無効化されており、firewall は「起動時に root の entrypoint で張ってから降格」する構成が必須。`remoteUser=vscode` / `postCreate` / attach のライフサイクルと衝突しやすく、失敗するとコンテナに接続できない事故になりうる。
- **費用対効果**: 個人〜小規模用途では、これらの運用コストに見合う脅威低減が得られない。

**強い egress 制御が必要な場合**は、コンテナ内ではなく**ホスト/ネットワーク層**で強制してください（ホストの firewall、egress プロキシ、VPN、CI runner の network policy、Kubernetes NetworkPolicy など）。コンテナ内設定やエージェント設定に依存しないため、これが最も堅牢です。

> 参考: どうしてもコンテナ内で行う場合は、`cap_add: [NET_ADMIN]` を足し、root の entrypoint で `init-firewall.sh` を実行してから vscode に降格する構成になります。上記のトレードオフを理解した上で、自己責任で導入してください。

## 参考資料

- [OWASP Agentic Top 10](https://genai.owasp.org/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [DevContainer Security](https://code.visualstudio.com/docs/devcontainers/containers#_devcontainer-security)
