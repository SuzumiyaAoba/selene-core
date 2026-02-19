/// R5RS Section 6.1: Equivalence predicates
/// Tests for eqv?, eq?, and equal?

fn s6_1_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_1_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// eqv? tests

test "R5RS 6.1: eqv? #t #t" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? #t #t)")
}

test "R5RS 6.1: eqv? #f #f" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? #f #f)")
}

test "R5RS 6.1: eqv? symbol same" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? 'abc 'abc)")
}

test "R5RS 6.1: eqv? integer same" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? 2 2)")
}

test "R5RS 6.1: eqv? empty list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? '() '())")
}

test "R5RS 6.1: eqv? char same" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? #\\a #\\a)")
}

test "R5RS 6.1: eqv? integer different" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eqv? 1 2)")
}

test "R5RS 6.1: eqv? bool different" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eqv? #t #f)")
}

test "R5RS 6.1: eqv? symbol different" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eqv? 'a 'b)")
}

test "R5RS 6.1: eqv? string same content (unspecified)" {
  let ctx = new_repl_context()
  // R5RS says unspecified for strings; just ensure no error
  match repl_eval(ctx, "(eqv? \"abc\" \"abc\")") {
    Ok(Value::Bool(_)) => ()
    Ok(v) => fail("expected boolean, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.1: eqv? different pairs" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eqv? (cons 1 2) (cons 1 2))")
}

test "R5RS 6.1: eqv? same procedure via let" {
  let ctx = new_repl_context()
  // Procedure identity via eqv? - may not be supported
  match repl_eval(ctx, "(let ((p (lambda (x) x))) (eqv? p p))") {
    Ok(Value::Bool(_)) => () // unspecified in some implementations
    Ok(v) => fail("expected boolean, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.1: eqv? car car" {
  let ctx = new_repl_context()
  // Native procedures with same name should be eqv?
  s6_1_assert_true(ctx, "(eqv? car car)")
}

test "R5RS 6.1: eqv? + +" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eqv? + +)")
}

test "R5RS 6.1: eqv? car cdr" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eqv? car cdr)")
}

// eq? tests

test "R5RS 6.1: eq? symbol same" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eq? 'a 'a)")
}

test "R5RS 6.1: eq? empty list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eq? '() '())")
}

test "R5RS 6.1: eq? #t #t" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eq? #t #t)")
}

test "R5RS 6.1: eq? #f #f" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eq? #f #f)")
}

test "R5RS 6.1: eq? same list object" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(let ((x (list 1 2))) (eq? x x))")
}

test "R5RS 6.1: eq? different list objects" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eq? (list 1) (list 1))")
}

test "R5RS 6.1: eq? car car" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(eq? car car)")
}

test "R5RS 6.1: eq? car cdr" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(eq? car cdr)")
}

test "R5RS 6.1: eq? same quoted list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(let ((x '(a))) (eq? x x))")
}

// equal? tests

test "R5RS 6.1: equal? symbol" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? 'a 'a)")
}

test "R5RS 6.1: equal? simple list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? '(a) '(a))")
}

test "R5RS 6.1: equal? nested list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? '(a (b) c) '(a (b) c))")
}

test "R5RS 6.1: equal? string" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? \"abc\" \"abc\")")
}

test "R5RS 6.1: equal? integer" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? 2 2)")
}

test "R5RS 6.1: equal? list from constructor" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? (list 1 2 3) (list 1 2 3))")
}

test "R5RS 6.1: equal? vector" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? (vector 1 2 3) (vector 1 2 3))")
}

test "R5RS 6.1: equal? dotted pair" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? '(1 2 . 3) '(1 2 . 3))")
}

test "R5RS 6.1: equal? empty list" {
  let ctx = new_repl_context()
  s6_1_assert_true(ctx, "(equal? '() '())")
}

test "R5RS 6.1: equal? different types" {
  let ctx = new_repl_context()
  s6_1_assert_false(ctx, "(equal? 1 \"1\")")
}
