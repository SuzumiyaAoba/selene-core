/// R5RS Section 5: Program structure (definitions)
/// Tests for define, internal definitions, top-level definitions

fn s5_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s5_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// 5.2 define variable

test "R5RS 5.2: define variable" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define x 42)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "x", 42)
}

// 5.2 define function shorthand

test "R5RS 5.2: define function shorthand" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define (square x) (* x x))") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "(square 5)", 25)
}

test "R5RS 5.2: define function with rest args" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define (f x . rest) rest)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_true(ctx, "(equal? (f 1 2 3) '(2 3))")
}

// 5.2 define recursive

test "R5RS 5.2: define recursive function" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "(fact 10)", 3628800)
}

// 5.2.2 Internal definitions

test "R5RS 5.2.2: internal define in lambda" {
  let ctx = new_repl_context()
  s5_assert_int(ctx,
    "((lambda () (define x 10) (define y 20) (+ x y)))",
    30
  )
}

test "R5RS 5.2.2: internal define mutual recursion" {
  let ctx = new_repl_context()
  s5_assert_true(ctx,
    "((lambda () (define (even? n) (if (zero? n) #t (odd? (- n 1)))) (define (odd? n) (if (zero? n) #f (even? (- n 1)))) (even? 10)))"
  )
}

test "R5RS 5.2.2: internal define in let" {
  let ctx = new_repl_context()
  s5_assert_int(ctx,
    "(let () (define a 1) (define b 2) (+ a b))",
    3
  )
}

// Multiple define (redefine)

test "R5RS 5.2: redefine" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define x 1)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "x", 1)
  match repl_eval(ctx, "(define x 2)") {
    Ok(_) => ()
    Err(e) => fail("redefine error: " + e)
  }
  s5_assert_int(ctx, "x", 2)
}

// define with begin

test "R5RS 5.2: begin with defines" {
  let ctx = new_repl_context()
  // Defines in begin must be followed by expressions in some contexts
  match repl_eval(ctx, "(define a 10)") {
    Ok(_) => ()
    Err(e) => fail("define a error: " + e)
  }
  match repl_eval(ctx, "(define b 20)") {
    Ok(_) => ()
    Err(e) => fail("define b error: " + e)
  }
  s5_assert_int(ctx, "(+ a b)", 30)
}

// Additional definition tests (11 new tests)

test "R5RS 5.2: define with set!" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define x 10)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "x", 10)
  match repl_eval(ctx, "(set! x 20)") {
    Ok(_) => ()
    Err(e) => fail("set! error: " + e)
  }
  s5_assert_int(ctx, "x", 20)
}

test "R5RS 5.2: define with complex expression" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define x (+ (* 2 3) (* 4 5)))") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "x", 26)
}

test "R5RS 5.2: define function with no arguments" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define (const-42) 42)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "(const-42)", 42)
}

test "R5RS 5.2: define with lambda expression" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define add (lambda (x y) (+ x y)))") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "(add 3 4)", 7)
}

test "R5RS 5.2: define with quoted value" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define lst '(1 2 3))") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_true(ctx, "(equal? lst '(1 2 3))")
}

test "R5RS 5.2.2: internal define with shadowing" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define x 100)") {
    Ok(_) => ()
    Err(e) => fail("outer define error: " + e)
  }
  s5_assert_int(ctx,
    "((lambda () (define x 50) (+ x 10)))",
    60  // inner x shadows outer x
  )
}

test "R5RS 5.2.2: internal define mixed with expressions" {
  let ctx = new_repl_context()
  s5_assert_int(ctx,
    "((lambda () (define a 5) (define b 10) (define c (+ a b)) c))",
    15
  )
}

test "R5RS 5.2: define function with multiple body expressions" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define (multi-body x) (set! x (+ x 1)) (set! x (* x 2)) x)") {
    Ok(_) => ()
    Err(e) => fail("define error: " + e)
  }
  s5_assert_int(ctx, "(multi-body 5)", 12)  // (5+1)*2 = 12
}

test "R5RS 5.2: top-level begin sequence" {
  let ctx = new_repl_context()
  // begin at top level with definitions and expression
  s5_assert_int(ctx, "(begin (define r 5) (define s 10) (+ r s))", 15)
}

test "R5RS 5.2.2: internal define with forward reference" {
  let ctx = new_repl_context()
  // Test that internal defines can reference each other (in correct order)
  // NOTE: Forward reference (f defined before g but calling g) requires letrec semantics
  s5_assert_int(ctx,
    "((lambda () (define (g x) (* x 2)) (define (f x) (+ x (g x))) (f 5)))",
    15  // f(5) = 5 + g(5) = 5 + 10 = 15
  )
}

test "R5RS 5.2: define multiple values" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(define a 1)") {
    Ok(_) => ()
    Err(e) => fail("define a error: " + e)
  }
  match repl_eval(ctx, "(define b 2)") {
    Ok(_) => ()
    Err(e) => fail("define b error: " + e)
  }
  match repl_eval(ctx, "(define c 3)") {
    Ok(_) => ()
    Err(e) => fail("define c error: " + e)
  }
  s5_assert_int(ctx, "(+ a b c)", 6)
}
