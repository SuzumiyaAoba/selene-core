# 値型・環境の設計メモ（ドラフト）

## 値型（Value）
- 最小構成として `Nil/Bool/Number/Char/String/Symbol/Pair/Vector/Procedure` を用意
- 数値は `Number::Int` と `Number::Real` を先行し、将来 `Rational/Complex` を追加
- 手続きは暫定で `Procedure::Native(name)` のみ（クロージャは TODO）

## 環境（Env）
- 構造: `Env { parent, frame }`
- `frame` は `(String, Value)` の配列
- 参照解決は `frame` を線形走査 → 見つからなければ `parent` へ
- `set!` は最初に見つかったフレームを更新、なければ未束縛エラー
- トップレベル環境は `parent=None` を想定
- 将来的に `frame` を HashMap へ置換して性能改善
