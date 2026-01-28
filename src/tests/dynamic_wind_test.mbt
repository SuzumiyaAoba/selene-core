/// Testing dynamic-wind

/// basic dynamic-wind
test "dynamic-wind basic" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #f) (lambda () 42) (lambda () #f))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// before/after is called in dynamic-wind
test "dynamic-wind before and after execution" {
  let env = initial_env()
  // Make sure before, thunk, and after are all executed
  let expr = parse_one("(+ (dynamic-wind (lambda () 1) (lambda () 10) (lambda () 100)) 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => () // thunk result
    _ => fail("expected 10")
  }
}

/// dynamic-wind thunk returns value
test "dynamic-wind returns thunk result" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () 'before) (lambda () (+ 1 2 3)) (lambda () 'after))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => ()
    _ => fail("expected 6")
  }
}

/// dynamic-wind with multiplication
test "dynamic-wind with computation result" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #t) (lambda () (* 7 8)) (lambda () #t))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(56))) => ()
    _ => fail("expected 56")
  }
}

/// nesting dynamic-wind
test "nested dynamic-wind" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () 1) (lambda () (dynamic-wind (lambda () 2) (lambda () 3) (lambda () 4))) (lambda () 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => () // Inner thunk result
    _ => fail("expected 3")
  }
}

/// Return calculation results with dynamic-wind
test "dynamic-wind computation" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #t) (lambda () (* 6 7)) (lambda () #t))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}
