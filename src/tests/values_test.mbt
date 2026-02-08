/// Testing for values/call-with-values

/// values ​​returns a single value
test "values single value" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 42)) (lambda (x) x))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// Returning multiple values ​​values
test "values multiple values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2 3)) (lambda (a b c) (+ a (+ b c))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => () // 1 + 2 + 3
    _ => fail("expected 6")
  }
}

/// values ​​without values ​​(zero values)
test "values no values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values)) (lambda () 99))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(99))) => ()
    _ => fail("expected 99")
  }
}

/// If the producer returns a normal value
test "call-with-values with normal value producer" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () 42) (lambda (x) (* x 2)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(84))) => ()
    _ => fail("expected 84")
  }
}

/// Calculations with multiple values
test "multiple values computation" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 10 20)) (lambda (a b) (- a b)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(-10))) => ()
    _ => fail("expected -10")
  }
}

/// swap two values
test "swap two values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2)) (lambda (a b) (values b a)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::MultipleValues(vals)) => {
      if vals.length() == 2 {
        match (vals[0], vals[1]) {
          (Value::Number(Number::Int(2)), Value::Number(Number::Int(1))) => ()
          _ => fail("expected (2 1)")
        }
      } else {
        fail("expected 2 values")
      }
    }
    _ => fail("expected multiple values")
  }
}

/// Process values ​​with consumer
test "values with list construction" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2 3)) list)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _, _)) => ()
    _ => fail("expected a list")
  }
}
