/// R5RS Section 4.1-4.2: Expressions
/// Tests for quote, if, set!, cond, case, and, or, let, let*, letrec, begin, do

fn s4_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s4_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// 4.1.2 Literal expressions (quote)

test "R5RS 4.1.2: quote symbol" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(quote a)") {
    Ok(Value::Symbol("a")) => ()
    Ok(v) => fail("expected symbol a, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 4.1.2: quote list" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(equal? (quote (+ 1 2)) '(+ 1 2))")
}

test "R5RS 4.1.2: quote number" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "'145932", 145932)
}

test "R5RS 4.1.2: quote string" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "'\"abc\"") {
    Ok(Value::String("abc")) => ()
    Ok(v) => fail("expected string abc, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

// 4.1.3 Procedure calls

test "R5RS 4.1.3: procedure call" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(+ 3 4)", 7)
  s4_assert_int(ctx, "((if #f + *) 3 4)", 12)
}

// 4.1.4 Lambda

test "R5RS 4.1.4: lambda basic" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "((lambda (x) (+ x x)) 4)", 8)
}

test "R5RS 4.1.4: lambda rest args" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? ((lambda x x) 3 4 5 6) '(3 4 5 6))"
  )
  s4_assert_true(ctx,
    "(equal? ((lambda (x y . z) z) 3 4 5 6) '(5 6))"
  )
}

test "R5RS 4.1.4: lambda closure" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((add-n (lambda (n) (lambda (x) (+ x n))))) ((add-n 10) 5))",
    15
  )
}

// 4.1.5 if

test "R5RS 4.1.5: if true" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(if (> 3 2) 1 0)", 1)
}

test "R5RS 4.1.5: if false" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(if (> 2 3) 1 0)", 0)
}

test "R5RS 4.1.5: if no else" {
  let ctx = new_repl_context()
  // if without else and false condition returns unspecified
  match repl_eval(ctx, "(if #f 1)") {
    Ok(_) => ()
    Err(e) => fail("error: " + e)
  }
}

// 4.1.6 set!

test "R5RS 4.1.6: set!" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let ((x 1)) (set! x 5) x)", 5)
}

// 4.2.1 cond

test "R5RS 4.2.1: cond basic" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (cond ((> 3 2) 'greater) ((< 3 2) 'less)) 'greater)"
  )
}

test "R5RS 4.2.1: cond else" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (cond ((> 2 3) 'greater) (else 'not-greater)) 'not-greater)"
  )
}

test "R5RS 4.2.1: cond => arrow form" {
  let ctx = new_repl_context()
  // cond => applies procedure to test result
  s4_assert_true(ctx,
    "(equal? (cond ((assv 2 '((1 one) (2 two) (3 three))) => cadr) (else 'not-found)) 'two)"
  )
}

test "R5RS 4.2.1: cond => false test" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (cond ((assv 4 '((1 one) (2 two) (3 three))) => cadr) (else 'not-found)) 'not-found)"
  )
}

// 4.2.1 case

test "R5RS 4.2.1: case" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (case (* 2 3) ((2 3 5 7) 'prime) ((1 4 6 8 9) 'composite)) 'composite)"
  )
}

test "R5RS 4.2.1: case else" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (case 10 ((1 2 3) 'small) (else 'other)) 'other)"
  )
}

// 4.2.1 and / or

test "R5RS 4.2.1: and" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(and (= 2 2) (> 2 1))")
  s4_assert_true(ctx, "(equal? (and 1 2 'c '(f g)) '(f g))")
  s4_assert_true(ctx, "(and)")
}

test "R5RS 4.2.1: or" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(or (= 2 2) (> 2 3))")
  s4_assert_true(ctx, "(equal? (or #f #f 'c) 'c)")
  s4_assert_true(ctx, "(not (or))")
}

// 4.2.2 let

test "R5RS 4.2.2: let" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let ((x 2) (y 3)) (* x y))", 6)
  s4_assert_int(ctx, "(let ((x 2) (y 3)) (let ((x 7) (z (+ x y))) (* z x)))", 35)
}

test "R5RS 4.2.2: let*" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let* ((x 1) (y (+ x 1))) y)", 2)
}

test "R5RS 4.2.2: letrec" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(letrec ((even? (lambda (n) (if (zero? n) #t (odd? (- n 1))))) (odd? (lambda (n) (if (zero? n) #f (even? (- n 1)))))) (even? 88))"
  )
}

test "R5RS 4.2.2: named let" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let loop ((n 10) (acc 0)) (if (zero? n) acc (loop (- n 1) (+ acc n))))",
    55
  )
}

// 4.2.3 begin

test "R5RS 4.2.3: begin" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(begin 1 2 3)", 3)
  s4_assert_int(ctx, "(let ((x 0)) (begin (set! x 5) x))", 5)
}

// 4.2.4 do

test "R5RS 4.2.4: do" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))",
    10
  )
}

test "R5RS 4.2.4: do vector" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (do ((vec (make-vector 5 0)) (i 0 (+ i 1))) ((= i 5) vec) (vector-set! vec i (* i i))) (vector 0 1 4 9 16))"
  )
}

// 4.2.6 quasiquote

test "R5RS 4.2.6: quasiquote" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(equal? `(list ,(+ 1 2) 4) '(list 3 4))")
  s4_assert_true(ctx,
    "(let ((name 'a)) (equal? `(list ,name) '(list a)))"
  )
}

test "R5RS 4.2.6: quasiquote splicing" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(a ,(+ 1 2) ,@(list 4 5 6) b) '(a 3 4 5 6 b))"
  )
}
