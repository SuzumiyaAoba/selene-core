/// Scheme 評価器の実行時値（ドラフト）。

/// 数値型の最小構成（拡張予定）。
pub(all) enum Number {
  Int(Int)
  Real(Double)
} derive(Show)

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
} derive(Show)
