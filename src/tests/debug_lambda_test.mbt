/// Tests for lambda passed as argument - tests tail call return handling

test "lambda: simple call" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (x) x) 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "lambda: as argument" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (f) (f 5)) (lambda (x) x))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "lambda: let with lambda" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(let ((f (lambda (x) x))) (f 5))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "lambda: nested call" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (f g) (f (g 5))) (lambda (x) x) (lambda (y) y))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "lambda: larger body prevents inlining" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (f) (+ 1 (+ 2 (+ 3 (+ 4 (+ 5 (+ 6 (+ 7 (+ 8 (+ 9 (f 10))))))))))) (lambda (x) x))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 55)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 55")
  }
}

test "lambda: boxed param prevents inlining" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (f) (set! f f) (f 5)) (lambda (x) x))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "lambda: free var prevents inlining" {
  let ctx = new_repl_context()
  let code = "(let ((y 10)) ((lambda (f) (f (+ y 0))) (lambda (x) x)))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 10")
  }
}

test "lambda: two args" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "((lambda (a b) (a b)) (lambda (x) x) 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

test "map: basic with lambda" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(equal? (map (lambda (x) (+ x 1)) '(1 2 3)) '(2 3 4))")
  match result {
    Ok(Value::Bool(b)) => assert_eq(b, true)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected #t")
  }
}

test "lambda: R5RS pitfall 4.2 - keyword shadowing with lambda arg" {
  let ctx = new_repl_context()
  // (lambda lambda lambda) creates a rest-param lambda that returns its arguments
  // (lambda (begin) (begin 1 2 3)) takes a function and calls it with 1, 2, 3
  let result = repl_eval(ctx, "(equal? ((lambda (begin) (begin 1 2 3)) (lambda lambda lambda)) '(1 2 3))")
  match result {
    Ok(Value::Bool(b)) => assert_eq(b, true)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected #t")
  }
}
