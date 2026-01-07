# Repository Guidelines

## Project Structure & Module Organization
- `src/`：本体実装（MoonBit）。現在は `src/main.mbt` がエントリーポイントのスタブ。
- `tests/`：`moon test` 用の単体テスト。拡充予定。
- `docs/`：実装計画や参考資料（`implementation-plan.md`, `llms.txt`, `r5rs.pdf`）。
- ルート：`Makefile`, `moon.pkg.json`, `README.md`。

## Build, Test, and Development Commands
- `make build` / `moon build`：依存取得とビルド。
- `make run` / `moon run`：実行（REPL 予定、現状はスタブ出力）。
- `make test` / `moon test`：テスト実行（テストはこれから増やす想定）。
- `make fmt` / `moon fmt`：フォーマット。
- `make clean`：生成物削除（`out/`, `.moon/`, `.cache/`）。

## Configuration & Environment
- 必須：MoonBit CLI（最新版推奨）。`moon --version` で確認。
- `moon.pkg.json` にパッケージ情報とソースルートが定義されています。

## Coding Style & Naming Conventions
- MoonBit 標準のフォーマットに合わせ、変更後は `moon fmt` を実行。
- `src/` と `tests/` 配下に `.mbt` を配置し、公開 API は `pub` で明示。
- 既存コードのインデント（スペース）に合わせて統一。

## Testing Guidelines
- フレームワーク：`moon test`（MoonBit 標準）。
- 追加するテストは `tests/` に配置し、字句解析→構文解析→評価器の順で拡充予定。
- 命名は機能単位で簡潔に（例：`lexer_*`、`parser_*` など）。

## Commit & Pull Request Guidelines
- 既存の履歴では `docs:` / `chore:` などの接頭辞が使われています。可能なら簡潔なプレフィックス＋要約で統一してください。
- PR には目的・変更点・動作確認（実行したコマンド）を記載。
- 仕様変更や振る舞い変更がある場合は、`docs/` の更新も検討。

## Documentation
- 概要と利用方法は `README.md` を更新してください。
- 実装計画や参考資料は `docs/` に追加・整理します。

## Architecture Overview
- 目標は Scheme (R5RS) 実装。字句解析器・構文解析器・評価器・REPL を段階的に追加する方針です（`docs/implementation-plan.md` 参照）。
