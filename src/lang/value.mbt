/// Runtime values for the Scheme evaluator (draft).

pub(all) enum Number {
  Int(Int)
  Real(Double)
} derive(Show)

pub(all) enum Procedure {
  Native(String)
  // TODO: Closure(params, body, env)
} derive(Show)

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
