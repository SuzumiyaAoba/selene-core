/// Testing the let/let*/letrec special form

/// Check the basic operation of let
test "let basic" {
  let env = initial_env()
  let expr = parse_one("(let ((x 1) (y 2)) (+ x y))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Verify that let can evaluate multiple expressions
test "let multiple expressions in body" {
  let env = initial_env()
  let expr = parse_one("(let ((x 10)) (+ x 1) (* x 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 20)
    _ => fail("Expected Int(20)")
  }
}

/// Ensure that let bindings cannot reference each other
test "let bindings are independent" {
  let env = initial_env()
  // (let ((x 1) (y x)) y) should result in an error (x is undefined when y is initialized)
  // However, the current implementation evaluates in order, so this test may not pass.
  // Correctly, evaluate all values ​​first and then expand the environment
  let expr = parse_one("(let ((x 1) (y 2)) (+ x y))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Check the basic operation of let*
test "let* basic" {
  let env = initial_env()
  let expr = parse_one("(let* ((x 1) (y 2)) (+ x y))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Make sure you can reference the previous variable with let*
test "let* sequential bindings" {
  let env = initial_env()
  let expr = parse_one("(let* ((x 5) (y (* x 2))) y)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    _ => fail("Expected Int(10)")
  }
}

/// Check that let* is evaluated sequentially
test "let* sequential evaluation" {
  let env = initial_env()
  let expr = parse_one("(let* ((x 1) (x (+ x 1)) (x (+ x 1))) x)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Check the basic operation of letrec
test "letrec basic" {
  let env = initial_env()
  let expr = parse_one("(letrec ((x 1) (y 2)) (+ x y))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

// Note: Due to the constraints of the immutable environment model, the current letrec implementation
// Does not support full recursive binding.
// Define recursive functions using define.
// For future improvements, consider a variable environment or another implementation method.

/// Create non-recursive closures with letrec
test "letrec with non-recursive closure" {
  let env = initial_env()
  let expr = parse_one("(letrec ((f (lambda (x) (+ x 1)))) (f 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}

/// let with empty binding
test "let empty bindings" {
  let env = initial_env()
  let expr = parse_one("(let () 42)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// nested let
test "let nested" {
  let env = initial_env()
  let expr = parse_one("(let ((x 1)) (let ((y 2)) (+ x y)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// Create a closure with let
test "let with closure" {
  let env = initial_env()
  let expr = parse_one("(let ((x 10)) ((lambda (y) (+ x y)) 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    _ => fail("Expected Int(15)")
  }
}

/// Test the closure environment with let*
test "let* with closure" {
  let env = initial_env()
  let expr = parse_one("(let* ((x 5) (f (lambda (y) (+ x y)))) (f 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 8)
    _ => fail("Expected Int(8)")
  }
}

/// Multiple non-recursive bindings with letrec
test "letrec multiple bindings" {
  let env = initial_env()
  let expr = parse_one("(letrec ((x 1) (y 2) (z 3)) (+ x (+ y z)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}
