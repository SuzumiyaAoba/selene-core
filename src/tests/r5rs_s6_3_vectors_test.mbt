/// R5RS Section 6.3.6: Vectors
/// Tests for vector operations

fn s6_3_6_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_3_6_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_3_6_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "R5RS 6.3.6: vector?" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(vector? (vector 1 2 3))")
  s6_3_6_assert_true(ctx, "(vector? (make-vector 3))")
  s6_3_6_assert_false(ctx, "(vector? '(1 2 3))")
  s6_3_6_assert_false(ctx, "(vector? 42)")
}

test "R5RS 6.3.6: make-vector" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (make-vector 5))", 5)
  s6_3_6_assert_true(ctx, "(equal? (make-vector 3 0) (vector 0 0 0))")
}

test "R5RS 6.3.6: vector" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector 'a 'b 'c) (vector 'a 'b 'c))")
  s6_3_6_assert_int(ctx, "(vector-length (vector))", 0)
}

test "R5RS 6.3.6: vector-length" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (vector 1 2 3))", 3)
  s6_3_6_assert_int(ctx, "(vector-length (vector))", 0)
  s6_3_6_assert_int(ctx, "(vector-length (make-vector 10))", 10)
}

test "R5RS 6.3.6: vector-ref" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-ref (vector 10 20 30) 0)", 10)
  s6_3_6_assert_int(ctx, "(vector-ref (vector 10 20 30) 1)", 20)
  s6_3_6_assert_int(ctx, "(vector-ref (vector 10 20 30) 2)", 30)
}

test "R5RS 6.3.6: vector-set!" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(let ((v (vector 1 2 3))) (vector-set! v 1 99) (equal? v (vector 1 99 3)))"
  )
}

test "R5RS 6.3.6: vector->list" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector->list (vector 1 2 3)) '(1 2 3))")
  s6_3_6_assert_true(ctx, "(equal? (vector->list (vector)) '())")
}

test "R5RS 6.3.6: list->vector" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (list->vector '(1 2 3)) (vector 1 2 3))")
  s6_3_6_assert_true(ctx, "(equal? (list->vector '()) (vector))")
}

test "R5RS 6.3.6: vector-fill!" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(let ((v (vector 1 2 3))) (vector-fill! v 0) (equal? v (vector 0 0 0)))"
  )
}

test "R5RS 6.3.6: vector roundtrip" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(equal? (vector->list (list->vector '(a b c))) '(a b c))"
  )
}

// Additional vector tests (15 new tests)

test "R5RS 6.3.6: vector with mixed types" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector 1 'a \"hello\" #t) (vector 1 'a \"hello\" #t))")
  s6_3_6_assert_true(ctx, "(vector? (vector 1 'a \"hello\" #t))")
}

test "R5RS 6.3.6: empty vector" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (vector))", 0)
  s6_3_6_assert_true(ctx, "(equal? (vector) (make-vector 0))")
}

test "R5RS 6.3.6: vector-set! multiple" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(let ((v (vector 1 2 3 4 5))) (vector-set! v 0 10) (vector-set! v 4 50) (equal? v (vector 10 2 3 4 50)))"
  )
}

test "R5RS 6.3.6: vector-set! same index" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(let ((v (vector 1 2 3))) (vector-set! v 1 20) (vector-set! v 1 99) (equal? v (vector 1 99 3)))"
  )
}

test "R5RS 6.3.6: make-vector with fill" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (make-vector 4 'x) (vector 'x 'x 'x 'x))")
  s6_3_6_assert_true(ctx, "(equal? (make-vector 2 \"hi\") (vector \"hi\" \"hi\"))")
}

test "R5RS 6.3.6: vector-ref bounds" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-ref (vector 10 20 30) 0)", 10)
  s6_3_6_assert_int(ctx, "(vector-ref (vector 10 20 30) 2)", 30)
}

test "R5RS 6.3.6: vector-fill! with symbol" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx,
    "(let ((v (vector 1 2 3))) (vector-fill! v 'filled) (equal? v (vector 'filled 'filled 'filled)))"
  )
}

test "R5RS 6.3.6: vector->list empty" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector->list (vector)) '())")
}

test "R5RS 6.3.6: list->vector empty" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (list->vector '()) (vector))")
}

test "R5RS 6.3.6: vector with nested lists" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector '(1 2) '(3 4)) (vector '(1 2) '(3 4)))")
}

test "R5RS 6.3.6: vector equality" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector 1 2 3) (vector 1 2 3))")
  s6_3_6_assert_false(ctx, "(equal? (vector 1 2 3) (vector 1 2 4))")
}

test "R5RS 6.3.6: vector single element" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (vector 'only))", 1)
  s6_3_6_assert_true(ctx, "(equal? (vector-ref (vector 'only) 0) 'only)")
}

test "R5RS 6.3.6: make-vector zero length" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (make-vector 0))", 0)
}

test "R5RS 6.3.6: vector large size" {
  let ctx = new_repl_context()
  s6_3_6_assert_int(ctx, "(vector-length (make-vector 100))", 100)
  s6_3_6_assert_true(ctx, "(equal? (make-vector 100 0) (make-vector 100 0))")
}

test "R5RS 6.3.6: vector with booleans" {
  let ctx = new_repl_context()
  s6_3_6_assert_true(ctx, "(equal? (vector #t #f #t) (vector #t #f #t))")
  s6_3_6_assert_true(ctx, "(vector-ref (vector #t #f) 0)")
  s6_3_6_assert_false(ctx, "(vector-ref (vector #t #f) 1)")
}
