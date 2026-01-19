/// Scheme 評価器の実行時値（ドラフト）。

/// 数値型（R5RS 数値塔）
/// Int < Rational < Real < Complex
pub(all) enum Number {
  Int(Int)
  /// 有理数: 分子と分母（常に既約分数で保持）
  Rational(Int, Int)
  Real(Double)
  /// 複素数: 実部と虚部
  Complex(Double, Double)
} derive(Show)

/// 最大公約数を計算する
pub fn gcd_int(a : Int, b : Int) -> Int {
  let mut x = if a < 0 { -a } else { a }
  let mut y = if b < 0 { -b } else { b }
  while y != 0 {
    let temp = y
    y = x % y
    x = temp
  }
  x
}

/// 有理数を既約分数に正規化する
pub fn normalize_rational(numer : Int, denom : Int) -> Number {
  if denom == 0 {
    // ゼロ除算エラー（実際には呼び出し側でチェックすべき）
    Number::Int(0)
  } else if numer == 0 {
    Number::Int(0)
  } else {
    let g = gcd_int(numer, denom)
    let n = numer / g
    let d = denom / g
    // 分母が負の場合、符号を分子に移動
    let (n, d) = if d < 0 { (-n, -d) } else { (n, d) }
    if d == 1 {
      Number::Int(n)
    } else {
      Number::Rational(n, d)
    }
  }
}

/// 継続を表す型。
/// CPS 変換された評価器で使用される。
pub(all) struct Continuation {
  /// 継続の識別子
  id : Int
} derive(Show)

/// 継続カウンタ（グローバル）
let continuation_counter : Ref[Int] = { val: 0 }

/// 新しい継続IDを生成する。
pub fn new_continuation_id() -> Int {
  let id = continuation_counter.val
  continuation_counter.val = continuation_counter.val + 1
  id
}

/// 手続き表現。
pub(all) enum Procedure {
  Native(String)
  Closure(Array[String], SExpr, Env)
  Cont(Continuation)  // ファーストクラス継続
} derive(Show)

/// 継続呼び出しを表す型。
/// 継続が呼び出されたときに、この値がスローされる。
pub(all) struct ContinuationCall {
  cont_id : Int
  value : Value
} derive(Show)

/// 継続ストア（グローバル）
/// 継続IDから継続の状態へのマッピング
struct ContinuationState {
  /// 継続が呼び出されたときに返す値を受け取るコールバック
  /// (実際には評価の「残り」を表す)
  env : Env
  /// 継続がキャプチャされた時点での式（デバッグ用）
  captured_at : String
}

let continuation_store : Array[(Int, ContinuationState)] = []

/// 継続を保存する。
pub fn store_continuation(id : Int, env : Env, captured_at : String) -> Unit {
  continuation_store.push((id, { env, captured_at }))
}

/// 継続を取得する。
pub fn get_continuation(id : Int) -> ContinuationState? {
  for entry in continuation_store {
    if entry.0 == id {
      return Some(entry.1)
    }
  }
  None
}

/// プロミス（遅延評価）を表す型。
pub(all) struct Promise {
  /// 評価済みかどうか
  forced : Ref[Bool]
  /// 遅延された式（未評価の場合）または結果（評価済みの場合）
  /// 未評価: Left(expr, env), 評価済み: Right(value)
  content : Ref[PromiseContent]
} derive(Show)

/// プロミスの内容
pub(all) enum PromiseContent {
  Delayed(SExpr, Env)
  Forced(Value)
} derive(Show)

/// 構文ルール（syntax-rules マクロ）
pub(all) struct SyntaxRules {
  /// リテラルキーワード（パターン内でそのままマッチする識別子）
  literals : Array[String]
  /// パターンとテンプレートのペアのリスト
  rules : Array[SyntaxRule]
  /// マクロ定義時の環境（衛生的マクロのため）
  def_env : Env
} derive(Show)

/// 個々の構文ルール
pub(all) struct SyntaxRule {
  /// パターン（マクロ呼び出し形式）
  pattern : SExpr
  /// テンプレート（展開形式）
  template : SExpr
} derive(Show)

/// 評価器が扱う値の総和型。
pub(all) enum Value {
  Nil
  Bool(Bool)
  Number(Number)
  Char(Char)
  String(String)
  Symbol(String)
  Pair(Value, Value)
  Vector(Array[Value])
  Procedure(Procedure)
  Promise(Promise)
  /// 多値（call-with-values で使用）
  MultipleValues(Array[Value])
  /// 構文トランスフォーマ（マクロ）
  Syntax(SyntaxRules)
} derive(Show)
