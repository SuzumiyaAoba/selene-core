/// Testing delayed evaluation (delay/force)

/// Basic delay and force
test "delay and force basic" {
  let env = initial_env()
  let expr = parse_one("(force (delay (+ 1 2)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
}

/// promise? predicate
test "promise? predicate" {
  let env = initial_env()
  let expr = parse_one("(promise? (delay 42))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// promise for non-promise?
test "promise? with non-promise" {
  let env = initial_env()
  let expr = parse_one("(promise? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// Delayed promises are not evaluated until forced
test "delay is lazy" {
  let env = initial_env()
  // Create a promise but don't force it
  let expr = parse_one("(let ((p (delay (/ 1 0)))) #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t (no error because delay is lazy)")
  }
}

/// Same result even if force is called twice (memoization)
test "force memoization" {
  let env = initial_env()
  let expr = parse_one("(let ((p (delay (+ 10 20)))) (+ (force p) (force p)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(60))) => () // 30 + 30
    _ => fail("expected 60")
  }
}

/// If you force a value other than a promise, it will be returned as is.
test "force non-promise" {
  let env = initial_env()
  let expr = parse_one("(force 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// nested delays
test "nested delay" {
  let env = initial_env()
  let expr = parse_one("(force (force (delay (delay 100))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail("expected 100")
  }
}

/// Reference variable with delay
test "delay with variable reference" {
  let env = initial_env()
  let expr = parse_one("(let ((x 10)) (force (delay x)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail("expected 10")
  }
}
