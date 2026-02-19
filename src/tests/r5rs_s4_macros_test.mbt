/// R5RS Section 4.3: Macros (define-syntax, syntax-rules)

fn s4_3_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s4_3_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "R5RS 4.3: define-syntax simple" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define-syntax my-if (syntax-rules () ((my-if c t f) (cond (c t) (else f)))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax error: " + e)
  }
  s4_3_assert_int(ctx, "(my-if #t 1 2)", 1)
  s4_3_assert_int(ctx, "(my-if #f 1 2)", 2)
}

test "R5RS 4.3: define-syntax swap!" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define-syntax swap! (syntax-rules () ((swap! a b) (let ((tmp a)) (set! a b) (set! b tmp)))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax error: " + e)
  }
  s4_3_assert_int(ctx, "(let ((x 1) (y 2)) (swap! x y) x)", 2)
  s4_3_assert_int(ctx, "(let ((x 1) (y 2)) (swap! x y) y)", 1)
}

test "R5RS 4.3: define-syntax with ellipsis" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define-syntax my-list (syntax-rules () ((my-list x ...) (list x ...))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax error: " + e)
  }
  s4_3_assert_true(ctx, "(equal? (my-list 1 2 3) '(1 2 3))")
  s4_3_assert_true(ctx, "(equal? (my-list) '())")
}

test "R5RS 4.3: define-syntax multiple patterns" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define-syntax my-and (syntax-rules () ((my-and) #t) ((my-and x) x) ((my-and x y ...) (if x (my-and y ...) #f))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax error: " + e)
  }
  s4_3_assert_true(ctx, "(my-and)")
  s4_3_assert_true(ctx, "(my-and #t #t)")
  s4_3_assert_true(ctx, "(not (my-and #t #f))")
  s4_3_assert_int(ctx, "(my-and 1 2 3)", 3)
}

test "R5RS 4.3: let-syntax" {
  let ctx = new_repl_context()
  s4_3_assert_int(ctx,
    "(let-syntax ((double (syntax-rules () ((double x) (+ x x))))) (double 5))",
    10
  )
}

test "R5RS 4.3: letrec-syntax" {
  let ctx = new_repl_context()
  s4_3_assert_true(ctx,
    "(letrec-syntax ((my-or (syntax-rules () ((my-or) #f) ((my-or e1 e2 ...) (let ((t e1)) (if t t (my-or e2 ...))))))) (my-or #f #f #t))"
  )
}

test "R5RS 4.3: hygiene" {
  let ctx = new_repl_context()
  // The macro should not capture the user's variable
  match repl_eval(ctx, "(define-syntax my-let1 (syntax-rules () ((my-let1 v e body) (let ((v e)) body))))") {
    Ok(_) => ()
    Err(e) => fail("define-syntax error: " + e)
  }
  s4_3_assert_int(ctx, "(my-let1 x 10 (+ x 1))", 11)
}
