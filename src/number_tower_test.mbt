/// 数値塔（有理数・複素数）のテスト

// =============================================================================
// 有理数テスト
// =============================================================================

/// 有理数の生成（除算）
test "rational from division" {
  let env = initial_env()
  let expr = parse_one("(/ 1 2)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(1, 2))) => ()
    _ => fail!("expected 1/2")
  }
}

/// 有理数の正規化（既約分数）
test "rational normalization" {
  let env = initial_env()
  let expr = parse_one("(/ 4 8)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(1, 2))) => ()
    _ => fail!("expected 1/2")
  }
}

/// 有理数の加算
test "rational addition" {
  let env = initial_env()
  let expr = parse_one("(+ (/ 1 2) (/ 1 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(5, 6))) => ()
    _ => fail!("expected 5/6")
  }
}

/// 有理数の減算
test "rational subtraction" {
  let env = initial_env()
  let expr = parse_one("(- (/ 1 2) (/ 1 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(1, 6))) => ()
    _ => fail!("expected 1/6")
  }
}

/// 有理数の乗算
test "rational multiplication" {
  let env = initial_env()
  let expr = parse_one("(* (/ 1 2) (/ 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(1, 3))) => ()
    _ => fail!("expected 1/3")
  }
}

/// 有理数の除算
test "rational division" {
  let env = initial_env()
  let expr = parse_one("(/ (/ 1 2) (/ 1 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Rational(3, 2))) => ()
    _ => fail!("expected 3/2")
  }
}

/// numerator 関数
test "numerator function" {
  let env = initial_env()
  let expr = parse_one("(numerator (/ 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail!("expected 3")
  }
}

/// denominator 関数
test "denominator function" {
  let env = initial_env()
  let expr = parse_one("(denominator (/ 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail!("expected 4")
  }
}

/// 整数の numerator
test "numerator with integer" {
  let env = initial_env()
  let expr = parse_one("(numerator 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail!("expected 5")
  }
}

/// 整数の denominator
test "denominator with integer" {
  let env = initial_env()
  let expr = parse_one("(denominator 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail!("expected 1")
  }
}

/// rational? 述語
test "rational? predicate" {
  let env = initial_env()
  let expr = parse_one("(rational? (/ 1 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

/// rational? with integer
test "rational? with integer" {
  let env = initial_env()
  let expr = parse_one("(rational? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

/// exact? with rational
test "exact? with rational" {
  let env = initial_env()
  let expr = parse_one("(exact? (/ 1 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

// =============================================================================
// 複素数テスト
// =============================================================================

/// make-rectangular で複素数を作成
test "make-rectangular" {
  let env = initial_env()
  let expr = parse_one("(make-rectangular 3 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Complex(3.0, 4.0))) => ()
    _ => fail!("expected 3+4i")
  }
}

/// 虚部が0なら実数
test "make-rectangular with zero imag" {
  let env = initial_env()
  let expr = parse_one("(make-rectangular 5 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(5.0))) => ()
    _ => fail!("expected 5.0")
  }
}

/// real-part
test "real-part function" {
  let env = initial_env()
  let expr = parse_one("(real-part (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(r))) => {
      if r == 3.0 {
        ()
      } else {
        fail!("expected 3.0")
      }
    }
    _ => fail!("expected 3.0")
  }
}

/// imag-part
test "imag-part function" {
  let env = initial_env()
  let expr = parse_one("(imag-part (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(i))) => {
      if i == 4.0 {
        ()
      } else {
        fail!("expected 4.0")
      }
    }
    _ => fail!("expected 4.0")
  }
}

/// 実数の imag-part は 0
test "imag-part of real" {
  let env = initial_env()
  let expr = parse_one("(imag-part 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(0.0))) => ()
    _ => fail!("expected 0.0")
  }
}

/// magnitude (絶対値)
test "magnitude function" {
  let env = initial_env()
  let expr = parse_one("(magnitude (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(m))) => {
      if m == 5.0 {
        ()
      } else {
        fail!("expected 5.0")
      }
    }
    _ => fail!("expected 5.0")
  }
}

/// complex? 述語（すべての数は複素数）
test "complex? predicate" {
  let env = initial_env()
  let expr = parse_one("(complex? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

/// complex? with complex
test "complex? with complex" {
  let env = initial_env()
  let expr = parse_one("(complex? (make-rectangular 1 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

/// 複素数の加算
test "complex addition" {
  let env = initial_env()
  let expr = parse_one("(+ (make-rectangular 1 2) (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Complex(r, i))) => {
      if r == 4.0 && i == 6.0 {
        ()
      } else {
        fail!("expected 4+6i")
      }
    }
    _ => fail!("expected 4+6i")
  }
}

/// 複素数の減算
test "complex subtraction" {
  let env = initial_env()
  let expr = parse_one("(- (make-rectangular 5 3) (make-rectangular 2 1))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Complex(r, i))) => {
      if r == 3.0 && i == 2.0 {
        ()
      } else {
        fail!("expected 3+2i")
      }
    }
    _ => fail!("expected 3+2i")
  }
}

/// 複素数の乗算
test "complex multiplication" {
  let env = initial_env()
  // (1+2i) * (3+4i) = 3 + 4i + 6i + 8i^2 = 3 + 10i - 8 = -5 + 10i
  let expr = parse_one("(* (make-rectangular 1 2) (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Complex(r, i))) => {
      if r == -5.0 && i == 10.0 {
        ()
      } else {
        fail!("expected -5+10i")
      }
    }
    _ => fail!("expected -5+10i")
  }
}

/// 複素数の絶対値 (abs)
test "abs with complex" {
  let env = initial_env()
  let expr = parse_one("(abs (make-rectangular 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Real(m))) => {
      if m == 5.0 {
        ()
      } else {
        fail!("expected 5.0")
      }
    }
    _ => fail!("expected 5.0")
  }
}

/// inexact? with complex
test "inexact? with complex" {
  let env = initial_env()
  let expr = parse_one("(inexact? (make-rectangular 1 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}
