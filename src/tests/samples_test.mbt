/// Integration tests for sample Scheme programs.
/// Each test corresponds to a .scm file in the samples/ directory.

fn sample_eval(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(_) => ()
    Err(e) => fail("eval failed: " + e)
  }
}

fn sample_assert_int(ctx : VMReplContext, expr : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, expr) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, expected)
    Ok(v) => fail("expected " + expected.to_string() + ", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

fn sample_assert_true(ctx : VMReplContext, expr : String) -> Unit raise Error {
  match repl_eval(ctx, expr) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

fn sample_assert_str(ctx : VMReplContext, expr : String, expected : String) -> Unit raise Error {
  match repl_eval(ctx, expr) {
    Ok(Value::String(s)) => assert_eq(s, expected)
    Ok(v) => fail("expected \"" + expected + "\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

fn sample_assert_list_eq(ctx : VMReplContext, expr : String, expected : String) -> Unit raise Error {
  let code = "(equal? " + expr + " " + expected + ")"
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("list mismatch: " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

fn sample_assert_false(ctx : VMReplContext, expr : String) -> Unit raise Error {
  match repl_eval(ctx, expr) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

// ============================================================
// samples/fibonacci/fibonacci.scm
// ============================================================

test "sample: fibonacci" {
  let ctx = new_repl_context()

  // 1. Naive recursive fibonacci
  sample_eval(ctx,
    "(define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))",
  )
  sample_assert_int(ctx, "(fib 10)", 55)

  // 2. Tail-recursive fibonacci
  sample_eval(ctx,
    "(define (fib-tail n) (define (iter a b count) (if (= count 0) b (iter (+ a b) a (- count 1)))) (iter 1 0 n))",
  )
  sample_assert_int(ctx, "(fib-tail 30)", 832040)

  // 3. Fibonacci with do loop
  sample_eval(ctx,
    "(define (fib-do n) (if (= n 0) 0 (do ((i 1 (+ i 1)) (a 1 (+ a b)) (b 0 a)) ((= i n) a))))",
  )
  sample_assert_int(ctx, "(fib-do 30)", 832040)

  // 4. Fibonacci sequence as a list
  sample_eval(ctx,
    "(define (fib-list n) (let loop ((i 0) (acc '())) (if (> i n) (reverse acc) (loop (+ i 1) (cons (fib-tail i) acc)))))",
  )
  sample_assert_list_eq(ctx, "(fib-list 10)", "'(0 1 1 2 3 5 8 13 21 34 55)")

  // 5. Generalized tabulate
  sample_eval(ctx,
    "(define (tabulate f start end) (let loop ((i start) (acc '())) (if (> i end) (reverse acc) (loop (+ i 1) (cons (f i) acc)))))",
  )
  sample_assert_list_eq(ctx,
    "(tabulate fib-tail 0 10)",
    "'(0 1 1 2 3 5 8 13 21 34 55)",
  )

  // 6. All implementations agree
  sample_eval(ctx,
    "(define (fib-check n) (let ((r1 (fib n)) (r2 (fib-tail n)) (r3 (fib-do n))) (and (= r1 r2) (= r2 r3))))",
  )
  sample_assert_true(ctx, "(fib-check 10)")
}

// ============================================================
// samples/sort/sort.scm
// ============================================================

test "sample: sort" {
  let ctx = new_repl_context()

  // filter utility
  sample_eval(ctx,
    "(define (filter pred lst) (let loop ((l lst) (acc '())) (cond ((null? l) (reverse acc)) ((pred (car l)) (loop (cdr l) (cons (car l) acc))) (else (loop (cdr l) acc)))))",
  )

  // Insertion sort
  sample_eval(ctx,
    "(define (insert x sorted less?) (cond ((null? sorted) (list x)) ((less? x (car sorted)) (cons x sorted)) (else (cons (car sorted) (insert x (cdr sorted) less?)))))",
  )
  sample_eval(ctx,
    "(define (insertion-sort lst less?) (let loop ((l lst) (acc '())) (if (null? l) acc (loop (cdr l) (insert (car l) acc less?)))))",
  )
  sample_assert_list_eq(ctx,
    "(insertion-sort '(5 3 8 1 9 2 7 4 6) <)",
    "'(1 2 3 4 5 6 7 8 9)",
  )

  // Quicksort
  sample_eval(ctx,
    "(define (quicksort lst less?) (if (or (null? lst) (null? (cdr lst))) lst (let ((pivot (car lst)) (rest (cdr lst))) (let ((lo (filter (lambda (x) (less? x pivot)) rest)) (hi (filter (lambda (x) (not (less? x pivot))) rest))) (append (quicksort lo less?) (cons pivot (quicksort hi less?)))))))",
  )
  sample_assert_list_eq(ctx,
    "(quicksort '(5 3 8 1 9 2 7 4 6) <)",
    "'(1 2 3 4 5 6 7 8 9)",
  )

  // Merge sort
  sample_eval(ctx,
    "(define (merge xs ys less?) (cond ((null? xs) ys) ((null? ys) xs) ((less? (car xs) (car ys)) (cons (car xs) (merge (cdr xs) ys less?))) (else (cons (car ys) (merge xs (cdr ys) less?)))))",
  )
  sample_eval(ctx,
    "(define (split lst) (let loop ((l lst) (left '()) (right '()) (toggle #t)) (if (null? l) (list (reverse left) (reverse right)) (if toggle (loop (cdr l) (cons (car l) left) right #f) (loop (cdr l) left (cons (car l) right) #t)))))",
  )
  sample_eval(ctx,
    "(define (merge-sort lst less?) (if (or (null? lst) (null? (cdr lst))) lst (let ((halves (split lst))) (merge (merge-sort (car halves) less?) (merge-sort (cadr halves) less?) less?))))",
  )
  sample_assert_list_eq(ctx,
    "(merge-sort '(5 3 8 1 9 2 7 4 6) <)",
    "'(1 2 3 4 5 6 7 8 9)",
  )

  // All three sorts agree
  sample_eval(ctx,
    "(define (sort-check) (let ((data '(38 27 43 3 9 82 10 1 57 24))) (let ((r1 (insertion-sort data <)) (r2 (quicksort data <)) (r3 (merge-sort data <))) (and (equal? r1 r2) (equal? r2 r3) (equal? r1 '(1 3 9 10 24 27 38 43 57 82))))))",
  )
  sample_assert_true(ctx, "(sort-check)")
}

// ============================================================
// samples/stream/stream.scm
// ============================================================

test "sample: stream" {
  let ctx = new_repl_context()

  // Stream primitives
  sample_eval(ctx, "(define stream-null '())")
  sample_eval(ctx, "(define (stream-null? s) (null? s))")
  sample_eval(ctx,
    "(define-syntax stream-cons (syntax-rules () ((stream-cons x s) (cons x (delay s)))))",
  )
  sample_eval(ctx, "(define (stream-car s) (car s))")
  sample_eval(ctx, "(define (stream-cdr s) (force (cdr s)))")

  // Stream operations
  sample_eval(ctx,
    "(define (stream-take n s) (if (or (= n 0) (stream-null? s)) '() (cons (stream-car s) (stream-take (- n 1) (stream-cdr s)))))",
  )
  sample_eval(ctx,
    "(define (stream-map f s) (if (stream-null? s) stream-null (stream-cons (f (stream-car s)) (stream-map f (stream-cdr s)))))",
  )
  sample_eval(ctx,
    "(define (stream-filter pred s) (cond ((stream-null? s) stream-null) ((pred (stream-car s)) (stream-cons (stream-car s) (stream-filter pred (stream-cdr s)))) (else (stream-filter pred (stream-cdr s)))))",
  )
  sample_eval(ctx,
    "(define (stream-zip-with f s1 s2) (if (or (stream-null? s1) (stream-null? s2)) stream-null (stream-cons (f (stream-car s1) (stream-car s2)) (stream-zip-with f (stream-cdr s1) (stream-cdr s2)))))",
  )

  // Natural numbers
  sample_eval(ctx, "(define (integers-from n) (stream-cons n (integers-from (+ n 1))))")
  sample_eval(ctx, "(define nats (integers-from 0))")
  sample_assert_list_eq(ctx, "(stream-take 5 nats)", "'(0 1 2 3 4)")

  // Fibonacci stream
  sample_eval(ctx,
    "(define fibs (stream-cons 0 (stream-cons 1 (stream-zip-with + fibs (stream-cdr fibs)))))",
  )
  sample_assert_list_eq(ctx,
    "(stream-take 10 fibs)",
    "'(0 1 1 2 3 5 8 13 21 34)",
  )

  // Stream-filter
  sample_assert_list_eq(ctx,
    "(stream-take 5 (stream-filter odd? (integers-from 0)))",
    "'(1 3 5 7 9)",
  )

  // Sieve of Eratosthenes (delay + nested lambda captures)
  sample_eval(ctx,
    "(define (sieve s) (stream-cons (stream-car s) (sieve (stream-filter (lambda (x) (not (= (remainder x (stream-car s)) 0))) (stream-cdr s)))))",
  )
  sample_eval(ctx, "(define primes (sieve (integers-from 2)))")
  sample_assert_list_eq(ctx,
    "(stream-take 10 primes)",
    "'(2 3 5 7 11 13 17 19 23 29)",
  )

  // Delay + lambda capturing from enclosing scope
  sample_eval(ctx, "(define (test-d4 s n) (delay (stream-filter (lambda (x) (> x n)) s)))")
  sample_assert_list_eq(ctx, "(stream-take 3 (force (test-d4 (integers-from 0) 5)))", "'(6 7 8)")

  // Combined verification
  sample_eval(ctx,
    "(define (stream-check) (and (equal? (stream-take 5 nats) '(0 1 2 3 4)) (equal? (stream-take 10 fibs) '(0 1 1 2 3 5 8 13 21 34)) (equal? (stream-take 5 (stream-filter odd? (integers-from 0))) '(1 3 5 7 9)) (equal? (stream-take 10 primes) '(2 3 5 7 11 13 17 19 23 29))))",
  )
  sample_assert_true(ctx, "(stream-check)")
}

// ============================================================
// samples/continuation/continuation.scm
// ============================================================

test "sample: continuation" {
  let ctx = new_repl_context()
  // Enable call/cc
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.globals.set(
    "call-with-current-continuation",
    Value::Procedure(Procedure::Native("call-with-current-continuation")),
  )
  ctx.compiler_globals.set("call/cc", ())
  ctx.compiler_globals.set("call-with-current-continuation", ())

  // 1. Non-local exit (early return)
  sample_eval(ctx,
    "(define (find-first pred lst) (call/cc (lambda (return) (for-each (lambda (x) (if (pred x) (return x))) lst) #f)))",
  )
  sample_assert_int(ctx, "(find-first even? '(1 3 5 4 7))", 4)
  sample_assert_true(ctx, "(eq? (find-first even? '(1 3 5 7)) #f)")

  // 2. Exception handling with call/cc
  sample_eval(ctx,
    "(define (try thunk handler) (call/cc (lambda (exit) (let ((raise (lambda (err) (exit (handler err))))) (thunk raise)))))",
  )
  sample_eval(ctx,
    "(define (safe-divide a b) (try (lambda (raise) (if (= b 0) (raise \"division by zero\") (quotient a b))) (lambda (err) (string-append \"Error: \" err))))",
  )
  sample_assert_int(ctx, "(safe-divide 10 3)", 3)
  sample_assert_str(ctx, "(safe-divide 10 0)", "Error: division by zero")

  // 3. Collect results
  sample_eval(ctx,
    "(define (collect-matches pred lst) (let ((results '())) (call/cc (lambda (done) (for-each (lambda (x) (if (pred x) (set! results (cons x results)))) lst) (reverse results)))))",
  )
  sample_assert_list_eq(ctx,
    "(collect-matches odd? '(1 2 3 4 5 6 7 8 9))",
    "'(1 3 5 7 9)",
  )

  // 4. Tree traversal with early exit (helper defined separately to avoid letrec-in-callcc)
  sample_eval(ctx,
    "(define (tree-walk t sum abort) (cond ((number? t) (if (< t 0) (abort sum) (+ sum t))) ((null? t) sum) (else (tree-walk (cdr t) (tree-walk (car t) sum abort) abort))))",
  )
  sample_eval(ctx,
    "(define (tree-sum-until-negative tree) (call/cc (lambda (abort) (tree-walk tree 0 abort))))",
  )
  sample_assert_int(ctx, "(tree-sum-until-negative '(1 (2 3) (4 (5 6))))", 21)
  sample_assert_int(ctx, "(tree-sum-until-negative '(1 (2 -1) (4 (5 6))))", 3)

  // 5. Range collection (pure recursion, no call/cc needed)
  sample_eval(ctx,
    "(define (range-collect start end) (let loop ((i end) (result '())) (if (< i start) result (loop (- i 1) (cons i result)))))",
  )
  sample_assert_list_eq(ctx, "(range-collect 1 5)", "'(1 2 3 4 5)")

  // Combined verification
  sample_eval(ctx,
    "(define (continuation-check) (and (= (find-first even? '(1 3 5 4 7)) 4) (eq? (find-first even? '(1 3 5 7)) #f) (= (safe-divide 10 3) 3) (string=? (safe-divide 10 0) \"Error: division by zero\") (equal? (collect-matches odd? '(1 2 3 4 5 6 7 8 9)) '(1 3 5 7 9)) (= (tree-sum-until-negative '(1 (2 3) (4 (5 6)))) 21) (= (tree-sum-until-negative '(1 (2 -1) (4 (5 6)))) 3) (equal? (range-collect 1 5) '(1 2 3 4 5))))",
  )
  sample_assert_true(ctx, "(continuation-check)")
}

// ============================================================
// samples/oop/oop.scm
// ============================================================

test "sample: oop" {
  let ctx = new_repl_context()

  // 1. Counter object
  sample_eval(ctx,
    "(define (make-counter . args) (let ((count (if (null? args) 0 (car args)))) (define (dispatch msg . params) (cond ((eq? msg 'inc) (set! count (+ count 1)) count) ((eq? msg 'dec) (set! count (- count 1)) count) ((eq? msg 'get) count) ((eq? msg 'reset) (set! count 0) count) (else (string-append \"Unknown message: \" (symbol->string msg))))) dispatch))",
  )
  sample_eval(ctx, "(define c (make-counter 10))")
  sample_eval(ctx, "(c 'inc)")
  sample_eval(ctx, "(c 'inc)")
  sample_eval(ctx, "(c 'inc)")
  sample_assert_int(ctx, "(c 'get)", 13)

  // 2. Stack object
  sample_eval(ctx,
    "(define (make-stack) (let ((items '())) (define (dispatch msg . params) (cond ((eq? msg 'push) (set! items (cons (car params) items)) items) ((eq? msg 'pop) (if (null? items) 'empty (let ((top (car items))) (set! items (cdr items)) top))) ((eq? msg 'peek) (if (null? items) 'empty (car items))) ((eq? msg 'size) (length items)) ((eq? msg 'empty?) (null? items)) ((eq? msg 'to-list) items) (else \"unknown\"))) dispatch))",
  )
  sample_eval(ctx, "(define s (make-stack))")
  sample_eval(ctx, "(s 'push 1)")
  sample_eval(ctx, "(s 'push 2)")
  sample_eval(ctx, "(s 'push 3)")
  sample_assert_int(ctx, "(s 'peek)", 3)
  sample_assert_int(ctx, "(s 'size)", 3)
  sample_assert_int(ctx, "(s 'pop)", 3)
  sample_assert_int(ctx, "(s 'pop)", 2)
  sample_assert_int(ctx, "(s 'size)", 1)

  // 3. Bank account with transaction log
  sample_eval(ctx,
    "(define (make-account name initial-balance) (let ((balance initial-balance) (log '())) (define (record! action amount) (set! log (cons (list action amount balance) log))) (define (dispatch msg . params) (cond ((eq? msg 'deposit) (let ((amount (car params))) (set! balance (+ balance amount)) (record! 'deposit amount) balance)) ((eq? msg 'withdraw) (let ((amount (car params))) (if (< balance amount) 'insufficient-funds (begin (set! balance (- balance amount)) (record! 'withdraw amount) balance)))) ((eq? msg 'balance) balance) ((eq? msg 'name) name) ((eq? msg 'history) (reverse log)) (else \"unknown\"))) dispatch))",
  )
  sample_eval(ctx, "(define acc (make-account \"Alice\" 1000))")
  sample_eval(ctx, "(acc 'deposit 500)")
  sample_eval(ctx, "(acc 'withdraw 200)")
  sample_assert_int(ctx, "(acc 'balance)", 1300)
  sample_assert_int(ctx, "(length (acc 'history))", 2)

  // 4. Inheritance via delegation (savings account)
  sample_eval(ctx,
    "(define (make-savings-account name initial-balance interest-pct) (let ((base (make-account name initial-balance))) (define (dispatch msg . params) (cond ((eq? msg 'add-interest) (let ((interest (quotient (* (base 'balance) interest-pct) 100))) (base 'deposit interest))) ((eq? msg 'rate) interest-pct) (else (apply base (cons msg params))))) dispatch))",
  )
  sample_eval(ctx, "(define sav (make-savings-account \"Bob\" 1000 10))")
  sample_eval(ctx, "(sav 'add-interest)")
  sample_assert_int(ctx, "(sav 'balance)", 1100)

  // Combined verification
  sample_eval(ctx,
    "(define (oop-check) (let ((c (make-counter 10))) (c 'inc) (c 'inc) (c 'inc) (let ((counter-ok (= (c 'get) 13))) (let ((s (make-stack))) (s 'push 1) (s 'push 2) (s 'push 3) (let ((stack-ok (and (= (s 'peek) 3) (= (s 'size) 3) (= (s 'pop) 3) (= (s 'pop) 2) (= (s 'size) 1)))) (let ((acc (make-account \"Alice\" 1000))) (acc 'deposit 500) (acc 'withdraw 200) (let ((account-ok (and (= (acc 'balance) 1300) (= (length (acc 'history)) 2)))) (let ((sav (make-savings-account \"Bob\" 1000 10))) (sav 'add-interest) (let ((savings-ok (= (sav 'balance) 1100))) (and counter-ok stack-ok account-ok savings-ok))))))))))",
  )
  sample_assert_true(ctx, "(oop-check)")
}

// ============================================================
// samples/textproc/textproc.scm
// ============================================================

test "sample: textproc" {
  let ctx = new_repl_context()

  // 1. Caesar cipher
  sample_eval(ctx,
    "(define (char-shift c n) (let ((base (if (char-upper-case? c) (char->integer #\\A) (char->integer #\\a)))) (integer->char (+ base (modulo (+ (- (char->integer c) base) n) 26)))))",
  )
  sample_eval(ctx,
    "(define (caesar text shift) (list->string (map (lambda (c) (if (char-alphabetic? c) (char-shift c shift) c)) (string->list text))))",
  )
  sample_assert_str(ctx, "(caesar \"Hello\" 3)", "Khoor")
  sample_assert_str(ctx, "(caesar \"Khoor\" -3)", "Hello")
  sample_assert_str(ctx, "(caesar \"ABC xyz\" 1)", "BCD yza")

  // 2. Palindrome check
  sample_eval(ctx,
    "(define (palindrome? str) (let ((chars (filter char-alphabetic? (map char-downcase (string->list str))))) (equal? chars (reverse chars))))",
  )
  sample_assert_true(ctx, "(palindrome? \"racecar\")")
  sample_assert_true(ctx, "(palindrome? \"A man a plan a canal Panama\")")
  sample_assert_false(ctx, "(palindrome? \"hello\")")

  // 3. String split
  sample_eval(ctx,
    "(define (string-split str delim) (let loop ((chars (string->list str)) (current '()) (result '())) (cond ((null? chars) (reverse (if (null? current) result (cons (list->string (reverse current)) result)))) ((char=? (car chars) delim) (if (null? current) (loop (cdr chars) '() result) (loop (cdr chars) '() (cons (list->string (reverse current)) result)))) (else (loop (cdr chars) (cons (car chars) current) result)))))",
  )
  sample_assert_list_eq(ctx,
    "(string-split \"hello world foo\" #\\space)",
    "'(\"hello\" \"world\" \"foo\")",
  )
  sample_assert_list_eq(ctx, "(string-split \"abc\" #\\,)", "'(\"abc\")")
  sample_assert_list_eq(ctx, "(string-split \"\" #\\,)", "'()")

  // 4. Character frequency count (using (char . count) pairs)
  sample_eval(ctx,
    "(define (char-freq str) (let loop ((chars (string->list str)) (freq '())) (if (null? chars) freq (let ((c (car chars))) (let ((entry (assv c freq))) (if entry (loop (cdr chars) (map (lambda (p) (if (eqv? (car p) c) (cons c (+ (cdr p) 1)) p)) freq)) (loop (cdr chars) (cons (cons c 1) freq))))))))",
  )
  sample_eval(ctx, "(define freq (char-freq \"aabbc\"))")
  sample_assert_int(ctx, "(cdr (assv #\\a freq))", 2)
  sample_assert_int(ctx, "(cdr (assv #\\b freq))", 2)
  sample_assert_int(ctx, "(cdr (assv #\\c freq))", 1)

  // 5. String operations: make-string, substring, string-ref
  sample_assert_str(ctx, "(make-string 5 #\\x)", "xxxxx")
  sample_assert_str(ctx, "(substring \"hello world\" 6 11)", "world")
  sample_assert_true(ctx, "(char=? (string-ref \"abc\" 1) #\\b)")
  sample_assert_int(ctx, "(string-length \"hello\")", 5)

  // 6. Case-insensitive string comparison
  sample_assert_true(ctx, "(string-ci=? \"Hello\" \"hello\")")
  sample_assert_true(ctx, "(string-ci<? \"abc\" \"DEF\")")

  // 7. String pad
  sample_eval(ctx,
    "(define (string-pad-right s width pad) (let ((len (string-length s))) (if (>= len width) s (string-append s (make-string (- width len) pad)))))",
  )
  sample_assert_str(ctx, "(string-pad-right \"hi\" 5 #\\.)", "hi...")

  // Combined verification
  sample_eval(ctx,
    "(define (textproc-check) (and (string=? (caesar (caesar \"Secret\" 13) -13) \"Secret\") (palindrome? \"abcba\") (not (palindrome? \"abcd\")) (equal? (string-split \"a,b,c\" #\\,) '(\"a\" \"b\" \"c\")) (= (cdr (assv #\\l (char-freq \"hello\"))) 2) (string-ci=? \"ABC\" \"abc\") (string=? (string-pad-right \"x\" 4 #\\-) \"x---\")))",
  )
  sample_assert_true(ctx, "(textproc-check)")
}

// ============================================================
// samples/numerics/numerics.scm
// ============================================================

test "sample: numerics" {
  let ctx = new_repl_context()

  // 1. Arithmetic with real numbers
  sample_assert_true(ctx, "(< (abs (- (+ (/ 1.0 3.0) (/ 1.0 6.0)) 0.5)) 0.0001)")
  sample_assert_true(ctx, "(< (abs (- (* (/ 2.0 3.0) (/ 3.0 4.0)) 0.5)) 0.0001)")
  // numerator/denominator work on integers
  sample_assert_int(ctx, "(numerator 3)", 3)
  sample_assert_int(ctx, "(denominator 3)", 1)
  sample_assert_true(ctx, "(exact? 42)")
  sample_assert_true(ctx, "(inexact? 3.14)")

  // 2. Rounding functions
  sample_eval(ctx,
    "(define (rounding-table x) (list (floor x) (ceiling x) (truncate x) (round x)))",
  )
  sample_assert_list_eq(ctx, "(rounding-table 2.7)", "'(2 3 2 3)")
  sample_assert_list_eq(ctx, "(rounding-table -2.7)", "'(-3 -2 -2 -3)")

  // 3. Math functions
  sample_assert_true(ctx, "(< (abs (- (sin 0.0) 0.0)) 0.0001)")
  sample_assert_true(ctx, "(< (abs (- (cos 0.0) 1.0)) 0.0001)")
  sample_assert_true(ctx, "(< (abs (- (exp 1.0) 2.71828)) 0.001)")
  sample_assert_true(ctx, "(< (abs (- (log 1.0) 0.0)) 0.0001)")
  sample_assert_true(ctx, "(= (expt 2 10) 1024)")
  sample_assert_true(ctx, "(= (sqrt 144) 12)")

  // 4. GCD, LCM, abs, max, min
  sample_assert_int(ctx, "(gcd 12 8)", 4)
  sample_assert_int(ctx, "(lcm 4 6)", 12)
  sample_assert_int(ctx, "(abs -42)", 42)
  sample_assert_int(ctx, "(max 3 7 1 9 2)", 9)
  sample_assert_int(ctx, "(min 3 7 1 9 2)", 1)

  // 5. Quotient, remainder, modulo
  sample_assert_int(ctx, "(quotient 17 5)", 3)
  sample_assert_int(ctx, "(remainder 17 5)", 2)
  sample_assert_int(ctx, "(modulo 17 5)", 2)
  sample_assert_int(ctx, "(remainder -17 5)", -2)
  sample_assert_int(ctx, "(modulo -17 5)", 3)

  // 6. Complex numbers
  sample_eval(ctx, "(define z (make-rectangular 3 4))")
  sample_assert_true(ctx, "(complex? z)")
  sample_assert_true(ctx, "(= (real-part z) 3)")
  sample_assert_true(ctx, "(= (imag-part z) 4)")
  sample_assert_true(ctx, "(= (magnitude z) 5)")

  // 7. Numeric predicates
  sample_assert_true(ctx, "(zero? 0)")
  sample_assert_true(ctx, "(positive? 5)")
  sample_assert_true(ctx, "(negative? -3)")
  sample_assert_true(ctx, "(odd? 7)")
  sample_assert_true(ctx, "(even? 8)")
  sample_assert_true(ctx, "(integer? 42)")
  sample_assert_true(ctx, "(number? 3.14)")

  // 8. Pi approximation via Leibniz series
  sample_eval(ctx,
    "(define (approx-pi n) (* 4 (let loop ((k 0) (sum 0.0)) (if (>= k n) sum (loop (+ k 1) (+ sum (/ (if (even? k) 1.0 -1.0) (+ (* 2.0 k) 1.0))))))))",
  )
  sample_eval(ctx, "(define pi-est (approx-pi 1000))")
  sample_assert_true(ctx, "(< (abs (- pi-est 3.14159)) 0.002)")

  // Combined verification
  sample_eval(ctx,
    "(define (numerics-check) (and (< (abs (- (+ (/ 1.0 3.0) (/ 1.0 6.0)) 0.5)) 0.0001) (= (expt 2 10) 1024) (= (gcd 12 8) 4) (= (magnitude (make-rectangular 3 4)) 5) (< (abs (- pi-est 3.14159)) 0.002)))",
  )
  sample_assert_true(ctx, "(numerics-check)")
}

// ============================================================
// samples/vectors/vectors.scm
// ============================================================

test "sample: vectors" {
  let ctx = new_repl_context()

  // 1. Basic vector operations
  sample_eval(ctx, "(define v (vector 5 3 1 4 2))")
  sample_assert_int(ctx, "(vector-length v)", 5)
  sample_assert_int(ctx, "(vector-ref v 0)", 5)
  sample_assert_int(ctx, "(vector-ref v 2)", 1)
  sample_assert_list_eq(ctx, "(vector->list v)", "'(5 3 1 4 2)")

  // 2. Bubble sort (in-place)
  sample_eval(ctx,
    "(define (bubble-sort! vec) (let ((n (vector-length vec))) (do ((i 0 (+ i 1))) ((= i (- n 1)) vec) (do ((j 0 (+ j 1))) ((= j (- n i 1))) (if (> (vector-ref vec j) (vector-ref vec (+ j 1))) (let ((tmp (vector-ref vec j))) (vector-set! vec j (vector-ref vec (+ j 1))) (vector-set! vec (+ j 1) tmp)))))))",
  )
  sample_eval(ctx, "(define v2 (vector 5 3 1 4 2))")
  sample_eval(ctx, "(bubble-sort! v2)")
  sample_assert_list_eq(ctx, "(vector->list v2)", "'(1 2 3 4 5)")

  // 3. Matrix operations (vector of vectors)
  sample_eval(ctx,
    "(define (make-matrix rows cols init) (let ((m (make-vector rows))) (do ((i 0 (+ i 1))) ((= i rows) m) (vector-set! m i (make-vector cols init)))))",
  )
  sample_eval(ctx,
    "(define (matrix-ref m i j) (vector-ref (vector-ref m i) j))",
  )
  sample_eval(ctx,
    "(define (matrix-set! m i j val) (vector-set! (vector-ref m i) j val))",
  )
  sample_eval(ctx,
    "(define (matrix-multiply a b) (let ((m (vector-length a)) (p (vector-length b)) (n (vector-length (vector-ref b 0)))) (let ((result (make-matrix m n 0))) (do ((i 0 (+ i 1))) ((= i m) result) (do ((j 0 (+ j 1))) ((= j n)) (do ((k 0 (+ k 1))) ((= k p)) (matrix-set! result i j (+ (matrix-ref result i j) (* (matrix-ref a i k) (matrix-ref b k j))))))))))",
  )

  // Identity * [[1,2],[3,4]] = [[1,2],[3,4]]
  sample_eval(ctx, "(define id2 (make-matrix 2 2 0))")
  sample_eval(ctx, "(matrix-set! id2 0 0 1)")
  sample_eval(ctx, "(matrix-set! id2 1 1 1)")
  sample_eval(ctx, "(define m1 (make-matrix 2 2 0))")
  sample_eval(ctx, "(matrix-set! m1 0 0 1)")
  sample_eval(ctx, "(matrix-set! m1 0 1 2)")
  sample_eval(ctx, "(matrix-set! m1 1 0 3)")
  sample_eval(ctx, "(matrix-set! m1 1 1 4)")
  sample_eval(ctx, "(define r (matrix-multiply id2 m1))")
  sample_assert_int(ctx, "(matrix-ref r 0 0)", 1)
  sample_assert_int(ctx, "(matrix-ref r 0 1)", 2)
  sample_assert_int(ctx, "(matrix-ref r 1 0)", 3)
  sample_assert_int(ctx, "(matrix-ref r 1 1)", 4)

  // [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]
  sample_eval(ctx, "(define m2 (make-matrix 2 2 0))")
  sample_eval(ctx, "(matrix-set! m2 0 0 5)")
  sample_eval(ctx, "(matrix-set! m2 0 1 6)")
  sample_eval(ctx, "(matrix-set! m2 1 0 7)")
  sample_eval(ctx, "(matrix-set! m2 1 1 8)")
  sample_eval(ctx, "(define r2 (matrix-multiply m1 m2))")
  sample_assert_int(ctx, "(matrix-ref r2 0 0)", 19)
  sample_assert_int(ctx, "(matrix-ref r2 0 1)", 22)
  sample_assert_int(ctx, "(matrix-ref r2 1 0)", 43)
  sample_assert_int(ctx, "(matrix-ref r2 1 1)", 50)

  // 4. Circular buffer
  sample_eval(ctx,
    "(define (make-ring-buffer cap) (let ((data (make-vector cap 0)) (head 0) (tail 0) (size 0)) (define (dispatch msg . args) (cond ((eq? msg 'enqueue) (if (= size cap) 'full (begin (vector-set! data tail (car args)) (set! tail (modulo (+ tail 1) cap)) (set! size (+ size 1)) 'ok))) ((eq? msg 'dequeue) (if (= size 0) 'empty (let ((val (vector-ref data head))) (set! head (modulo (+ head 1) cap)) (set! size (- size 1)) val))) ((eq? msg 'size) size) (else 'unknown))) dispatch))",
  )
  sample_eval(ctx, "(define rb (make-ring-buffer 3))")
  sample_eval(ctx, "(rb 'enqueue 10)")
  sample_eval(ctx, "(rb 'enqueue 20)")
  sample_eval(ctx, "(rb 'enqueue 30)")
  sample_assert_true(ctx, "(eq? (rb 'enqueue 40) 'full)")
  sample_assert_int(ctx, "(rb 'dequeue)", 10)
  sample_eval(ctx, "(rb 'enqueue 40)")
  sample_assert_int(ctx, "(rb 'dequeue)", 20)
  sample_assert_int(ctx, "(rb 'dequeue)", 30)
  sample_assert_int(ctx, "(rb 'dequeue)", 40)
  sample_assert_true(ctx, "(eq? (rb 'dequeue) 'empty)")

  // 5. list->vector and vector->list round-trip
  sample_assert_list_eq(ctx,
    "(vector->list (list->vector '(1 2 3 4 5)))",
    "'(1 2 3 4 5)",
  )

  // Combined verification
  sample_eval(ctx,
    "(define (vectors-check) (let ((v (vector 3 1 2))) (bubble-sort! v) (and (= (vector-ref v 0) 1) (= (vector-ref v 1) 2) (= (vector-ref v 2) 3))))",
  )
  sample_assert_true(ctx, "(vectors-check)")
}

// ============================================================
// samples/functional/functional.scm
// ============================================================

test "sample: functional" {
  let ctx = new_repl_context()

  // 1. fold-left and fold-right
  sample_assert_int(ctx, "(fold-left + 0 '(1 2 3 4 5))", 15)
  sample_assert_int(ctx, "(fold-left * 1 '(1 2 3 4 5))", 120)
  sample_assert_list_eq(ctx,
    "(fold-right cons '() '(1 2 3))",
    "'(1 2 3)",
  )
  sample_assert_list_eq(ctx,
    "(fold-left (lambda (acc x) (cons x acc)) '() '(1 2 3))",
    "'(3 2 1)",
  )

  // 2. Function composition and currying
  sample_eval(ctx,
    "(define (compose f g) (lambda (x) (f (g x))))",
  )
  sample_eval(ctx,
    "(define (curry f) (lambda (a) (lambda (b) (f a b))))",
  )
  sample_eval(ctx, "(define add1 (lambda (x) (+ x 1)))")
  sample_eval(ctx, "(define double (lambda (x) (* x 2)))")
  sample_assert_int(ctx, "((compose add1 double) 5)", 11)
  sample_assert_int(ctx, "((compose double add1) 5)", 12)
  sample_assert_int(ctx, "(((curry +) 3) 4)", 7)
  sample_assert_int(ctx, "(((curry *) 5) 6)", 30)

  // 3. Association list database
  sample_eval(ctx, "(define db '())")
  sample_eval(ctx,
    "(define (db-insert! key value) (set! db (cons (cons key value) db)))",
  )
  sample_eval(ctx,
    "(define (db-lookup key) (let ((entry (assoc key db))) (if entry (cdr entry) #f)))",
  )
  sample_eval(ctx,
    "(define (db-delete! key) (set! db (filter (lambda (entry) (not (equal? (car entry) key))) db)))",
  )
  sample_eval(ctx, "(db-insert! \"alice\" 30)")
  sample_eval(ctx, "(db-insert! \"bob\" 25)")
  sample_eval(ctx, "(db-insert! \"carol\" 35)")
  sample_assert_int(ctx, "(db-lookup \"bob\")", 25)
  sample_eval(ctx, "(db-delete! \"bob\")")
  sample_assert_false(ctx, "(db-lookup \"bob\")")
  sample_assert_int(ctx, "(db-lookup \"alice\")", 30)

  // 4. Member and memq
  sample_assert_list_eq(ctx, "(memq 'b '(a b c))", "'(b c)")
  sample_assert_false(ctx, "(memq 'd '(a b c))")
  sample_assert_list_eq(ctx, "(member \"b\" '(\"a\" \"b\" \"c\"))", "'(\"b\" \"c\")")

  // 5. Zip and unzip
  sample_eval(ctx,
    "(define (zip lst1 lst2) (if (or (null? lst1) (null? lst2)) '() (cons (list (car lst1) (car lst2)) (zip (cdr lst1) (cdr lst2)))))",
  )
  sample_assert_list_eq(ctx,
    "(zip '(1 2 3) '(a b c))",
    "'((1 a) (2 b) (3 c))",
  )

  // 6. Flatten nested lists
  sample_eval(ctx,
    "(define (flatten lst) (cond ((null? lst) '()) ((pair? (car lst)) (append (flatten (car lst)) (flatten (cdr lst)))) (else (cons (car lst) (flatten (cdr lst))))))",
  )
  sample_assert_list_eq(ctx,
    "(flatten '(1 (2 (3 4) 5) (6 7)))",
    "'(1 2 3 4 5 6 7)",
  )

  // 7. Quasiquote templates
  sample_eval(ctx, "(define x 10)")
  sample_eval(ctx, "(define items '(1 2 3))")
  sample_assert_list_eq(ctx, "`(a ,x b)", "'(a 10 b)")
  sample_assert_list_eq(ctx, "`(start ,@items end)", "'(start 1 2 3 end)")
  sample_eval(ctx,
    "(define (make-binding name val) `(,name . ,val))",
  )
  sample_assert_list_eq(ctx, "(make-binding 'x 42)", "'(x . 42)")

  // 8. Apply with multiple args
  sample_assert_int(ctx, "(apply + 1 2 '(3 4 5))", 15)
  sample_assert_list_eq(ctx, "(apply list 'a 'b '(c d))", "'(a b c d)")

  // Combined verification
  sample_eval(ctx,
    "(define (functional-check) (and (= (fold-left + 0 '(1 2 3 4 5)) 15) (= ((compose add1 double) 5) 11) (= (db-lookup \"alice\") 30) (equal? (flatten '(1 (2 3))) '(1 2 3)) (equal? `(a ,x) '(a 10))))",
  )
  sample_assert_true(ctx, "(functional-check)")
}

// ============================================================
// samples/dynamic/dynamic.scm
// ============================================================

test "sample: dynamic" {
  let ctx = new_repl_context()

  // 1. dynamic-wind basic: before/after ordering
  sample_eval(ctx, "(define log '())")
  sample_eval(ctx,
    "(define (log! msg) (set! log (cons msg log)))",
  )
  sample_eval(ctx,
    "(dynamic-wind (lambda () (log! 'before)) (lambda () (log! 'during) 42) (lambda () (log! 'after)))",
  )
  sample_assert_list_eq(ctx, "(reverse log)", "'(before during after)")

  // 2. Resource management pattern
  sample_eval(ctx, "(define resource-log '())")
  sample_eval(ctx,
    "(define (with-resource name thunk) (dynamic-wind (lambda () (set! resource-log (cons (list 'acquire name) resource-log))) thunk (lambda () (set! resource-log (cons (list 'release name) resource-log)))))",
  )
  sample_eval(ctx,
    "(with-resource 'file (lambda () (set! resource-log (cons '(use file) resource-log)) 'done))",
  )
  sample_assert_list_eq(ctx,
    "(reverse resource-log)",
    "'((acquire file) (use file) (release file))",
  )

  // 3. Nested dynamic-wind
  sample_eval(ctx, "(define nest-log '())")
  sample_eval(ctx,
    "(dynamic-wind (lambda () (set! nest-log (cons 'outer-in nest-log))) (lambda () (dynamic-wind (lambda () (set! nest-log (cons 'inner-in nest-log))) (lambda () (set! nest-log (cons 'body nest-log)) 99) (lambda () (set! nest-log (cons 'inner-out nest-log))))) (lambda () (set! nest-log (cons 'outer-out nest-log))))",
  )
  sample_assert_list_eq(ctx,
    "(reverse nest-log)",
    "'(outer-in inner-in body inner-out outer-out)",
  )

  // 4. Multiple values: values and call-with-values
  sample_eval(ctx,
    "(define (div-mod a b) (values (quotient a b) (remainder a b)))",
  )
  sample_eval(ctx,
    "(define (test-div-mod a b) (call-with-values (lambda () (div-mod a b)) (lambda (q r) (+ (* q b) r))))",
  )
  sample_assert_int(ctx, "(test-div-mod 17 5)", 17)
  sample_assert_int(ctx, "(test-div-mod 100 7)", 100)

  // 5. call-with-values for destructuring
  sample_eval(ctx,
    "(define (swap a b) (values b a))",
  )
  sample_eval(ctx,
    "(define (test-swap) (call-with-values (lambda () (swap 1 2)) (lambda (a b) (list a b))))",
  )
  sample_assert_list_eq(ctx, "(test-swap)", "'(2 1)")

  // 6. Single value passthrough
  sample_assert_int(ctx,
    "(call-with-values (lambda () 42) (lambda (x) (+ x 1)))",
    43,
  )

  // Combined verification
  sample_eval(ctx,
    "(define (dynamic-check) (and (equal? (reverse log) '(before during after)) (= (test-div-mod 17 5) 17) (equal? (test-swap) '(2 1)) (equal? (reverse nest-log) '(outer-in inner-in body inner-out outer-out))))",
  )
  sample_assert_true(ctx, "(dynamic-check)")
}
