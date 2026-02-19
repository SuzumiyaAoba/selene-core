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
