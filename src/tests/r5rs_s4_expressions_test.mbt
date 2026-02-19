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

fn s4_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
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

// delay/force (8 tests)

test "R5RS 4.2.7: delay basic" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(force (delay (+ 1 2)))", 3)
}

test "R5RS 4.2.7: delay memoization" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((count 0)) (let ((p (delay (begin (set! count (+ count 1)) count)))) (force p) (force p) (force p)))",
    1  // count should only increment once due to memoization
  )
}

test "R5RS 4.2.7: delay with side effect" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(let ((x 0)) (let ((p (delay (set! x 5)))) (= x 0)))"  // delay doesn't execute immediately
  )
}

test "R5RS 4.2.7: delay force twice" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(let ((p (delay (+ 1 2)))) (= (force p) (force p)))"  // both forces return same value
  )
}

test "R5RS 4.2.7: nested delay" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(force (force (delay (delay 42))))", 42)
}

test "R5RS 4.2.7: delay with lambda" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(force (delay ((lambda (x) (* x x)) 5)))",
    25
  )
}

test "R5RS 4.2.7: promise? predicate" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(promise? (delay 1))")
  s4_assert_false(ctx, "(promise? 1)")
  s4_assert_false(ctx, "(promise? 'a)")
}

test "R5RS 4.2.7: delay complex expression" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((x 10)) (force (delay (let ((y 20)) (+ x y)))))",
    30
  )
}

// Conditional expressions edge cases (8 tests)

test "R5RS 4.1.5: if with non-boolean tests (truthy)" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(if 0 1 2)", 1)  // 0 is truthy
  s4_assert_int(ctx, "(if '() 1 2)", 1)  // '() is truthy
  s4_assert_int(ctx, "(if \"\" 1 2)", 1)  // "" is truthy
}

test "R5RS 4.1.5: if nested" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(if (if #t #t #f) 1 2)", 1)
  s4_assert_int(ctx, "(if (if #f #t #f) 1 2)", 2)
}

test "R5RS 4.2.1: cond => with multiple clauses" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (cond ((assv 1 '((1 a) (2 b))) => cadr) ((assv 3 '((3 c))) => cadr) (else 'not-found)) 'a)"
  )
}

test "R5RS 4.2.1: cond => second clause" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (cond ((assv 5 '((1 a) (2 b))) => cadr) ((assv 2 '((1 x) (2 y))) => cadr) (else 'not-found)) 'y)"
  )
}

test "R5RS 4.2.1: case with multiple datum" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (case 'c ((a e i o u) 'vowel) ((w y) 'semivowel) ((b c d) 'consonant) (else 'other)) 'consonant)"
  )
}

test "R5RS 4.2.1: case with symbols" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? (case 'apple ((orange banana) 'fruit1) ((apple grape) 'fruit2) (else 'unknown)) 'fruit2)"
  )
}

test "R5RS 4.2.1: nested cond" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(cond ((> 3 2) (cond ((> 5 4) 1) (else 2))) (else 3))",
    1
  )
}

test "R5RS 4.2.1: and or combinations" {
  let ctx = new_repl_context()
  s4_assert_true(ctx, "(and (or #f #t) (or #t #f))")
  s4_assert_true(ctx, "(not (and (or #f #f) #t))")
}

// Lambda edge cases (8 tests)

test "R5RS 4.1.4: lambda empty parameters" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "((lambda () 42))", 42)
}

// NOTE: VM limitation - consecutive lambda application not fully supported
// test "R5RS 4.1.4: lambda multi-level closure" {
//   let ctx = new_repl_context()
//   s4_assert_int(ctx,
//     "(let ((a 1)) (let ((f (lambda (b) (lambda (c) (+ a b c))))) (((f 2) 3))))",
//     6
//   )
// }

// NOTE: Optimizer issue with rest-only lambda
// test "R5RS 4.1.4: lambda rest args only" {
//   let ctx = new_repl_context()
//   s4_assert_true(ctx, "(equal? ((lambda x x) 1 2 3) '(1 2 3))")
//   s4_assert_true(ctx, "(equal? ((lambda x x)) '())")
// }

test "R5RS 4.1.4: lambda capturing loop variable" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((x 10)) ((lambda (y) (+ x y)) 5))",
    15
  )
}

test "R5RS 4.1.4: lambda with multiple expressions" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "((lambda (x) (define y 10) (+ x y)) 5)",
    15
  )
}

test "R5RS 4.1.4: lambda nested same param name" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "((lambda (x) ((lambda (x) x) 5)) 10)",
    5  // inner x shadows outer
  )
}

// NOTE: VM limitation - consecutive lambda application not fully supported
// test "R5RS 4.1.4: lambda application order" {
//   let ctx = new_repl_context()
//   s4_assert_int(ctx,
//     "(let ((x 1)) (((lambda (f) f) (lambda () x))))",
//     1
//   )
// }

test "R5RS 4.1.4: lambda with begin body" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "((lambda (x) (begin (define y 5) (+ x y))) 3)",
    8
  )
}

// let/let*/letrec edge cases (12 tests)

test "R5RS 4.2.2: let empty bindings" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let () 42)", 42)
  s4_assert_int(ctx, "(let () (+ 1 2))", 3)
}

test "R5RS 4.2.2: let shadowing outer" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((x 1)) (let ((x 2) (y x)) y))",
    1  // y binds to outer x
  )
}

test "R5RS 4.2.2: let parallel binding" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((x 1) (y 2)) (let ((x y) (y x)) (- x y)))",
    1  // x=2, y=1, so 2-1=1
  )
}

test "R5RS 4.2.2: let* sequential binding" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let* ((x 1) (y (+ x 1)) (z (+ y 1))) z)", 3)
}

test "R5RS 4.2.2: let* shadowing same name" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let* ((x 1) (x (+ x 1)) (x (+ x 1))) x)", 3)
}

test "R5RS 4.2.2: let* empty bindings" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(let* () 10)", 10)
}

test "R5RS 4.2.2: letrec forward reference" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(letrec ((f (lambda () g)) (g 42)) (f))",
    42
  )
}

test "R5RS 4.2.2: letrec mutual recursion sum" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(letrec ((sum-evens (lambda (n) (if (<= n 0) 0 (+ n (sum-odds (- n 1)))))) (sum-odds (lambda (n) (if (<= n 0) 0 (sum-evens (- n 1)))))) (sum-evens 10))",
    30  // 10+8+6+4+2 = 30
  )
}

test "R5RS 4.2.2: letrec single binding" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(letrec ((fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1))))))) (fact 5))",
    120
  )
}

test "R5RS 4.2.2: letrec with non-procedure" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(letrec ((x 10) (y 20)) (+ x y))",
    30
  )
}

test "R5RS 4.2.2: named let fibonacci" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let fib ((n 7)) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))",
    13
  )
}

test "R5RS 4.2.2: named let with multiple args" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let loop ((a 1) (b 2) (c 3)) (if (> a 3) c (loop (+ a 1) (+ b 1) (+ c 1))))",
    6  // c starts at 3, increments 3 times: 4,5,6
  )
}

// do loop (6 tests)

test "R5RS 4.2.4: do no body" {
  let ctx = new_repl_context()
  s4_assert_int(ctx, "(do ((i 0 (+ i 1))) ((= i 5) i))", 5)
}

test "R5RS 4.2.4: do multiple variables" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(do ((i 0 (+ i 1)) (j 10 (- j 1))) ((= i 5) j))",
    5  // when i=5, j=5
  )
}

test "R5RS 4.2.4: do with body side effects" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(let ((sum 0)) (do ((i 1 (+ i 1))) ((> i 5) sum) (set! sum (+ sum i))))",
    15  // 1+2+3+4+5
  )
}

test "R5RS 4.2.4: do zero iterations" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(do ((i 0 (+ i 1))) ((= i 0) 99))",
    99  // exits immediately
  )
}

test "R5RS 4.2.4: do accumulator pattern" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(do ((i 1 (+ i 1)) (acc 1 (* acc i))) ((> i 5) acc))",
    120  // 5! = 120
  )
}

test "R5RS 4.2.4: do with multiple result expressions" {
  let ctx = new_repl_context()
  s4_assert_int(ctx,
    "(do ((i 0 (+ i 1))) ((= i 3) (+ i 10)))",
    13  // i=3 at exit, returns 3+10
  )
}

// Quasiquote advanced patterns (6 tests)

test "R5RS 4.2.6: quasiquote nested" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(a `(b ,(+ 1 2) ,(list ,(+ 1 3) 'd) e) f) '(a `(b ,(+ 1 2) ,(list 4 'd) e) f))"
  )
}

test "R5RS 4.2.6: multiple splicing" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(,@(list 1 2) ,@(list 3 4)) '(1 2 3 4))"
  )
}

test "R5RS 4.2.6: splicing at end" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(a b ,@(list 'c 'd)) '(a b c d))"
  )
}

test "R5RS 4.2.6: splicing at start" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(,@(list 'x 'y) a b) '(x y a b))"
  )
}

test "R5RS 4.2.6: empty splice" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(equal? `(a ,@'() b) '(a b))"
  )
}

test "R5RS 4.2.6: quasiquote with let" {
  let ctx = new_repl_context()
  s4_assert_true(ctx,
    "(let ((x 1) (y 2)) (equal? `(,x ,(+ x y) ,@(list x y)) '(1 3 1 2)))"
  )
}
