/// Testing the evaluator.

/// Evaluation of numeric literals.
test "eval number literal" {
  let env = initial_env()
  let expr = SExpr::Number(42)
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("expected number")
  }
}

/// Evaluating variable references.
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

/// Applying built-in operators.
test "eval builtin addition" {
  let env = initial_env()
  let expr = parse_one("(+ 1 2)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("expected number")
  }
}

/// Evaluation of lambda expressions.
test "eval lambda" {
  let env = initial_env()
  let expr = parse_one("((lambda (x) (+ x 1)) 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("expected number")
  }
}

/// Multi-parameter lambda.
test "eval lambda with multiple params" {
  let env = initial_env()
  let expr = parse_one("((lambda (x y) (* x y)) 3 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("expected number")
  }
}

/// Evaluating the begin expression.
test "eval begin" {
  let env = initial_env()
  let expr = parse_one("(begin (+ 1 2) (* 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("expected number")
  }
}

/// Nested lambdas (testing closures).
test "eval nested lambda closure" {
  let env = initial_env()
  let expr = parse_one("((lambda (x) (lambda (y) (+ x y))) 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Procedure(Procedure::Closure(_, _, _))) => ()
    _ => fail("expected closure")
  }
}

/// Closure variable capture.
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

/// Evaluation of quote expression.
test "eval quote" {
  let env = initial_env()
  let expr = parse_one("(quote (1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected pair")
  }
}
