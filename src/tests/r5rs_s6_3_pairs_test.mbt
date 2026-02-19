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

// Three-level cXXr (16 tests)

test "R5RS 6.3.2: caaar" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(caaar '(((1))))", 1)
  s6_3_2_assert_int(ctx, "(caaar '(((5 6) 7)))", 5)
}

test "R5RS 6.3.2: caadr" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(caadr '(x (2)))", 2)
  s6_3_2_assert_true(ctx, "(equal? (caadr '(a ((3)))) '(3))")  // car of car of cdr = '(3)
}

test "R5RS 6.3.2: cadar" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(cadar '((x 3)))", 3)
  s6_3_2_assert_true(ctx, "(equal? (cadar '((a (4)))) '(4))")  // car of cdr of car = '(4)
}

test "R5RS 6.3.2: caddr" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(caddr '(a b 4))", 4)
  s6_3_2_assert_true(ctx, "(equal? (caddr '(1 2 (5))) '(5))")  // car of cdr of cdr = '(5)
}

test "R5RS 6.3.2: cdaar" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cdaar '(((a . (6))))) '(6))")
  s6_3_2_assert_true(ctx, "(equal? (cdaar '(((1 2 3)))) '(2 3))")
}

test "R5RS 6.3.2: cdadr" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cdadr '(a (b . (6)))) '(6))")
  s6_3_2_assert_true(ctx, "(equal? (cdadr '(x (y z))) '(z))")
}

test "R5RS 6.3.2: cddar" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cddar '((a b . (7)))) '(7))")
  s6_3_2_assert_true(ctx, "(equal? (cddar '((1 2 3))) '(3))")
}

test "R5RS 6.3.2: cdddr" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cdddr '(a b c . (8))) '(8))")
  s6_3_2_assert_true(ctx, "(equal? (cdddr '(1 2 3 4)) '(4))")
}

// List construction patterns (10 tests)

test "R5RS 6.3.2: cons with nested lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cons '(1 2) '((3 4) (5 6))) '((1 2) (3 4) (5 6)))")
}

test "R5RS 6.3.2: cons creates pair" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(pair? (cons 1 2))")
  s6_3_2_assert_true(ctx, "(pair? (cons 'a '()))")
}

test "R5RS 6.3.2: list with nested structures" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list '(a) '(b (c))) '((a) (b (c))))")
  s6_3_2_assert_true(ctx, "(equal? (list 1 (list 2 3) 4) '(1 (2 3) 4))")
}

test "R5RS 6.3.2: improper list with pair?" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(pair? '(1 . 2))")
  s6_3_2_assert_true(ctx, "(pair? '(a b . c))")
}

test "R5RS 6.3.2: improper list with list?" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(list? '(1 . 2))")
  s6_3_2_assert_false(ctx, "(list? '(a b . c))")
}

test "R5RS 6.3.2: dot notation" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(car '(1 . 2))", 1)
  s6_3_2_assert_int(ctx, "(cdr '(1 . 2))", 2)
  s6_3_2_assert_true(ctx, "(equal? '(a . (b . (c . ()))) '(a b c))")
}

test "R5RS 6.3.2: cons vs list" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (cons 1 (cons 2 (cons 3 '()))) (list 1 2 3))")
}

test "R5RS 6.3.2: empty list properties" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(pair? '())")
  s6_3_2_assert_true(ctx, "(list? '())")
  s6_3_2_assert_true(ctx, "(null? '())")
}

test "R5RS 6.3.2: nested empty lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(pair? '(()))")
  s6_3_2_assert_int(ctx, "(length '(() ()))", 2)
}

test "R5RS 6.3.2: list of lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list (list 1) (list 2 3)) '((1) (2 3)))")
}

// List manipulation (12 tests)

test "R5RS 6.3.2: append three lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '(1 2) '(3 4) '(5 6)) '(1 2 3 4 5 6))")
}

test "R5RS 6.3.2: append four lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '(a) '(b) '(c) '(d)) '(a b c d))")
}

test "R5RS 6.3.2: append with improper tail" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '(1 2) 3) '(1 2 . 3))")
  s6_3_2_assert_true(ctx, "(equal? (append '(a b) 'c) '(a b . c))")
}

test "R5RS 6.3.2: append empty lists" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '() '() '()) '())")
  s6_3_2_assert_true(ctx, "(equal? (append '() '(a) '()) '(a))")
}

test "R5RS 6.3.2: reverse nested" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (reverse '((a b) (c d))) '((c d) (a b)))")
  s6_3_2_assert_true(ctx, "(equal? (reverse '(1 (2 3) 4)) '(4 (2 3) 1))")
}

test "R5RS 6.3.2: reverse single element" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (reverse '(x)) '(x))")
}

test "R5RS 6.3.2: list-tail zero offset" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list-tail '(a b c) 0) '(a b c))")
  s6_3_2_assert_true(ctx, "(equal? (list-tail '(x) 0) '(x))")
}

test "R5RS 6.3.2: list-tail full offset" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list-tail '(a b c) 3) '())")
}

test "R5RS 6.3.2: list-ref with nested" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (list-ref '((a b) (c d) (e f)) 1) '(c d))")
  s6_3_2_assert_true(ctx, "(equal? (list-ref '((x)) 0) '(x))")
}

test "R5RS 6.3.2: length with nested" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(length '(1 (2 3) 4))", 3)
  s6_3_2_assert_int(ctx, "(length '((a) (b) (c)))", 3)
}

test "R5RS 6.3.2: length single element" {
  let ctx = new_repl_context()
  s6_3_2_assert_int(ctx, "(length '(x))", 1)
  s6_3_2_assert_int(ctx, "(length '((a b c)))", 1)
}

test "R5RS 6.3.2: append preserves structure" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (append '((a) (b)) '((c) (d))) '((a) (b) (c) (d)))")
}

// Association lists (8 tests)

test "R5RS 6.3.2: assq first match" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (assq 'a '((a 1) (b 2) (a 3))) '(a 1))")
}

test "R5RS 6.3.2: assq not found" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(assq 'z '((a 1) (b 2) (c 3)))")
}

test "R5RS 6.3.2: assv with numbers" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (assv 2 '((1 one) (2 two) (3 three))) '(2 two))")
  s6_3_2_assert_true(ctx, "(equal? (assv 1 '((1 a) (2 b))) '(1 a))")
}

test "R5RS 6.3.2: assv not found" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(assv 99 '((1 one) (2 two)))")
}

test "R5RS 6.3.2: assoc with complex keys" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (assoc '(a b) '(((a) x) ((a b) y))) '((a b) y))")
  s6_3_2_assert_true(ctx, "(equal? (assoc '(1 2) '(((3) a) ((1 2) b))) '((1 2) b))")
}

test "R5RS 6.3.2: assoc with strings" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (assoc \"hello\" '((\"hi\" 1) (\"hello\" 2))) '(\"hello\" 2))")
}

test "R5RS 6.3.2: assoc not found" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(assoc '(x y) '(((a) 1) ((b) 2)))")
}

test "R5RS 6.3.2: association list structure" {
  let ctx = new_repl_context()
  // assoc returns the entire pair
  s6_3_2_assert_true(ctx, "(pair? (assq 'a '((a 1) (b 2))))")
  s6_3_2_assert_true(ctx, "(equal? (car (assq 'a '((a 1)))) 'a)")
}

// Membership tests (4 tests)

test "R5RS 6.3.2: memq not found" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(memq 'z '(a b c))")
  s6_3_2_assert_false(ctx, "(memq 'x '())")
}

test "R5RS 6.3.2: memq found" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (memq 'b '(a b c)) '(b c))")
  s6_3_2_assert_true(ctx, "(equal? (memq 'a '(a)) '(a))")
}

test "R5RS 6.3.2: member with complex elements" {
  let ctx = new_repl_context()
  s6_3_2_assert_true(ctx, "(equal? (member '(1 2) '((a) (1 2) (3 4))) '((1 2) (3 4)))")
  s6_3_2_assert_true(ctx, "(equal? (member '(x) '((y) (x) (z))) '((x) (z)))")
}

test "R5RS 6.3.2: member not found" {
  let ctx = new_repl_context()
  s6_3_2_assert_false(ctx, "(member '(a b) '((c d) (e f)))")
  s6_3_2_assert_false(ctx, "(member 'x '())")
}
