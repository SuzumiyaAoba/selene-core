# R5RS Pitfalls テスト移植状況

Guile の `r5rs_pitfall.test` を `src/tests/r5rs_pitfall_test.mbt` に移植しています。
現在は機能不足のため、以下のフラグで該当ケースを無効化しています。

## 無効化中のフラグと理由

- `enable_callcc = false`
  - VM で `call/cc` を有効化しても `invalid frame depth` が発生
- `enable_macros = false`
  - `let-syntax` が未実装
- `enable_rest_params = false`
  - rest parameter 構文が未実装
- `enable_keyword_shadowing = false`
  - `quote` などの予約語シャドーイングが未対応
- `enable_string_to_symbol = false`
  - `string->symbol` が未実装
- `enable_named_let = false`
  - named `let` が未実装
- `enable_append = false`
  - `append` が VM 側で未実装

## 参考

- 原典: `docs/third_party/guile/r5rs_pitfall.test`
- 移植テスト: `src/tests/r5rs_pitfall_test.mbt`
