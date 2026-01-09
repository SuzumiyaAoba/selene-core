/// 組み込み手続きのテスト。

/// ブール値リテラルの評価。
test "eval boolean literals" {
  let env = initial_env()
  let expr_t = parse_one("#t")
  let expr_f = parse_one("#f")
  match eval(expr_t, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
  match eval(expr_f, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// cons操作のテスト。
test "builtin cons" {
  let env = initial_env()
  let expr = parse_one("(cons 1 2)")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Number(Number::Int(2)))) => ()
    _ => fail("expected pair (1 . 2)")
  }
}

/// car操作のテスト。
test "builtin car" {
  let env = initial_env()
  let expr = parse_one("(car (cons 1 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// cdr操作のテスト。
test "builtin cdr" {
  let env = initial_env()
  let expr = parse_one("(cdr (cons 1 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
}

/// リスト構築のテスト。
test "build list with cons" {
  let env = initial_env()
  let expr = parse_one("(cons 1 (cons 2 (cons 3 ())))")
  match eval(expr, env) {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected list")
  }
}

/// null?のテスト。
test "builtin null?" {
  let env = initial_env()
  let expr1 = parse_one("(null? ())")
  let expr2 = parse_one("(null? (cons 1 2))")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (null? ())")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (null? (cons 1 2))")
  }
}

/// pair?のテスト。
test "builtin pair?" {
  let env = initial_env()
  let expr1 = parse_one("(pair? (cons 1 2))")
  let expr2 = parse_one("(pair? 42)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (pair? (cons 1 2))")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (pair? 42)")
  }
}

/// number?のテスト。
test "builtin number?" {
  let env = initial_env()
  let expr1 = parse_one("(number? 42)")
  let expr2 = parse_one("(number? #t)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (number? 42)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (number? #t)")
  }
}

/// boolean?のテスト。
test "builtin boolean?" {
  let env = initial_env()
  let expr1 = parse_one("(boolean? #t)")
  let expr2 = parse_one("(boolean? 42)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (boolean? #t)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (boolean? 42)")
  }
}

/// 数値比較 = のテスト。
test "builtin =" {
  let env = initial_env()
  let expr1 = parse_one("(= 1 1)")
  let expr2 = parse_one("(= 1 2)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (= 1 1)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (= 1 2)")
  }
}

/// 数値比較 < のテスト。
test "builtin <" {
  let env = initial_env()
  let expr1 = parse_one("(< 1 2)")
  let expr2 = parse_one("(< 2 1)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (< 1 2)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (< 2 1)")
  }
}

/// 数値比較 > のテスト。
test "builtin >" {
  let env = initial_env()
  let expr1 = parse_one("(> 3 2)")
  let expr2 = parse_one("(> 2 3)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (> 3 2)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (> 2 3)")
  }
}

/// notのテスト。
test "builtin not" {
  let env = initial_env()
  let expr1 = parse_one("(not #f)")
  let expr2 = parse_one("(not #t)")
  let expr3 = parse_one("(not 42)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (not #f)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (not #t)")
  }
  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (not 42)")
  }
}

/// eq?のテスト。
test "builtin eq?" {
  let env = initial_env()
  let expr1 = parse_one("(eq? 1 1)")
  let expr2 = parse_one("(eq? 1 2)")
  let expr3 = parse_one("(eq? #t #t)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (eq? 1 1)")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (eq? 1 2)")
  }
  match eval(expr3, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (eq? #t #t)")
  }
}
