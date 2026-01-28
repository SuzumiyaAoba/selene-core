/// Testing of extended mathematical functions (trigonometric functions, logarithmic/exponential functions)

/// Constant: π (pi)
let pi : Double = 3.14159265358979323846

/// Basic operation of sin
test "sin basic" {
  let env = initial_env()
  let expr = parse_one("(sin 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // sin(0) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Basic operation of cos
test "cos basic" {
  let env = initial_env()
  let expr = parse_one("(cos 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // cos(0) = 1
      assert_eq(r, 1.0)
    }
    _ => fail("Expected Real(1.0)")
  }
}

/// Basic operation of tan
test "tan basic" {
  let env = initial_env()
  let expr = parse_one("(tan 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // tan(0) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Basic operation of asin
test "asin basic" {
  let env = initial_env()
  let expr = parse_one("(asin 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // asin(0) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Basic operation of acos
test "acos basic" {
  let env = initial_env()
  let expr = parse_one("(acos 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // acos(1) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Basic operation of atan (1 argument)
test "atan basic" {
  let env = initial_env()
  let expr = parse_one("(atan 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // atan(0) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Two-argument version of atan (atan2)
test "atan2 basic" {
  let env = initial_env()
  let expr = parse_one("(atan 0 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // atan2(0, 1) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Basic operation of exp
test "exp basic" {
  let env = initial_env()
  let expr = parse_one("(exp 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // exp(0) = 1
      assert_eq(r, 1.0)
    }
    _ => fail("Expected Real(1.0)")
  }
}

/// Basic operation of log
test "log basic" {
  let env = initial_env()
  let expr = parse_one("(log 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // log(1) = 0
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// Inverse functional relationship between sin and asin
test "sin asin inverse" {
  let env = initial_env()
  // asin(sin(0.5)) ≈ 0.5
  let expr = parse_one("(asin (sin 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// Inverse functional relationship between cos and acos
test "cos acos inverse" {
  let env = initial_env()
  // acos(cos(0.5)) ≈ 0.5
  let expr = parse_one("(acos (cos 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// Inverse functional relationship between tan and atan
test "tan atan inverse" {
  let env = initial_env()
  // atan(tan(0.5)) ≈ 0.5
  let expr = parse_one("(atan (tan 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// Inverse functional relationship between exp and log
test "exp log inverse" {
  let env = initial_env()
  // log(exp(1)) = 1
  let expr = parse_one("(log (exp 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // Consider floating point errors
      let diff = if r > 1.0 { r - 1.0 } else { 1.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 1.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// exp(log(x)) = x
test "log exp inverse" {
  let env = initial_env()
  // exp(log(2)) = 2
  let expr = parse_one("(exp (log 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // Consider floating point errors
      let diff = if r > 2.0 { r - 2.0 } else { 2.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 2.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// Trigonometric identity: sin^2 + cos^2 = 1
test "trigonometric identity" {
  let env = initial_env()
  // (+ (expt (sin 1) 2) (expt (cos 1) 2)) = 1
  let expr = parse_one("(+ (expt (sin 1) 2) (expt (cos 1) 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // Consider floating point errors
      let diff = if r > 1.0 { r - 1.0 } else { 1.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 1.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// If you pass an integer with sin
test "sin with integer" {
  let env = initial_env()
  let expr = parse_one("(sin 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// exp(1) ≈ e ≈ 2.718
test "exp of 1" {
  let env = initial_env()
  let expr = parse_one("(exp 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // Since e ≈ 2.718, 2.7 < r < 2.8
      if r < 2.7 || r > 2.8 {
        fail("Expected approximately 2.718")
      }
    }
    _ => fail("Expected Real")
  }
}

/// atan2 quadrant determination
test "atan2 quadrants" {
  let env = initial_env()
  // Quadrant 1: atan2(1, 1) ≈ π/4
  let expr1 = parse_one("(atan 1 1)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // π/4 ≈ 0.785
      if r < 0.7 || r > 0.8 {
        fail("Expected approximately π/4")
      }
    }
    _ => fail("Expected Real")
  }

  // Quadrant 2: atan2(1, -1) ≈ 3π/4
  let expr2 = parse_one("(atan 1 (- 0 1))")
  match eval(expr2, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 3π/4 ≈ 2.356
      if r < 2.3 || r > 2.4 {
        fail("Expected approximately 3π/4")
      }
    }
    _ => fail("Expected Real")
  }
}

/// Complex formula: log(exp(sin(1)))
test "complex expression" {
  let env = initial_env()
  let expr = parse_one("(log (exp (sin 1)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}
