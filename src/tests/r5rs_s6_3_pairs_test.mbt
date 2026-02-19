/// R5RS Section 6.3.2: Pairs and lists
/// Tests for cons, car, cdr, list, append, reverse, etc.

fn s6_3_2_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_3_2_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_3_2_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// pair? null? list?

test "R5RS 6.3.2: pair?" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(pair? '(a . b))")
  s6_3_2_assert_true(ctx, "(pair? '(a b c))")
  s6_3_2_assert_false(ctx, "(pair? '())")
  s6_3_2_assert_false(ctx, "(pair? 1)")
  s6_3_2_assert_false(ctx, "(pair? \"hello\")")
}

test "R5RS 6.3.2: null?" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(null? '())")
  s6_3_2_assert_false(ctx, "(null? '(1))")
  s6_3_2_assert_false(ctx, "(null? 0)")
  s6_3_2_assert_false(ctx, "(null? #f)")
}

test "R5RS 6.3.2: list?" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(list? '(a b c))")
  s6_3_2_assert_true(ctx, "(list? '())")
  s6_3_2_assert_false(ctx, "(list? '(a . b))")
}

// cons, car, cdr

test "R5RS 6.3.2: cons" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cons 'a '()) '(a))")
  s6_3_2_assert_true(ctx, "(equal? (cons '(a) '(b c d)) '((a) b c d))")
  s6_3_2_assert_true(ctx, "(equal? (cons \"a\" '(b c)) '(\"a\" b c))")
  s6_3_2_assert_true(ctx, "(equal? (cons 'a 3) '(a . 3))")
  s6_3_2_assert_true(ctx, "(equal? (cons '(a b) 'c) '((a b) . c))")
}

test "R5RS 6.3.2: car" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (car '(a b c)) 'a)")
  s6_3_2_assert_true(ctx, "(equal? (car '((a) b c d)) '(a))")
  s6_3_2_assert_int(ctx, "(car '(1 . 2))", 1)
}

test "R5RS 6.3.2: cdr" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cdr '((a) b c d)) '(b c d))")
  s6_3_2_assert_int(ctx, "(cdr '(1 . 2))", 2)
}

// list, length

test "R5RS 6.3.2: list" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list 'a (+ 3 4) 'c) '(a 7 c))")
  s6_3_2_assert_true(ctx, "(equal? (list) '())")
}

test "R5RS 6.3.2: length" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(length '(a b c))", 3)
  s6_3_2_assert_int(ctx, "(length '(a (b) (c d e)))", 3)
  s6_3_2_assert_int(ctx, "(length '())", 0)
}

// append

test "R5RS 6.3.2: append" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '(x) '(y)) '(x y))")
  s6_3_2_assert_true(ctx, "(equal? (append '(a) '(b c d)) '(a b c d))")
  s6_3_2_assert_true(ctx, "(equal? (append '(a (b)) '((c))) '(a (b) (c)))")
  s6_3_2_assert_true(ctx, "(equal? (append '() 'a) 'a)")
}

// reverse

test "R5RS 6.3.2: reverse" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (reverse '(a b c)) '(c b a))")
  s6_3_2_assert_true(ctx, "(equal? (reverse '(a (b c) d (e (f)))) '((e (f)) d (b c) a))")
  s6_3_2_assert_true(ctx, "(equal? (reverse '()) '())")
}

// list-tail, list-ref

test "R5RS 6.3.2: list-tail" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list-tail '(a b c d) 2) '(c d))")
  s6_3_2_assert_true(ctx, "(equal? (list-tail '(a b c) 0) '(a b c))")
}

test "R5RS 6.3.2: list-ref" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list-ref '(a b c d) 2) 'c)")
  s6_3_2_assert_int(ctx, "(list-ref '(1 2 3) 0)", 1)
}

// map, for-each

test "R5RS 6.3.2: map" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (map + '(1 2 3) '(4 5 6)) '(5 7 9))")
  s6_3_2_assert_true(ctx, "(equal? (map car '((a b) (d e) (g h))) '(a d g))")
}

test "R5RS 6.3.2: for-each" {
  let ctx = new_repl_context()
  // for-each with single list, testing side effects
  s6_3_2_assert_true(ctx,
    "(let ((sum 0)) (for-each (lambda (x) (set! sum (+ sum x))) '(1 2 3)) (= sum 6))"
  )
}

// member, memv, memq

test "R5RS 6.3.2: memq memv member" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (memq 'a '(a b c)) '(a b c))")
  s6_3_2_assert_false(ctx, "(memq 'a '(b c d))")
  s6_3_2_assert_true(ctx, "(equal? (memv 2 '(1 2 3)) '(2 3))")
  s6_3_2_assert_true(ctx, "(equal? (member '(a) '(b (a) c)) '((a) c))")
}

// assq, assv, assoc

test "R5RS 6.3.2: assq assv assoc" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx,
    "(equal? (assq 'b '((a 1) (b 2) (c 3))) '(b 2))"
  )
  s6_3_2_assert_false(ctx, "(assq 'd '((a 1) (b 2) (c 3)))")
  s6_3_2_assert_true(ctx,
    "(equal? (assv 2 '((1 a) (2 b) (3 c))) '(2 b))"
  )
  s6_3_2_assert_true(ctx,
    "(equal? (assoc '(b) '((a 1) ((b) 2) (c 3))) '((b) 2))"
  )
}

// set-car!, set-cdr!

test "R5RS 6.3.2: set-car! set-cdr!" {
  let ctx = new_repl_context()
  // Our implementation returns new pair; test return value
  s6_3_2_assert_true(ctx, "(equal? (set-car! (cons 1 2) 10) '(10 . 2))")
  s6_3_2_assert_true(ctx, "(equal? (set-cdr! (cons 1 2) 20) '(1 . 20))")
}

// caar, cadr, cdar, cddr, caaar, etc.

test "R5RS 6.3.2: caar cadr cdar cddr" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(caar '((1 2) 3))", 1)
  s6_3_2_assert_int(ctx, "(cadr '(1 2 3))", 2)
  s6_3_2_assert_true(ctx, "(equal? (cdar '((1 2) 3)) '(2))")
  s6_3_2_assert_true(ctx, "(equal? (cddr '(1 2 3)) '(3))")
}
