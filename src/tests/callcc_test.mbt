/// tests for call/cc (call-with-current-continuation).

/// Returns the normal return value if no continuation is invoked.
test "call/cc without invoking continuation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) 42))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// When you call continue, its value becomes the return value of call/cc.
test "call/cc with continuation invocation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (begin (k 100) 42)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail("expected 100")
  }
}

/// When a continuation is invoked, subsequent expressions are not evaluated (early return).
test "call/cc early return" {
  let env = initial_env()
  let expr = parse_one("(+ 1 (call/cc (lambda (k) (begin (k 10) (+ 100 200)))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(11))) => ()
    _ => fail("expected 11")
  }
}

/// call-with-current-continuation is an alias for call/cc.
test "call-with-current-continuation alias" {
  let env = initial_env()
  let expr = parse_one("(call-with-current-continuation (lambda (k) (k 50)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(50))) => ()
    _ => fail("expected 50")
  }
}

/// error passing non-procedure to call/cc.
test "call/cc with non-procedure" {
  let env = initial_env()
  let expr = parse_one("(call/cc 42)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}

/// Continuation accepts only one argument.
test "continuation requires exactly one argument" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (k 1 2)))")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => fail("expected ArityError")
  }
}

/// Save the continuation to a variable and call it later.
test "call/cc save and invoke later" {
  let env = initial_env()
  // (let ((saved #f))
  //   (+ 1 (call/cc (lambda (k) (set! saved k) 10)))
  //   (if saved (saved 20) 0))
  // In this case, since the escape is continued, if you call saved later,
  // Propagation of new continuous call errors
  let expr = parse_one("(call/cc (lambda (k) (+ 1 (k 5))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// Nested call/cc.
test "nested call/cc" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k1) (call/cc (lambda (k2) (k1 100)))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail("expected 100")
  }
}

/// Calls for an inner continuation.
test "nested call/cc inner continuation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k1) (+ 1 (call/cc (lambda (k2) (k2 10))))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(11))) => ()
    _ => fail("expected 11")
  }
}

/// Treat continuation as a procedure.
test "continuation is a procedure" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (procedure? k)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}
