/// Scheme 評価器の実行時値（ドラフト）。

/// 数値型の最小構成（拡張予定）。
pub(all) enum Number {
  Int(Int)
  Real(Double)
} derive(Show)

/// 手続き表現（クロージャは後で追加）。
pub(all) enum Procedure {
  Native(String)
  // TODO: Closure(params, body, env)
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
} derive(Show)
