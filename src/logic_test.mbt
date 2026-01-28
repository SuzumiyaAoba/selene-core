/// Test of logical operations.

/// Basic test for not function.
test "builtin not" {
  let env = initial_env()
  let expr1 = parse_one("(not #t)")
  let expr2 = parse_one("(not #f)")
  let expr3 = parse_one("(not 3)")
  let expr4 = parse_one("(not ())")

  match eval(expr1, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (not #t)")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (not #f)")
  }

  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (not 3)")
  }

  match eval(expr4, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (not ())")
  }
}

/// and special form basic tests.
test "and basic" {
  let env = initial_env()
  let expr1 = parse_one("(and)")
  let expr2 = parse_one("(and #t)")
  let expr3 = parse_one("(and #f)")
  let expr4 = parse_one("(and #t #t)")
  let expr5 = parse_one("(and #t #f)")
  let expr6 = parse_one("(and #f #t)")

  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and)")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and #t)")
  }

  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (and #f)")
  }

  match eval(expr4, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and #t #t)")
  }

  match eval(expr5, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (and #t #f)")
  }

  match eval(expr6, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (and #f #t)")
  }
}

/// Return value test for and (returns the last value).
test "and returns last value" {
  let env = initial_env()
  let expr1 = parse_one("(and 1 2 3)")
  let expr2 = parse_one("(and (= 2 2) (> 2 1))")

  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3 for (and 1 2 3)")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and (= 2 2) (> 2 1))")
  }
}

/// Short circuit evaluation test of and.
test "and short circuit" {
  let env = initial_env()
  // The expression after #f should not be evaluated (no error will occur)
  let expr = SExpr::Pair(
    SExpr::Symbol("and"),
    SExpr::Pair(
      SExpr::Bool(false),
      SExpr::Pair(
        // This part is not evaluated, so unbound variables will not cause an error.
        SExpr::Symbol("undefined-var"),
        SExpr::Nil
      )
    )
  )

  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("and should short-circuit on #f")
  }
}

/// or special format basic tests.
test "or basic" {
  let env = initial_env()
  let expr1 = parse_one("(or)")
  let expr2 = parse_one("(or #t)")
  let expr3 = parse_one("(or #f)")
  let expr4 = parse_one("(or #f #f)")
  let expr5 = parse_one("(or #t #f)")
  let expr6 = parse_one("(or #f #t)")

  match eval(expr1, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (or)")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or #t)")
  }

  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (or #f)")
  }

  match eval(expr4, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for (or #f #f)")
  }

  match eval(expr5, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or #t #f)")
  }

  match eval(expr6, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or #f #t)")
  }
}

/// Return value test for or (returns the first true value).
test "or returns first true value" {
  let env = initial_env()
  let expr1 = parse_one("(or #f 2 3)")
  let expr2 = parse_one("(or (= 2 2) (> 2 1))")

  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2 for (or #f 2 3)")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or (= 2 2) (> 2 1))")
  }
}

/// Short circuit evaluation test of or.
test "or short circuit" {
  let env = initial_env()
  // The expression after the true value should not be evaluated (no error will occur)
  let expr = SExpr::Pair(
    SExpr::Symbol("or"),
    SExpr::Pair(
      SExpr::Number(1),
      SExpr::Pair(
        // This part is not evaluated, so unbound variables will not cause an error.
        SExpr::Symbol("undefined-var"),
        SExpr::Nil
      )
    )
  )

  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("or should short-circuit on true value")
  }
}

/// Combination test for and and or.
test "and or combination" {
  let env = initial_env()
  let expr1 = parse_one("(and (or #f #t) (or #t #f))")
  let expr2 = parse_one("(or (and #f #t) (and #t #t))")
  let expr3 = parse_one("(not (and #t #f))")
  let expr4 = parse_one("(not (or #f #f))")

  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and (or #f #t) (or #t #f))")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or (and #f #t) (and #t #t))")
  }

  match eval(expr3, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (not (and #t #f))")
  }

  match eval(expr4, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (not (or #f #f))")
  }
}

/// Testing complex logical expressions.
test "complex logic expressions" {
  let env = initial_env()
  let expr1 = parse_one("(and (> 5 3) (< 2 4) (= 1 1))")
  let expr2 = parse_one("(or (> 1 5) (< 2 1) (= 2 2))")
  let expr3 = parse_one("(and (not #f) (not (= 1 2)))")

  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and (> 5 3) (< 2 4) (= 1 1))")
  }

  match eval(expr2, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (or (> 1 5) (< 2 1) (= 2 2))")
  }

  match eval(expr3, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for (and (not #f) (not (= 1 2)))")
  }
}
