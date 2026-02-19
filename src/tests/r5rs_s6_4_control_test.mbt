/// R5RS Section 6.4: Control features
/// Tests for procedure?, apply, map, for-each, force/delay, values, call-with-values, call/cc

fn s6_4_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_4_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_4_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// procedure?

test "R5RS 6.4: procedure?" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx, "(procedure? car)")
  s6_4_assert_true(ctx, "(procedure? +)")
  s6_4_assert_true(ctx, "(procedure? (lambda (x) x))")
  s6_4_assert_false(ctx, "(procedure? 3)")
  s6_4_assert_false(ctx, "(procedure? '(1 2))")
  s6_4_assert_false(ctx, "(procedure? #t)")
}

// apply

test "R5RS 6.4: apply" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx, "(apply + '(1 2 3))", 6)
  s6_4_assert_int(ctx, "(apply + 1 2 '(3))", 6)
  s6_4_assert_true(ctx, "(equal? (apply list '(1 2 3)) '(1 2 3))")
  s6_4_assert_int(ctx, "(apply * '(2 3 4))", 24)
}

// map

test "R5RS 6.4: map basic" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx, "(equal? (map cadr '((a b) (d e) (g h))) '(b e h))")
  s6_4_assert_true(ctx, "(equal? (map (lambda (n) (* n n)) '(1 2 3 4 5)) '(1 4 9 16 25))")
}

test "R5RS 6.4: map multi-list" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx, "(equal? (map + '(1 2 3) '(4 5 6)) '(5 7 9))")
  s6_4_assert_true(ctx, "(equal? (map * '(1 2) '(3 4)) '(3 8))")
}

// for-each

test "R5RS 6.4: for-each" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx,
    "(let ((sum 0)) (for-each (lambda (x) (set! sum (+ sum x))) '(1 2 3 4 5)) (= sum 15))"
  )
}

// force / delay

test "R5RS 6.4: force delay" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx, "(force (delay (+ 1 2)))", 3)
  s6_4_assert_true(ctx,
    "(let ((p (delay (+ 1 2)))) (= (force p) (force p)))"
  )
}

test "R5RS 6.4: delay memoization" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(let ((count 0)) (let ((p (delay (begin (set! count (+ count 1)) count)))) (force p) (force p) (force p)))",
    1
  )
}

// call-with-current-continuation

test "R5RS 6.4: call/cc basic escape" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(call-with-current-continuation (lambda (exit) (for-each (lambda (x) (if (negative? x) (exit x))) '(54 0 37 -3 245 19)) #t))",
    -3
  )
}

test "R5RS 6.4: call/cc capture and invoke" {
  let ctx = new_repl_context()
  // Simplified: use call/cc to escape with a value
  s6_4_assert_int(ctx,
    "(+ 1 (call-with-current-continuation (lambda (c) (c 10))))",
    11
  )
}

// dynamic-wind

test "R5RS 6.4: dynamic-wind basic" {
  let ctx = new_repl_context()
  // dynamic-wind should call all three thunks and return body value
  s6_4_assert_int(ctx,
    "(dynamic-wind (lambda () 0) (lambda () 42) (lambda () 0))",
    42
  )
}

test "R5RS 6.4: dynamic-wind returns body value" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(dynamic-wind (lambda () #f) (lambda () 42) (lambda () #f))",
    42
  )
}

// values / call-with-values

test "R5RS 6.4: values and call-with-values" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(call-with-values (lambda () (values 1 2 3)) +)",
    6
  )
}

test "R5RS 6.4: values single" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(call-with-values (lambda () (values 42)) (lambda (x) x))",
    42
  )
}

test "R5RS 6.4: call/cc escape from loop" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(call-with-current-continuation (lambda (exit) (let loop ((i 0)) (if (= i 5) (exit i) (loop (+ i 1))))))",
    5
  )
}

test "R5RS 6.4: apply with multiple args" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx, "(equal? (apply list 1 2 '(3 4)) '(1 2 3 4))")
}

test "R5RS 6.4: map with lambda" {
  let ctx = new_repl_context()
  s6_4_assert_true(ctx,
    "(equal? (map (lambda (x) (+ x 1)) '(1 2 3)) '(2 3 4))"
  )
}

test "R5RS 6.4: for-each side effects" {
  let ctx = new_repl_context()
  s6_4_assert_int(ctx,
    "(let ((total 0)) (for-each (lambda (x) (set! total (+ total x))) '(1 2 3 4 5)) total)",
    15
  )
}
