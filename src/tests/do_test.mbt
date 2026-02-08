/// Testing the do loop

/// Basic do loop (count up)
test "do loop basic counting" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((= i 5) i))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// Build a list with a do loop
test "do loop building list" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1)) (lst () (cons i lst))) ((= i 3) lst))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _, _)) => ()
    _ => fail("expected a list")
  }
}

/// No end condition expression for do loop (returns Nil)
test "do loop no result expression" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((= i 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail("expected Nil")
  }
}

/// Execute commands in a do loop
test "do loop with commands" {
  let env = initial_env()
  // Execute the command but do not affect the result
  let expr = parse_one("(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 4) sum) (+ 1 1))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => () // 0+1+2+3=6
    _ => fail("expected 6")
  }
}

/// do loop initialization only (no step expression)
test "do loop without step" {
  let env = initial_env()
  let expr = parse_one("(do ((x 10)) (#t x))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail("expected 10")
  }
}

/// Using multiple variables in do loops
test "do loop multiple variables" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => () // 0+1+2+3+4=10
    _ => fail("expected 10")
  }
}

/// Early termination with do loop
test "do loop early exit" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((> i 3) i))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("expected 4")
  }
}
