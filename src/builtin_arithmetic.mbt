/// Arithmetic built-in functions
///
/// Implement basic arithmetic operations of Scheme.

/// A helper function that expects a number
fn expect_number(value : Value) -> Result[Number, EvalError] {
  match value {
    Value::Number(n) => Ok(n)
    _ => Err(EvalError::TypeError("expected number"))
  }
}

/// Convert a number to Double
fn number_to_double(n : Number) -> Double {
  match n {
    Number::Int(x) => x.to_double()
    Number::Rational(num, den) => num.to_double() / den.to_double()
    Number::Real(x) => x
    Number::Complex(r, _) => r // Real parts only
  }
}

/// Whether the number is complex or not
fn is_complex(n : Number) -> Bool {
  match n {
    Number::Complex(_, _) => true
    _ => false
  }
}

/// Get the real and imaginary parts of a complex number from a number
fn to_complex_parts(n : Number) -> (Double, Double) {
  match n {
    Number::Int(x) => (x.to_double(), 0.0)
    Number::Rational(num, den) => (num.to_double() / den.to_double(), 0.0)
    Number::Real(x) => (x, 0.0)
    Number::Complex(r, i) => (r, i)
  }
}

/// Normalize the result of a complex number (to a real number if the imaginary part is 0)
fn normalize_complex(r : Double, i : Double) -> Number {
  if i == 0.0 {
    Number::Real(r)
  } else {
    Number::Complex(r, i)
  }
}

/// Integer operation (extended version: rational and complex numbers)
fn add_numbers(a : Number, b : Number) -> Number {
  // If complex numbers are included
  if is_complex(a) || is_complex(b) {
    let (ar, ai) = to_complex_parts(a)
    let (br, bi) = to_complex_parts(b)
    return normalize_complex(ar + br, ai + bi)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x + y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x + y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() + y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x + y.to_double())
    // Addition of Rational Numbers
    (Number::Rational(n1, d1), Number::Rational(n2, d2)) =>
      normalize_rational(n1 * d2 + n2 * d1, d1 * d2)
    (Number::Int(x), Number::Rational(n, d)) =>
      normalize_rational(x * d + n, d)
    (Number::Rational(n, d), Number::Int(y)) =>
      normalize_rational(n + y * d, d)
    (Number::Real(x), Number::Rational(n, d)) =>
      Number::Real(x + n.to_double() / d.to_double())
    (Number::Rational(n, d), Number::Real(y)) =>
      Number::Real(n.to_double() / d.to_double() + y)
    // Complex numbers processed above
    (Number::Complex(_, _), _) => Number::Int(0) // unreachable
    (_, Number::Complex(_, _)) => Number::Int(0) // unreachable
  }
}

fn sub_numbers(a : Number, b : Number) -> Number {
  if is_complex(a) || is_complex(b) {
    let (ar, ai) = to_complex_parts(a)
    let (br, bi) = to_complex_parts(b)
    return normalize_complex(ar - br, ai - bi)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x - y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x - y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() - y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x - y.to_double())
    (Number::Rational(n1, d1), Number::Rational(n2, d2)) =>
      normalize_rational(n1 * d2 - n2 * d1, d1 * d2)
    (Number::Int(x), Number::Rational(n, d)) =>
      normalize_rational(x * d - n, d)
    (Number::Rational(n, d), Number::Int(y)) =>
      normalize_rational(n - y * d, d)
    (Number::Real(x), Number::Rational(n, d)) =>
      Number::Real(x - n.to_double() / d.to_double())
    (Number::Rational(n, d), Number::Real(y)) =>
      Number::Real(n.to_double() / d.to_double() - y)
    (Number::Complex(_, _), _) => Number::Int(0)
    (_, Number::Complex(_, _)) => Number::Int(0)
  }
}

fn mul_numbers(a : Number, b : Number) -> Number {
  if is_complex(a) || is_complex(b) {
    let (ar, ai) = to_complex_parts(a)
    let (br, bi) = to_complex_parts(b)
    // (ar + ai*i) * (br + bi*i) = (ar*br - ai*bi) + (ar*bi + ai*br)*i
    return normalize_complex(ar * br - ai * bi, ar * bi + ai * br)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x * y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x * y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() * y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x * y.to_double())
    (Number::Rational(n1, d1), Number::Rational(n2, d2)) =>
      normalize_rational(n1 * n2, d1 * d2)
    (Number::Int(x), Number::Rational(n, d)) =>
      normalize_rational(x * n, d)
    (Number::Rational(n, d), Number::Int(y)) =>
      normalize_rational(n * y, d)
    (Number::Real(x), Number::Rational(n, d)) =>
      Number::Real(x * n.to_double() / d.to_double())
    (Number::Rational(n, d), Number::Real(y)) =>
      Number::Real(n.to_double() / d.to_double() * y)
    (Number::Complex(_, _), _) => Number::Int(0)
    (_, Number::Complex(_, _)) => Number::Int(0)
  }
}

fn div_numbers(a : Number, b : Number) -> Number {
  if is_complex(a) || is_complex(b) {
    let (ar, ai) = to_complex_parts(a)
    let (br, bi) = to_complex_parts(b)
    // (ar + ai*i) / (br + bi*i) = ((ar*br + ai*bi) + (ai*br - ar*bi)*i) / (br^2 + bi^2)
    let denom = br * br + bi * bi
    return normalize_complex((ar * br + ai * bi) / denom, (ai * br - ar * bi) / denom)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) =>
      // Returns a rational number if it is not divisible by an integer division
      if x % y == 0 {
        Number::Int(x / y)
      } else {
        normalize_rational(x, y)
      }
    (Number::Real(x), Number::Real(y)) => Number::Real(x / y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() / y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x / y.to_double())
    (Number::Rational(n1, d1), Number::Rational(n2, d2)) =>
      normalize_rational(n1 * d2, d1 * n2)
    (Number::Int(x), Number::Rational(n, d)) =>
      normalize_rational(x * d, n)
    (Number::Rational(n, d), Number::Int(y)) =>
      normalize_rational(n, d * y)
    (Number::Real(x), Number::Rational(n, d)) =>
      Number::Real(x * d.to_double() / n.to_double())
    (Number::Rational(n, d), Number::Real(y)) =>
      Number::Real(n.to_double() / d.to_double() / y)
    (Number::Complex(_, _), _) => Number::Int(0)
    (_, Number::Complex(_, _)) => Number::Int(0)
  }
}

fn max_numbers(a : Number, b : Number) -> Number {
  let av = number_to_double(a)
  let bv = number_to_double(b)
  if av > bv { a } else { b }
}

fn min_numbers(a : Number, b : Number) -> Number {
  let av = number_to_double(a)
  let bv = number_to_double(b)
  if av < bv { a } else { b }
}

/// Built-in functions: +
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

/// Built-in functions: -
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
          Number::Rational(n, d) => Number::Rational(-n, d)
          Number::Real(x) => Number::Real(-x)
          Number::Complex(r, i) => Number::Complex(-r, -i)
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

/// Built-in functions: *
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

/// Built-in functions:/
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
          Number::Int(x) => normalize_rational(1, x)
          Number::Rational(n, d) => normalize_rational(d, n)
          Number::Real(x) => Number::Real(1.0 / x)
          Number::Complex(r, i) => {
            let denom = r * r + i * i
            Number::Complex(r / denom, -i / denom)
          }
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

/// Built-in function: quotient
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

/// Built-in function: remainder
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

/// Built-in function: modulo
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

/// Built-in function: abs
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
        Number::Rational(n, d) => Number::Rational(if n < 0 { -n } else { n }, d)
        Number::Real(x) => Number::Real(if x < 0.0 { -x } else { x })
        Number::Complex(r, i) => {
          // The absolute value of a complex number becomes a real number
          let mag = (r * r + i * i).sqrt()
          Number::Real(mag)
        }
      },
    ),
  )
}

/// Built-in functions: max
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

/// Built-in function: min
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

/// Built-in function: gcd
/// (gcd n1n2...) - calculate maximum common factor
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

/// Built-in functions: lcm
/// (lcm n1n2...) - calculate least common multiple
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

/// Auxiliary function for numerical comparison
fn compare_numbers(op : String, a : Number, b : Number) -> Bool {
  // Complex numbers can only be compared with =
  match (a, b) {
    (Number::Complex(ar, ai), Number::Complex(br, bi)) => {
      match op {
        "=" => ar == br && ai == bi
        _ => false // Complex numbers cannot be compared in order
      }
    }
    (Number::Complex(_, _), _) | (_, Number::Complex(_, _)) => {
      match op {
        "=" => false // Complex and non-complex numbers are not equal
        _ => false
      }
    }
    _ => {
      // Convert to real numbers and compare
      let av = number_to_double(a)
      let bv = number_to_double(b)
      match op {
        "=" => av == bv
        "<" => av < bv
        ">" => av > bv
        "<=" => av <= bv
        ">=" => av >= bv
        _ => false
      }
    }
  }
}

/// Built-in functions: =
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

/// Built-in functions: <
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

/// Built-in functions: >
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

/// Built-in functions: < =
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

/// Built-in functions: > =
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
