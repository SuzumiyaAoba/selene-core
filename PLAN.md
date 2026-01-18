# Selene Core 実装計画

**最終目標**: 自作 VM 上での Scheme (R5RS) 実行

## 現在の状態

### 完了済み

#### Phase 1: 基盤
- [x] 字句解析器 (lexer.mbt)
- [x] パーサ (parser.mbt)
- [x] 値表現と環境 (value.mbt, env.mbt)
- [x] 基本評価器 (eval.mbt)

#### Phase 2: 特殊形式
- [x] `if`, `lambda`, `define`, `set!`, `begin`
- [x] `quote`, `quasiquote`, `unquote`, `unquote-splicing`
- [x] `let`, `let*`, `letrec`
- [x] `cond`, `case`
- [x] `and`, `or`

#### Phase 3: 組み込み関数
- [x] 算術演算 (`+`, `-`, `*`, `/`, `quotient`, `remainder`, `modulo`, etc.)
- [x] 数学関数 (`sin`, `cos`, `tan`, `sqrt`, `expt`, `log`, `exp`, etc.)
- [x] 比較演算 (`=`, `<`, `>`, `<=`, `>=`)
- [x] リスト操作 (`cons`, `car`, `cdr`, `list`, `append`, `reverse`, `length`, etc.)
- [x] cXXXr アクセサ (`caar`, `cadr`, `cdar`, `cddr`, etc.)
- [x] 述語 (`null?`, `pair?`, `list?`, `number?`, `symbol?`, `string?`, etc.)
- [x] 等価性 (`eq?`, `eqv?`, `equal?`)
- [x] 文字列操作 (`string-length`, `string-ref`, `substring`, `string-append`, etc.)
- [x] 文字列比較 (`string<?`, `string>?`, `string<=?`, `string>=?`, `string-ci=?`, etc.)
- [x] 文字操作 (`char?`, `char=?`, `char<?`, `char-upcase`, `char-downcase`, etc.)
- [x] ベクタ (`vector`, `make-vector`, `vector-ref`, `vector-set!`, `vector-length`, etc.)
- [x] 型変換 (`number->string`, `string->number`, `symbol->string`, `string->symbol`, etc.)
- [x] 制御フロー (`apply`, `map`, `for-each`, `filter`, `fold-left`, `fold-right`)
- [x] 継続 (`call/cc`)
- [x] I/O (`display`, `newline`, `write`, `read`)
- [x] ペア操作 (`set-car!`, `set-cdr!`)

**テスト**: 400 件パス

---

## TODO

### Phase 4: R5RS 完全対応

- [ ] `do` ループ構文
- [ ] `delay` / `force` (遅延評価)
- [ ] `dynamic-wind`
- [ ] `call-with-values` / `values` (多値)
- [ ] `syntax-rules` マクロシステム
- [ ] 数値塔の拡張 (有理数, 複素数)
- [ ] ポート操作の完全実装
  - [ ] `open-input-file`, `open-output-file`
  - [ ] `close-input-port`, `close-output-port`
  - [ ] `read-char`, `peek-char`, `write-char`
  - [ ] `eof-object?`
  - [ ] `call-with-input-file`, `call-with-output-file`
- [ ] `load` 関数

### Phase 5: コンパイラ

- [ ] 中間表現 (IR) の設計
- [ ] AST → IR 変換
- [ ] IR の最適化
  - [ ] 定数畳み込み
  - [ ] 不要コード除去
  - [ ] インライン展開
- [ ] バイトコード形式の設計
- [ ] IR → バイトコード変換
- [ ] バイトコードのシリアライズ/デシリアライズ

### Phase 6: 仮想マシン (VM)

- [ ] VM アーキテクチャ設計
  - [ ] スタックベース vs レジスタベース
  - [ ] 命令セットの定義
  - [ ] メモリモデル
- [ ] 基本命令の実装
  - [ ] スタック操作 (push, pop, dup)
  - [ ] 算術命令
  - [ ] 分岐命令 (jump, branch)
  - [ ] 関数呼び出し (call, return)
- [ ] クロージャのサポート
- [ ] 継続のサポート
- [ ] ガベージコレクション
- [ ] 末尾呼び出し最適化

### Phase 7: 統合とツール

- [ ] REPL の VM 対応
- [ ] デバッガ
- [ ] プロファイラ
- [ ] バイトコードダンプツール

---

## アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────┐
│                      Source Code                             │
│                    (Scheme / R5RS)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Lexer                                 │
│                     (lexer.mbt)                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Parser                                │
│                     (parser.mbt)                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          AST                                 │
│                      (value.mbt)                             │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│      Tree-Walking        │    │        Compiler          │
│       Interpreter        │    │     (Phase 5: TODO)      │
│       (eval.mbt)         │    │                          │
│                          │    │   AST → IR → Bytecode    │
│   [Current: Working]     │    │                          │
└──────────────────────────┘    └──────────────────────────┘
                                              │
                                              ▼
                                ┌──────────────────────────┐
                                │     Virtual Machine      │
                                │     (Phase 6: TODO)      │
                                │                          │
                                │   Bytecode Execution     │
                                │                          │
                                └──────────────────────────┘
```

---

## ファイル構成

```
src/
├── lexer.mbt              # 字句解析
├── parser.mbt             # 構文解析
├── value.mbt              # 値表現
├── env.mbt                # 環境
├── eval.mbt               # 評価器コア
├── special_form.mbt       # 特殊形式
├── builtin_arithmetic.mbt # 算術演算
├── builtin_char.mbt       # 文字操作
├── builtin_control.mbt    # 制御フロー
├── builtin_io.mbt         # I/O
├── builtin_list.mbt       # リスト操作
├── builtin_math.mbt       # 数学関数
├── builtin_predicate.mbt  # 述語
├── builtin_string.mbt     # 文字列操作
├── builtin_vector.mbt     # ベクタ
├── ffi.js.mbt             # JavaScript FFI
├── ffi.wasm-gc.mbt        # WASM FFI
├── main.mbt               # エントリポイント
└── *_test.mbt             # テストファイル群
```

---

## 次のマイルストーン

**Phase 4 (R5RS 完全対応)** の優先順位:

1. `do` ループ - 一般的な反復構造
2. `delay` / `force` - 遅延評価の基盤
3. `values` / `call-with-values` - 多値サポート
4. ポート操作の完全実装 - ファイル I/O
5. `syntax-rules` - マクロシステム
6. `dynamic-wind` - 継続との統合
7. 数値塔拡張 - 有理数/複素数

---

## 参考資料

- [R5RS 仕様書](docs/r5rs.pdf)
- [MoonBit 言語ドキュメント](https://www.moonbitlang.com/docs/)
