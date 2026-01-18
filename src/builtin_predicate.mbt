/// 述語組み込み関数
///
/// Scheme の型チェックと等価性テストを実装する。

/// 組み込み関数: null?
fn builtin_null_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("null?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Nil => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: procedure?
fn builtin_procedure_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("procedure?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Procedure(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: list?
fn builtin_list_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("list?: requires exactly 1 argument"))
  }
  fn is_list(v : Value) -> Bool {
    match v {
      Value::Nil => true
      Value::Pair(_, cdr) => is_list(cdr)
      _ => false
    }
  }
  Ok(Value::Bool(is_list(args[0])))
}

/// 組み込み関数: integer?
fn builtin_integer_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("integer?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Real(r)) => {
      // 整数値を持つ実数も integer? は #t を返す
      Ok(Value::Bool(r.floor() == r))
    }
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: real?
fn builtin_real_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("real?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: zero?
fn builtin_zero_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("zero?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n == 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r == 0.0))
    _ => Err(EvalError::TypeError("zero?: argument must be a number"))
  }
}

/// 組み込み関数: positive?
fn builtin_positive_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("positive?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n > 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r > 0.0))
    _ => Err(EvalError::TypeError("positive?: argument must be a number"))
  }
}

/// 組み込み関数: negative?
fn builtin_negative_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("negative?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n < 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r < 0.0))
    _ => Err(EvalError::TypeError("negative?: argument must be a number"))
  }
}

/// 組み込み関数: odd?
fn builtin_odd_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("odd?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n % 2 != 0))
    Value::Number(Number::Real(r)) => {
      if r.floor() != r {
        Err(EvalError::TypeError("odd?: argument must be an integer"))
      } else {
        Ok(Value::Bool(r.to_int() % 2 != 0))
      }
    }
    _ => Err(EvalError::TypeError("odd?: argument must be an integer"))
  }
}

/// 組み込み関数: even?
fn builtin_even_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("even?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n % 2 == 0))
    Value::Number(Number::Real(r)) => {
      if r.floor() != r {
        Err(EvalError::TypeError("even?: argument must be an integer"))
      } else {
        Ok(Value::Bool(r.to_int() % 2 == 0))
      }
    }
    _ => Err(EvalError::TypeError("even?: argument must be an integer"))
  }
}

/// 組み込み関数: pair?
fn builtin_pair_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("pair?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, _) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: number?
fn builtin_number_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("number?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: boolean?
fn builtin_boolean_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("boolean?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Bool(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: eq?
fn builtin_eq_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("eq?: requires exactly 2 arguments"))
  }
  // 簡易実装: 数値とブール値の等価性チェック
  let result = match (args[0], args[1]) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(a), Value::Bool(b)) => a == b
    (Value::Number(Number::Int(a)), Value::Number(Number::Int(b))) => a == b
    (Value::Symbol(a), Value::Symbol(b)) => a == b
    _ => false
  }
  Ok(Value::Bool(result))
}

/// 組み込み関数: eqv?
/// eq? よりも緩い等価性チェック（数値も含む）
fn builtin_eqv_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("eqv?: requires exactly 2 arguments"))
  }
  let result = match (args[0], args[1]) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(a), Value::Bool(b)) => a == b
    (Value::Number(Number::Int(a)), Value::Number(Number::Int(b))) => a == b
    (Value::Number(Number::Real(a)), Value::Number(Number::Real(b))) => a == b
    (Value::Char(a), Value::Char(b)) => a == b
    (Value::Symbol(a), Value::Symbol(b)) => a == b
    (Value::String(a), Value::String(b)) => physical_identity(a, b)
    (Value::Pair(_, _), Value::Pair(_, _)) => physical_identity(args[0], args[1])
    (Value::Vector(_), Value::Vector(_)) => physical_identity(args[0], args[1])
    (Value::Procedure(Procedure::Native(a)), Value::Procedure(Procedure::Native(b))) =>
      a == b
    (
      Value::Procedure(Procedure::Closure(_, _, _)),
      Value::Procedure(Procedure::Closure(_, _, _)),
    ) => physical_identity(args[0], args[1])
    (Value::Procedure(Procedure::Cont(a)), Value::Procedure(Procedure::Cont(b))) =>
      a.id == b.id
    _ => false
  }
  Ok(Value::Bool(result))
}

/// 物理的同一性をチェックするヘルパー関数
/// MoonBit では参照比較が難しいため、常に false を返す
fn physical_identity[T](_a : T, _b : T) -> Bool {
  false
}

/// 組み込み関数: equal?
/// 構造的等価性をチェック（深い比較）
fn builtin_equal_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("equal?: requires exactly 2 arguments"))
  }
  Ok(Value::Bool(values_equal(args[0], args[1])))
}

/// 2つの Value が構造的に等しいかチェックする
fn values_equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Real(y))) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Real(y))) =>
      x.to_double() == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Int(y))) =>
      x == y.to_double()
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::String(x), Value::String(y)) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Pair(car1, cdr1), Value::Pair(car2, cdr2)) =>
      values_equal(car1, car2) && values_equal(cdr1, cdr2)
    (Value::Vector(v1), Value::Vector(v2)) => {
      if v1.length() != v2.length() {
        false
      } else {
        let mut i = 0
        let len = v1.length()
        let mut result = true
        let _ = while i < len {
          if not(values_equal(v1[i], v2[i])) {
            result = false
            break
          }
          i = i + 1
        } else {
          ()
        }
        result
      }
    }
    (Value::Procedure(Procedure::Native(x)), Value::Procedure(Procedure::Native(y))) =>
      x == y
    (Value::Procedure(Procedure::Cont(x)), Value::Procedure(Procedure::Cont(y))) =>
      x.id == y.id
    _ => false
  }
}

/// 組み込み関数: not
fn builtin_not(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("not: requires exactly 1 argument"))
  }
  let result = match args[0] {
    Value::Bool(false) => true
    _ => false
  }
  Ok(Value::Bool(result))
}
