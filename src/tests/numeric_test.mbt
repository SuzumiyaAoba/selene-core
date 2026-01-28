/// Testing numerical functions
/// Note: Because the lexer does not support real literals,
/// Tests that use real numbers use real numbers generated with sqrt etc.

/// integer on floor
test "floor integer" {
  let env = initial_env()
  let expr = parse_one("(floor 5)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// sqrt result on floor
test "floor with sqrt" {
  let env = initial_env()
  let expr = parse_one("(floor (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// ceiling and integer
test "ceiling integer" {
  let env = initial_env()
  let expr = parse_one("(ceiling 7)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("Expected Int(7)")
  }
}

/// sqrt result with ceiling
test "ceiling with sqrt" {
  let env = initial_env()
  let expr = parse_one("(ceiling (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("Expected Int(4)")
  }
}

/// truncate integer
test "truncate integer" {
  let env = initial_env()
  let expr = parse_one("(truncate 9)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(9))) => ()
    _ => fail("Expected Int(9)")
  }
}

/// sqrt result with truncate
test "truncate with sqrt" {
  let env = initial_env()
  let expr = parse_one("(truncate (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// integer in round
test "round integer" {
  let env = initial_env()
  let expr = parse_one("(round 7)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("Expected Int(7)")
  }
}

/// sqrt result in round
test "round with sqrt" {
  let env = initial_env()
  let expr = parse_one("(round (sqrt 10))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("Expected Int(3)")
  }
}

/// Basic operation of sqrt
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

/// 0 in sqrt
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

/// sqrt at 9
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

/// Basic operation of expt (integer power)
test "expt basic integer" {
  let env = initial_env()
  let expr = parse_one("(expt 2 3)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(8))) => ()
    _ => fail("Expected Int(8)")
  }
}

/// expt with exponent 0
test "expt zero exponent" {
  let env = initial_env()
  let expr = parse_one("(expt 5 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("Expected Int(1)")
  }
}

/// Negative exponent in expt
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

/// 10^3 in expt
test "expt 10 to 3" {
  let env = initial_env()
  let expr = parse_one("(expt 10 3)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1000))) => ()
    _ => fail("Expected Int(1000)")
  }
}

/// Basic behavior of exact?
test "exact? with integer" {
  let env = initial_env()
  let expr = parse_one("(exact? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// sqrt result (real number) with exact?
test "exact? with sqrt" {
  let env = initial_env()
  let expr = parse_one("(exact? (sqrt 2))")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Integer with inexact?
test "inexact? with integer" {
  let env = initial_env()
  let expr = parse_one("(inexact? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// sqrt result (real number) with inexact?
test "inexact? with sqrt" {
  let env = initial_env()
  let expr = parse_one("(inexact? (sqrt 2))")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// Basic behavior of number->string (integer)
test "number->string integer" {
  let env = initial_env()
  let expr = parse_one("(number->string 42)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "42")
    _ => fail("Expected String(\"42\")")
  }
}

/// 0 in number->string
test "number->string zero" {
  let env = initial_env()
  let expr = parse_one("(number->string 0)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "0")
    _ => fail("Expected String(\"0\")")
  }
}

/// negative number in number->string
test "number->string negative" {
  let env = initial_env()
  let expr = parse_one("(number->string (- 0 123))")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "-123")
    _ => fail("Expected String(\"-123\")")
  }
}

/// sqrt result with number->string
test "number->string with sqrt" {
  let env = initial_env()
  let expr = parse_one("(number->string (sqrt 4))")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "2")
    _ => fail("Expected String(\"2\")")
  }
}

/// Combination of sqrt and expt
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

/// Comparison of floor, ceiling, round
test "rounding functions comparison" {
  let env = initial_env()
  // sqrt(17) ≈ 4.12, so floor=4, ceiling=5, round=4
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
