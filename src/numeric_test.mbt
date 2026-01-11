/// 数値関数のテスト
/// 注: レキサーが実数リテラルをサポートしていないため、
/// 実数を使うテストはsqrtなどで生成した実数を利用します

/// floor で整数
test "floor integer" {
  let env = initial_env()
  let expr = parse_one("(floor 5)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// floor で sqrt の結果
test "floor with sqrt" {
  let env = initial_env()
  let expr = parse_one("(floor (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// ceiling で整数
test "ceiling integer" {
  let env = initial_env()
  let expr = parse_one("(ceiling 7)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("Expected Int(7)")
  }
}

/// ceiling で sqrt の結果
test "ceiling with sqrt" {
  let env = initial_env()
  let expr = parse_one("(ceiling (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("Expected Int(4)")
  }
}

/// truncate で整数
test "truncate integer" {
  let env = initial_env()
  let expr = parse_one("(truncate 9)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(9))) => ()
    _ => fail("Expected Int(9)")
  }
}

/// truncate で sqrt の結果
test "truncate with sqrt" {
  let env = initial_env()
  let expr = parse_one("(truncate (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// round で整数
test "round integer" {
  let env = initial_env()
  let expr = parse_one("(round 7)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("Expected Int(7)")
  }
}

/// round で sqrt の結果
test "round with sqrt" {
  let env = initial_env()
  let expr = parse_one("(round (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// sqrt の基本的な動作
test "sqrt basic" {
  let env = initial_env()
  let expr = parse_one("(sqrt 4)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      assert_eq(r, 2.0)
    }
    _ => fail("Expected Real(2.0)")
  }
}

/// sqrt で 0
test "sqrt zero" {
  let env = initial_env()
  let expr = parse_one("(sqrt 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      assert_eq(r, 0.0)
    }
    _ => fail("Expected Real(0.0)")
  }
}

/// sqrt で 9
test "sqrt nine" {
  let env = initial_env()
  let expr = parse_one("(sqrt 9)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      assert_eq(r, 3.0)
    }
    _ => fail("Expected Real(3.0)")
  }
}

/// expt の基本的な動作（整数のべき乗）
test "expt basic integer" {
  let env = initial_env()
  let expr = parse_one("(expt 2 3)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(8))) => ()
    _ => fail("Expected Int(8)")
  }
}

/// expt で指数が 0
test "expt zero exponent" {
  let env = initial_env()
  let expr = parse_one("(expt 5 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("Expected Int(1)")
  }
}

/// expt で負の指数
test "expt negative exponent" {
  let env = initial_env()
  let expr = parse_one("(expt 2 (- 0 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      assert_eq(r, 0.25)
    }
    _ => fail("Expected Real(0.25)")
  }
}

/// expt で 10^3
test "expt 10 to 3" {
  let env = initial_env()
  let expr = parse_one("(expt 10 3)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1000))) => ()
    _ => fail("Expected Int(1000)")
  }
}

/// exact? の基本的な動作
test "exact? with integer" {
  let env = initial_env()
  let expr = parse_one("(exact? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// exact? で sqrt の結果（実数）
test "exact? with sqrt" {
  let env = initial_env()
  let expr = parse_one("(exact? (sqrt 2))")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// inexact? で整数
test "inexact? with integer" {
  let env = initial_env()
  let expr = parse_one("(inexact? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// inexact? で sqrt の結果（実数）
test "inexact? with sqrt" {
  let env = initial_env()
  let expr = parse_one("(inexact? (sqrt 2))")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// number->string の基本的な動作（整数）
test "number->string integer" {
  let env = initial_env()
  let expr = parse_one("(number->string 42)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "42")
    _ => fail("Expected String(\"42\")")
  }
}

/// number->string で 0
test "number->string zero" {
  let env = initial_env()
  let expr = parse_one("(number->string 0)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "0")
    _ => fail("Expected String(\"0\")")
  }
}

/// number->string で負の数
test "number->string negative" {
  let env = initial_env()
  let expr = parse_one("(number->string (- 0 123))")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "-123")
    _ => fail("Expected String(\"-123\")")
  }
}

/// number->string で sqrt の結果
test "number->string with sqrt" {
  let env = initial_env()
  let expr = parse_one("(number->string (sqrt 4))")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "2")
    _ => fail("Expected String(\"2\")")
  }
}

/// sqrt と expt の組み合わせ
test "sqrt and expt combined" {
  let env = initial_env()
  let expr = parse_one("(expt (sqrt 4) 2)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      assert_eq(r, 4.0)
    }
    _ => fail("Expected Real(4.0)")
  }
}

/// floor, ceiling, round の比較
test "rounding functions comparison" {
  let env = initial_env()
  // sqrt(17) ≈ 4.12 なので、floor=4, ceiling=5, round=4
  let expr1 = parse_one("(floor (sqrt 17))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("Expected Int(4) for floor")
  }
  let expr2 = parse_one("(ceiling (sqrt 17))")
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5) for ceiling")
  }
  let expr3 = parse_one("(round (sqrt 17))")
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("Expected Int(4) for round")
  }
}
