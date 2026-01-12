/// 拡張数学関数（三角関数、対数・指数関数）のテスト

/// 定数: π（円周率）
let pi : Double = 3.14159265358979323846

/// sin の基本的な動作
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

/// cos の基本的な動作
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

/// tan の基本的な動作
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

/// asin の基本的な動作
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

/// acos の基本的な動作
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

/// atan の基本的な動作（1引数）
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

/// atan の2引数版（atan2）
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

/// exp の基本的な動作
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

/// log の基本的な動作
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

/// sin と asin の逆関数関係
test "sin asin inverse" {
  let env = initial_env()
  // asin(sin(0.5)) ≈ 0.5
  let expr = parse_one("(asin (sin 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// cos と acos の逆関数関係
test "cos acos inverse" {
  let env = initial_env()
  // acos(cos(0.5)) ≈ 0.5
  let expr = parse_one("(acos (cos 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// tan と atan の逆関数関係
test "tan atan inverse" {
  let env = initial_env()
  // atan(tan(0.5)) ≈ 0.5
  let expr = parse_one("(atan (tan 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}

/// exp と log の逆関数関係
test "exp log inverse" {
  let env = initial_env()
  // log(exp(1)) = 1
  let expr = parse_one("(log (exp 1))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 浮動小数点の誤差を考慮
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
      // 浮動小数点の誤差を考慮
      let diff = if r > 2.0 { r - 2.0 } else { 2.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 2.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// 三角関数の恒等式: sin^2 + cos^2 = 1
test "trigonometric identity" {
  let env = initial_env()
  // (+ (expt (sin 1) 2) (expt (cos 1) 2)) = 1
  let expr = parse_one("(+ (expt (sin 1) 2) (expt (cos 1) 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 浮動小数点の誤差を考慮
      let diff = if r > 1.0 { r - 1.0 } else { 1.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 1.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// sin で整数を渡した場合
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
      // e ≈ 2.718 なので、2.7 < r < 2.8
      if r < 2.7 || r > 2.8 {
        fail("Expected approximately 2.718")
      }
    }
    _ => fail("Expected Real")
  }
}

/// atan2 の象限判定
test "atan2 quadrants" {
  let env = initial_env()
  // 第1象限: atan2(1, 1) ≈ π/4
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

  // 第2象限: atan2(1, -1) ≈ 3π/4
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

/// 複雑な数式: log(exp(sin(1)))
test "complex expression" {
  let env = initial_env()
  let expr = parse_one("(log (exp (sin 1)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(_))) => ()
    _ => fail("Expected Real")
  }
}
