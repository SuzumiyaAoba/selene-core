/// 算術演算のテスト。

/// quotient演算のテスト。
test "builtin quotient" {
  let env = initial_env()
  let expr1 = parse_one("(quotient 10 3)")
  let expr2 = parse_one("(quotient (- 10) 3)")
  let expr3 = parse_one("(quotient 10 (- 3))")
  let expr4 = parse_one("(quotient (- 10) (- 3))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(-3))) => ()
    _ => fail("expected -3")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(-3))) => ()
    _ => fail("expected -3")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
}

/// remainder演算のテスト。
test "builtin remainder" {
  let env = initial_env()
  let expr1 = parse_one("(remainder 10 3)")
  let expr2 = parse_one("(remainder (- 10) 3)")
  let expr3 = parse_one("(remainder 10 (- 3))")
  let expr4 = parse_one("(remainder (- 10) (- 3))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(-1))) => ()
    _ => fail("expected -1")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(-1))) => ()
    _ => fail("expected -1")
  }
}

/// modulo演算のテスト。
test "builtin modulo" {
  let env = initial_env()
  let expr1 = parse_one("(modulo 10 3)")
  let expr2 = parse_one("(modulo (- 10) 3)")
  let expr3 = parse_one("(modulo 10 (- 3))")
  let expr4 = parse_one("(modulo (- 10) (- 3))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2 for (modulo (- 10) 3)")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(-2))) => ()
    _ => fail("expected -2 for (modulo 10 (- 3))")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(-1))) => ()
    _ => fail("expected -1 for (modulo (- 10) (- 3))")
  }
}

/// absのテスト。
test "builtin abs" {
  let env = initial_env()
  let expr1 = parse_one("(abs 5)")
  let expr2 = parse_one("(abs (- 5))")
  let expr3 = parse_one("(abs 0)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5 for (abs (- 5))")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
}

/// maxのテスト。
test "builtin max" {
  let env = initial_env()
  let expr1 = parse_one("(max 1)")
  let expr2 = parse_one("(max 1 2 3)")
  let expr3 = parse_one("(max 5 2 8 1)")
  let expr4 = parse_one("(max (- 3) (- 1) (- 5))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(8))) => ()
    _ => fail("expected 8")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(-1))) => ()
    _ => fail("expected -1")
  }
}

/// minのテスト。
test "builtin min" {
  let env = initial_env()
  let expr1 = parse_one("(min 1)")
  let expr2 = parse_one("(min 1 2 3)")
  let expr3 = parse_one("(min 5 2 8 1)")
  let expr4 = parse_one("(min (- 3) (- 1) (- 5))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(-5))) => ()
    _ => fail("expected -5")
  }
}

/// 基本的な算術演算のテスト。
test "basic arithmetic" {
  let env = initial_env()
  let expr1 = parse_one("(+ 1 2 3)")
  let expr2 = parse_one("(- 10 3 2)")
  let expr3 = parse_one("(* 2 3 4)")
  let expr4 = parse_one("(/ 100 2 5)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(6))) => ()
    _ => fail("expected 6 for (+ 1 2 3)")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5 for (- 10 3 2)")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(24))) => ()
    _ => fail("expected 24 for (* 2 3 4)")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail("expected 10 for (/ 100 2 5)")
  }
}

/// 単項演算のテスト。
test "unary operations" {
  let env = initial_env()
  let expr1 = parse_one("(- 5)")
  let expr2 = parse_one("(+ 5)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(-5))) => ()
    _ => fail("expected -5 for (- 5)")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5 for (+ 5)")
  }
}

/// ゼロ引数の算術演算のテスト。
test "zero argument arithmetic" {
  let env = initial_env()
  let expr1 = parse_one("(+)")
  let expr2 = parse_one("(*)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0 for (+)")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1 for (*)")
  }
}

/// ネストした算術演算のテスト。
test "nested arithmetic" {
  let env = initial_env()
  let expr = parse_one("(+ (* 2 3) (- 10 5) (abs (- 3)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(14))) => ()
    _ => fail("expected 14 for (+ (* 2 3) (- 10 5) (abs (- 3)))")
  }
}
