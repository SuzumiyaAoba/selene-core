/// Tests for macro system integration with bytecode compiler

test "define-syntax basic" {
  let ctx = new_repl_context()

  // Define a simple macro
  match repl_eval(ctx, "(define-syntax my-when (syntax-rules () ((_ test body) (if test body #f))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax failed: " + e)
  }

  // Use the macro
  match repl_eval(ctx, "(my-when #t 42)") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }

  // Test with false condition
  match repl_eval(ctx, "(my-when #f 42)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }
}

test "define-syntax with ellipsis" {
  let ctx = new_repl_context()

  // Define a macro with ellipsis
  match repl_eval(ctx, "(define-syntax my-begin (syntax-rules () ((_ e) e) ((_ e1 e2 ...) (let ((x e1)) (my-begin e2 ...)))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax failed: " + e)
  }

  // Use the macro
  match repl_eval(ctx, "(my-begin 1 2 3)") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }
}

test "let-syntax scoped macro" {
  let ctx = new_repl_context()

  // let-syntax creates a scoped macro
  match repl_eval(ctx, "(let-syntax ((double (syntax-rules () ((_ x) (+ x x))))) (double 5))") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("let-syntax failed: " + e)
  }
}

test "macro nested expansion" {
  let ctx = new_repl_context()

  // Define my-or macro
  match repl_eval(ctx, "(define-syntax my-or (syntax-rules () ((_ a b) (if a a b))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax failed: " + e)
  }

  // Nested use of the macro
  match repl_eval(ctx, "(my-or #f (my-or #f 42))") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("nested macro expansion failed: " + e)
  }
}

test "macro with literals" {
  let ctx = new_repl_context()

  // Define a macro with literal keywords
  match repl_eval(ctx, "(define-syntax my-cond (syntax-rules (else) ((_ (else e)) e) ((_ (test e)) (if test e #f))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax failed: " + e)
  }

  // Test with else
  match repl_eval(ctx, "(my-cond (else 99))") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 99)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }

  // Test with condition
  match repl_eval(ctx, "(my-cond (#t 42))") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }
}

test "define-syntax persists across evaluations" {
  let ctx = new_repl_context()

  // Define first macro
  match repl_eval(ctx, "(define-syntax m1 (syntax-rules () ((_ x) (+ x 1))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax m1 failed: " + e)
  }

  // Define second macro
  match repl_eval(ctx, "(define-syntax m2 (syntax-rules () ((_ x) (* x 2))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax m2 failed: " + e)
  }

  // Both macros should work
  match repl_eval(ctx, "(m1 (m2 5))") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 11) // (* 5 2) = 10, (+ 10 1) = 11
    Ok(v) => fail("unexpected value: " + v.to_string())
    Err(e) => fail("macro expansion failed: " + e)
  }
}
