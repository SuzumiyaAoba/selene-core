/// Testing the cond special form

/// Basic behavior of cond (first clause is true)
test "cond basic - first clause true" {
  let env = initial_env()
  let expr = parse_one("(cond (#t 1) (#f 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 1)
    _ => fail("Expected Int(1)")
  }
}

/// second clause is true in cond
test "cond second clause true" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#t 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// else clause of cond
test "cond else clause" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#f 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Evaluate conditional expression with cond
test "cond with evaluated test" {
  let env = initial_env()
  let expr = parse_one("(cond ((= 1 1) 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// Evaluate multiple expressions with cond
test "cond with multiple expressions in body" {
  let env = initial_env()
  let expr = parse_one("(cond (#t (+ 1 2) (* 3 4)) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("Expected Int(12)")
  }
}

/// If body is empty in cond, return value of test
test "cond returns test value when body is empty" {
  let env = initial_env()
  let expr = parse_one("(cond ((+ 1 2)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// All clauses are false in cond (no else)
test "cond all clauses false without else" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#f 2))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Determine the size of a number with cond
test "cond with numeric comparison" {
  let env = initial_env()
  let expr = parse_one("(cond ((< 5 3) 1) ((> 5 3) 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// nested cond
test "cond nested" {
  let env = initial_env()
  let expr = parse_one("(cond (#t (cond (#f 1) (else 2))) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// Using variables with cond
test "cond with variables" {
  let env = initial_env()
  let expr = parse_one("(let ((x 5)) (cond ((< x 3) 1) ((< x 7) 2) (else 3)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// Complex conditions with cond
test "cond with complex conditions" {
  let env = initial_env()
  let expr = parse_one("(cond ((and #f #t) 1) ((or #f #t) 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// Treat 0 as true with cond
test "cond treats zero as true" {
  let env = initial_env()
  let expr = parse_one("(cond (0 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// treat empty list as true with cond
test "cond treats empty list as true" {
  let env = initial_env()
  let expr = parse_one("(cond (() 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// Only #f is false in cond
test "cond only false is false" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (1 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}
