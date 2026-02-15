/// Extended list function tests: assq, assv, assoc, memq, memv, member, set-car!, set-cdr!

/// Helper: assert expression evaluates to #t
fn list_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

/// Helper: assert expression evaluates to #f
fn list_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "assq found" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (assq 'b '((a 1) (b 2) (c 3))) '(b 2))")
}

test "assq not found" {
  let ctx = new_repl_context()
  list_assert_false(ctx, "(assq 'd '((a 1) (b 2) (c 3)))")
}

test "assq empty list" {
  let ctx = new_repl_context()
  list_assert_false(ctx, "(assq 'a '())")
}

test "assoc with equal?" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (assoc '(1 2) '(((1 2) found) ((3 4) other))) '((1 2) found))")
}

test "assv with number" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (assv 2 '((1 a) (2 b) (3 c))) '(2 b))")
}

test "memq found" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (memq 'b '(a b c)) '(b c))")
}

test "memq not found" {
  let ctx = new_repl_context()
  list_assert_false(ctx, "(memq 'd '(a b c))")
}

test "memv with number" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (memv 2 '(1 2 3)) '(2 3))")
}

test "member with equal?" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (member '(2) '((1) (2) (3))) '((2) (3)))")
}

test "set-car! returns new pair" {
  let ctx = new_repl_context()
  // Current implementation: set-car! returns a new pair (immutable Pair model)
  list_assert_true(ctx, "(equal? (set-car! (cons 1 2) 10) '(10 . 2))")
}

test "set-cdr! returns new pair" {
  let ctx = new_repl_context()
  // Current implementation: set-cdr! returns a new pair (immutable Pair model)
  list_assert_true(ctx, "(equal? (set-cdr! (cons 1 2) 20) '(1 . 20))")
}

test "reverse basic" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (reverse '(1 2 3)) '(3 2 1))")
}

test "reverse empty" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(null? (reverse '()))")
}

test "append multiple" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (append '(1 2) '(3 4) '(5)) '(1 2 3 4 5))")
}

test "append empty lists" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (append '() '() '(1)) '(1))")
}

test "list-tail" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (list-tail '(a b c d) 2) '(c d))")
}

test "list-tail zero" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(equal? (list-tail '(a b c) 0) '(a b c))")
}

test "list-ref" {
  let ctx = new_repl_context()
  list_assert_true(ctx, "(eq? (list-ref '(a b c d) 2) 'c)")
}
