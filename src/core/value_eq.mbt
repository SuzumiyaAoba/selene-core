/// Value comparison helpers.
pub fn values_eqv(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Real(y))) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    _ => false
  }
}
