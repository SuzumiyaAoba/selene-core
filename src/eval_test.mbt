/// 評価器のテスト。

/// 数値リテラルの評価。
test "eval number literal" {
  let env = initial_env()
  let expr = SExpr::Number(42)
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("expected number")
  }
}

/// 変数参照の評価。
test "eval variable lookup" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))
  let expr = SExpr::Symbol("x")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    _ => fail("expected number")
  }
}

/// 組み込み演算子の適用。
test "eval builtin addition" {
  let env = initial_env()
  let expr = parse_one("(+ 1 2)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("expected number")
  }
}

/// lambda式の評価。
test "eval lambda" {
  let env = initial_env()
  let expr = parse_one("((lambda (x) (+ x 1)) 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("expected number")
  }
}

/// 複数パラメータのlambda。
test "eval lambda with multiple params" {
  let env = initial_env()
  let expr = parse_one("((lambda (x y) (* x y)) 3 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("expected number")
  }
}

/// begin式の評価。
test "eval begin" {
  let env = initial_env()
  let expr = parse_one("(begin (+ 1 2) (* 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("expected number")
  }
}

/// ネストしたlambda（クロージャのテスト）。
test "eval nested lambda closure" {
  let env = initial_env()
  let expr = parse_one("((lambda (x) (lambda (y) (+ x y))) 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Procedure(Procedure::Closure(_, _, _))) => ()
    _ => fail("expected closure")
  }
}

/// クロージャの変数捕捉。
test "eval closure captures environment" {
  let env = initial_env()
  // ((lambda (x) ((lambda (y) (+ x y)) 3)) 5) => 8
  let expr = parse_one("((lambda (x) ((lambda (y) (+ x y)) 3)) 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 8)
    _ => fail("expected number")
  }
}

/// quote式の評価。
test "eval quote" {
  let env = initial_env()
  let expr = parse_one("(quote (1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected pair")
  }
}
