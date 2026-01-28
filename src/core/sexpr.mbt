/// S-expression representation of the reader/parser stage.
pub(all) enum SExpr {
  Nil
  Bool(Bool)
  Symbol(String)
  Number(Int)
  Char(Char)
  String(String)
  Pair(SExpr, SExpr)
  Vector(Array[SExpr])
  Quote(SExpr)
  Quasiquote(SExpr)
  Unquote(SExpr)
  UnquoteSplicing(SExpr)
} derive(Show, Eq)

/// Create a list of 2 elements.
pub fn list2(a : SExpr, b : SExpr) -> SExpr {
  SExpr::Pair(a, SExpr::Pair(b, SExpr::Nil))
}

/// Generate symbols.
pub fn sym(name : String) -> SExpr {
  SExpr::Symbol(name)
}

/// Convert SExpr to Value (convert without evaluating).
pub fn sexpr_to_value(sexpr : SExpr) -> Value {
  match sexpr {
    SExpr::Nil => Value::Nil
    SExpr::Bool(b) => Value::Bool(b)
    SExpr::Symbol(name) => Value::Symbol(name)
    SExpr::Number(n) => Value::Number(Number::Int(n))
    SExpr::Char(c) => Value::Char(c)
    SExpr::String(s) => Value::String(s)
    SExpr::Pair(car, cdr) =>
      Value::Pair(sexpr_to_value(car), sexpr_to_value(cdr))
    SExpr::Vector(items) => {
      let values : Array[Value] = []
      for item in items {
        values.push(sexpr_to_value(item))
      }
      Value::Vector(values)
    }
    SExpr::Quote(expr) => sexpr_to_value(expr)
    SExpr::Quasiquote(expr) => Value::Pair(
      Value::Symbol("quasiquote"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
    SExpr::Unquote(expr) => Value::Pair(
      Value::Symbol("unquote"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
    SExpr::UnquoteSplicing(expr) => Value::Pair(
      Value::Symbol("unquote-splicing"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
  }
}
