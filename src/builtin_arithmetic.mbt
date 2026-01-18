/// 算術演算組み込み関数
///
/// Scheme の基本的な算術演算を実装する。

/// 数値を期待するヘルパー関数
fn expect_number(value : Value) -> Result[Number, EvalError] {
  match value {
    Value::Number(n) => Ok(n)
    _ => Err(EvalError::TypeError("expected number"))
  }
}

/// 整数演算（簡易版）。
fn add_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x + y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x + y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() + y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x + y.to_double())
  }
}

fn sub_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x - y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x - y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() - y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x - y.to_double())
  }
}

fn mul_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x * y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x * y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() * y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x * y.to_double())
  }
}

fn div_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x / y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x / y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() / y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x / y.to_double())
  }
}

fn max_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(if x > y { x } else { y })
    (Number::Real(x), Number::Real(y)) => Number::Real(if x > y { x } else { y })
    (Number::Int(x), Number::Real(y)) => {
      let x_real = x.to_double()
      Number::Real(if x_real > y { x_real } else { y })
    }
    (Number::Real(x), Number::Int(y)) => {
      let y_real = y.to_double()
      Number::Real(if x > y_real { x } else { y_real })
    }
  }
}

fn min_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(if x < y { x } else { y })
    (Number::Real(x), Number::Real(y)) => Number::Real(if x < y { x } else { y })
    (Number::Int(x), Number::Real(y)) => {
      let x_real = x.to_double()
      Number::Real(if x_real < y { x_real } else { y })
    }
    (Number::Real(x), Number::Int(y)) => {
      let y_real = y.to_double()
      Number::Real(if x < y_real { x } else { y_real })
    }
  }
}

/// 組み込み関数: +
fn builtin_add(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(0)))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = add_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: -
fn builtin_sub(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("-: requires at least 1 argument"))
  }
  if args.length() == 1 {
    let num = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    return Ok(
      Value::Number(
        match num {
          Number::Int(x) => Number::Int(-x)
          Number::Real(x) => Number::Real(-x)
        },
      ),
    )
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = sub_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: *
fn builtin_mul(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(1)))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = mul_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: /
fn builtin_div(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("/: requires at least 1 argument"))
  }
  if args.length() == 1 {
    let num = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    return Ok(
      Value::Number(
        match num {
          Number::Int(x) => Number::Int(1 / x)
          Number::Real(x) => Number::Real(1.0 / x)
        },
      ),
    )
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = div_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: quotient
fn builtin_quotient(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("quotient: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("quotient: division by zero"))
      }
      Ok(Value::Number(Number::Int(x / y)))
    }
    _ => Err(EvalError::TypeError("quotient: requires integer arguments"))
  }
}

/// 組み込み関数: remainder
fn builtin_remainder(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("remainder: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("remainder: division by zero"))
      }
      Ok(Value::Number(Number::Int(x % y)))
    }
    _ => Err(EvalError::TypeError("remainder: requires integer arguments"))
  }
}

/// 組み込み関数: modulo
fn builtin_modulo(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("modulo: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("modulo: division by zero"))
      }
      let r = x % y
      // Scheme modulo: result has same sign as divisor
      let result = if (r > 0 && y < 0) || (r < 0 && y > 0) { r + y } else { r }
      Ok(Value::Number(Number::Int(result)))
    }
    _ => Err(EvalError::TypeError("modulo: requires integer arguments"))
  }
}

/// 組み込み関数: abs
fn builtin_abs(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("abs: requires exactly 1 argument"))
  }
  let num = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  Ok(
    Value::Number(
      match num {
        Number::Int(x) => Number::Int(if x < 0 { -x } else { x })
        Number::Real(x) => Number::Real(if x < 0.0 { -x } else { x })
      },
    ),
  )
}

/// 組み込み関数: max
fn builtin_max(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("max: requires at least 1 argument"))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = max_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: min
fn builtin_min(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("min: requires at least 1 argument"))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = min_numbers(result, num)
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Number(result))
}

/// 組み込み関数: gcd
/// (gcd n1 n2 ...) - 最大公約数を計算
fn builtin_gcd(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(0)))
  }

  fn gcd_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if b_abs == 0 {
      a_abs
    } else {
      gcd_two(b_abs, a_abs % b_abs)
    }
  }

  let mut result = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(EvalError::TypeError("gcd: arguments must be integers"))
  }

  let mut i = 1
  let _ = while i < args.length() {
    let n = match args[i] {
      Value::Number(Number::Int(n)) => n
      _ => return Err(EvalError::TypeError("gcd: arguments must be integers"))
    }
    result = gcd_two(result, n)
    i = i + 1
  } else {
    ()
  }

  Ok(Value::Number(Number::Int(result)))
}

/// 組み込み関数: lcm
/// (lcm n1 n2 ...) - 最小公倍数を計算
fn builtin_lcm(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(1)))
  }

  fn gcd_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if b_abs == 0 {
      a_abs
    } else {
      gcd_two(b_abs, a_abs % b_abs)
    }
  }

  fn lcm_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if a_abs == 0 || b_abs == 0 {
      0
    } else {
      (a_abs / gcd_two(a_abs, b_abs)) * b_abs
    }
  }

  let mut result = match args[0] {
    Value::Number(Number::Int(n)) => if n < 0 { -n } else { n }
    _ => return Err(EvalError::TypeError("lcm: arguments must be integers"))
  }

  let mut i = 1
  let _ = while i < args.length() {
    let n = match args[i] {
      Value::Number(Number::Int(n)) => n
      _ => return Err(EvalError::TypeError("lcm: arguments must be integers"))
    }
    result = lcm_two(result, n)
    i = i + 1
  } else {
    ()
  }

  Ok(Value::Number(Number::Int(result)))
}

/// 数値比較の補助関数
fn compare_numbers(op : String, a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      match op {
        "=" => x == y
        "<" => x < y
        ">" => x > y
        "<=" => x <= y
        ">=" => x >= y
        _ => false
      }
    }
    (Number::Real(x), Number::Real(y)) => {
      match op {
        "=" => x == y
        "<" => x < y
        ">" => x > y
        "<=" => x <= y
        ">=" => x >= y
        _ => false
      }
    }
    (Number::Int(x), Number::Real(y)) => {
      let xd = x.to_double()
      match op {
        "=" => xd == y
        "<" => xd < y
        ">" => xd > y
        "<=" => xd <= y
        ">=" => xd >= y
        _ => false
      }
    }
    (Number::Real(x), Number::Int(y)) => {
      let yd = y.to_double()
      match op {
        "=" => x == yd
        "<" => x < yd
        ">" => x > yd
        "<=" => x <= yd
        ">=" => x >= yd
        _ => false
      }
    }
  }
}

/// 組み込み関数: =
fn builtin_num_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("=: requires at least 2 arguments"))
  }
  let first = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers("=", first, num) {
      return Ok(Value::Bool(false))
    }
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Bool(true))
}

/// 組み込み関数: <
fn builtin_lt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("<: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers("<", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Bool(true))
}

/// 組み込み関数: >
fn builtin_gt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError(">: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers(">", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Bool(true))
}

/// 組み込み関数: <=
fn builtin_le(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("<=: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers("<=", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Bool(true))
}

/// 組み込み関数: >=
fn builtin_ge(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError(">=: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers(">=", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else {
    ()
  }
  Ok(Value::Bool(true))
}
