/// Extended control flow tests: values, call-with-values, dynamic-wind, apply, eval.

/// Helper: assert expression evaluates to #t
fn ctrl_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "values single" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(call-with-values (lambda () (values 1)) (lambda (x) x))") {
    Ok(Value::Number(Number::Int(1))) => ()
    Ok(v) => fail("expected 1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "values multiple" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(call-with-values (lambda () (values 1 2 3)) (lambda (a b c) (+ a b c)))") {
    Ok(Value::Number(Number::Int(6))) => ()
    Ok(v) => fail("expected 6, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "dynamic-wind basic ordering" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define log '())")
  let _ = repl_eval(ctx, "(dynamic-wind (lambda () (set! log (cons 'in log))) (lambda () (set! log (cons 'body log))) (lambda () (set! log (cons 'out log))))")
  ctrl_assert_true(ctx, "(equal? (reverse log) '(in body out))")
}

test "apply basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(apply + '(1 2 3))") {
    Ok(Value::Number(Number::Int(6))) => ()
    Ok(v) => fail("expected 6, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "apply with extra args" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(apply + 1 2 '(3 4))") {
    Ok(Value::Number(Number::Int(10))) => ()
    Ok(v) => fail("expected 10, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "apply with lambda" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(apply (lambda (x y) (* x y)) '(3 4))") {
    Ok(Value::Number(Number::Int(12))) => ()
    Ok(v) => fail("expected 12, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "for-each basic" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define result '())")
  let _ = repl_eval(ctx, "(for-each (lambda (x) (set! result (cons (* x x) result))) '(1 2 3))")
  ctrl_assert_true(ctx, "(equal? (reverse result) '(1 4 9))")
}

test "map basic" {
  let ctx = new_repl_context()
  ctrl_assert_true(ctx, "(equal? (map (lambda (x) (* x x)) '(1 2 3 4)) '(1 4 9 16))")
}

test "filter basic" {
  let ctx = new_repl_context()
  ctrl_assert_true(ctx, "(equal? (filter (lambda (x) (> x 2)) '(1 2 3 4 5)) '(3 4 5))")
}

test "fold-left sum" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(fold-left + 0 '(1 2 3 4 5))") {
    Ok(Value::Number(Number::Int(15))) => ()
    Ok(v) => fail("expected 15, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "fold-right cons" {
  let ctx = new_repl_context()
  ctrl_assert_true(ctx, "(equal? (fold-right cons '() '(1 2 3)) '(1 2 3))")
}

test "boolean? predicate" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(boolean? #t)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(boolean? 42)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "procedure? predicate" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(procedure? car)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(procedure? 42)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "symbol->string and string->symbol roundtrip" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol->string 'hello)") {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    Ok(v) => fail("expected \"hello\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(string->symbol \"world\")") {
    Ok(Value::Symbol(s)) => assert_eq(s, "world")
    Ok(v) => fail("expected symbol world, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "list? predicate" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(list? '(1 2 3))") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(list? (cons 1 2))") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
