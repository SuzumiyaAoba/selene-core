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

// ============================================================
// samples/symbolic/symbolic.scm
// Symbolic differentiation (SICP-style)
// ============================================================

test "sample: symbolic" {
  let ctx = new_repl_context()

  // --- Constructors and selectors ---
  sample_eval(ctx, "(define (make-sum a b) (list '+ a b))")
  sample_eval(ctx, "(define (make-product a b) (list '* a b))")
  sample_eval(ctx, "(define (make-power base exp) (list '** base exp))")

  sample_eval(ctx, "(define (sum? e) (and (pair? e) (eq? (car e) '+)))")
  sample_eval(ctx, "(define (product? e) (and (pair? e) (eq? (car e) '*)))")
  sample_eval(ctx, "(define (power? e) (and (pair? e) (eq? (car e) '**)))")

  sample_eval(ctx, "(define (addend e) (cadr e))")
  sample_eval(ctx, "(define (augend e) (caddr e))")
  sample_eval(ctx, "(define (multiplier e) (cadr e))")
  sample_eval(ctx, "(define (multiplicand e) (caddr e))")
  sample_eval(ctx, "(define (base e) (cadr e))")
  sample_eval(ctx, "(define (exponent e) (caddr e))")

  // --- Simplifying constructors ---
  sample_eval(ctx,
    "(define (simp-sum a b) (cond ((and (number? a) (number? b)) (+ a b)) ((and (number? a) (= a 0)) b) ((and (number? b) (= b 0)) a) (else (make-sum a b))))",
  )
  sample_eval(ctx,
    "(define (simp-product a b) (cond ((and (number? a) (number? b)) (* a b)) ((and (number? a) (= a 0)) 0) ((and (number? b) (= b 0)) 0) ((and (number? a) (= a 1)) b) ((and (number? b) (= b 1)) a) (else (make-product a b))))",
  )
  sample_eval(ctx,
    "(define (simp-power base exp) (cond ((and (number? exp) (= exp 0)) 1) ((and (number? exp) (= exp 1)) base) (else (make-power base exp))))",
  )

  // --- Derivative ---
  sample_eval(ctx,
    "(define (deriv exp var) (cond ((number? exp) 0) ((symbol? exp) (if (eq? exp var) 1 0)) ((sum? exp) (simp-sum (deriv (addend exp) var) (deriv (augend exp) var))) ((product? exp) (simp-sum (simp-product (multiplier exp) (deriv (multiplicand exp) var)) (simp-product (deriv (multiplier exp) var) (multiplicand exp)))) ((power? exp) (simp-product (simp-product (exponent exp) (simp-power (base exp) (simp-sum (exponent exp) -1))) (deriv (base exp) var))) (else (list 'deriv exp var))))",
  )

  // --- Test: d/dx(x) = 1 ---
  sample_assert_int(ctx, "(deriv 'x 'x)", 1)
  // --- Test: d/dx(y) = 0 ---
  sample_assert_int(ctx, "(deriv 'y 'x)", 0)
  // --- Test: d/dx(5) = 0 ---
  sample_assert_int(ctx, "(deriv 5 'x)", 0)
  // --- Test: d/dx(x + x) = 2 ---
  sample_assert_int(ctx, "(deriv '(+ x x) 'x)", 2)
  // --- Test: d/dx(x * y) = y ---
  sample_assert_list_eq(ctx,
    "(let ((r (deriv '(* x y) 'x))) (if (symbol? r) (list r) (list r)))",
    "(list (deriv '(* x y) 'x))",
  )

  // --- Test: d/dx(x * x) = (+ x x) ---
  sample_assert_list_eq(ctx, "(deriv '(* x x) 'x)", "'(+ x x)")

  // --- Test: d/dx(x^3) = (* 3 (** x 2)) ---
  sample_assert_list_eq(ctx, "(deriv '(** x 3) 'x)", "'(* 3 (** x 2))")

  // --- Expression evaluator for numeric checking ---
  sample_eval(ctx,
    "(define (eval-expr e env) (cond ((number? e) e) ((symbol? e) (let ((binding (assq e env))) (if binding (cdr binding) (error \"unbound\" e)))) ((sum? e) (+ (eval-expr (addend e) env) (eval-expr (augend e) env))) ((product? e) (* (eval-expr (multiplier e) env) (eval-expr (multiplicand e) env))) ((power? e) (let loop ((b (eval-expr (base e) env)) (n (eval-expr (exponent e) env)) (acc 1)) (if (= n 0) acc (loop b (- n 1) (* acc b))))) (else (error \"unknown expr\" e))))",
  )

  // --- Numerical verification: d/dx(x^3) at x=2 should be 12 ---
  sample_eval(ctx, "(define dx3 (deriv '(** x 3) 'x))")
  sample_assert_int(ctx, "(eval-expr dx3 '((x . 2)))", 12)

  // --- Numerical verification: d/dx(x^3 + 2*x) at x=3 ---
  // d/dx(x^3 + 2*x) = 3x^2 + 2 = 3*9 + 2 = 29
  sample_eval(ctx,
    "(define poly '(+ (** x 3) (* 2 x)))",
  )
  sample_eval(ctx, "(define dpoly (deriv poly 'x))")
  sample_assert_int(ctx, "(eval-expr dpoly '((x . 3)))", 29)

  // --- Symbolic manipulation: collect terms ---
  sample_eval(ctx,
    "(define (tree-size e) (if (pair? e) (+ 1 (tree-size (car e)) (tree-size (cdr e))) 1))",
  )
  sample_assert_true(ctx, "(> (tree-size dpoly) 1)")

  // --- Multi-variable: d/dy of (x * y + y^2) = x + 2y ---
  sample_eval(ctx,
    "(define expr-xy '(+ (* x y) (** y 2)))",
  )
  sample_eval(ctx, "(define dexpr-dy (deriv expr-xy 'y))")
  // At x=3, y=4: x + 2y = 3 + 8 = 11
  sample_assert_int(ctx, "(eval-expr dexpr-dy '((x . 3) (y . 4)))", 11)

  // --- Combined verification ---
  sample_eval(ctx,
    "(define (symbolic-check) (and (= (deriv 5 'x) 0) (= (deriv 'x 'x) 1) (= (deriv 'y 'x) 0) (= (deriv '(+ x x) 'x) 2) (equal? (deriv '(* x x) 'x) '(+ x x)) (= (eval-expr (deriv '(** x 3) 'x) '((x . 2))) 12) (= (eval-expr (deriv '(+ (** x 3) (* 2 x)) 'x) '((x . 3))) 29)))",
  )
  sample_assert_true(ctx, "(symbolic-check)")
}

// ============================================================
// samples/graph/graph.scm
// Graph algorithms using adjacency lists
// ============================================================

test "sample: graph" {
  let ctx = new_repl_context()

  // --- Graph representation: adjacency list as alist ---
  sample_eval(ctx,
    "(define (make-graph) '())",
  )
  sample_eval(ctx,
    "(define (add-edge graph from to) (let ((existing (assv from graph))) (if existing (map (lambda (entry) (if (eqv? (car entry) from) (cons from (cons to (cdr entry))) entry)) graph) (cons (list from to) graph))))",
  )
  sample_eval(ctx,
    "(define (neighbors graph node) (let ((entry (assv node graph))) (if entry (cdr entry) '())))",
  )

  // --- Build a test graph ---
  // 1->2, 1->3, 2->4, 3->4, 4->5, 2->5
  sample_eval(ctx,
    "(define g (add-edge (add-edge (add-edge (add-edge (add-edge (add-edge (make-graph) 1 2) 1 3) 2 4) 3 4) 4 5) 2 5))",
  )

  // Helper for boolean conversion from member
  sample_eval(ctx, "(define (member? item lst) (if (member item lst) #t #f))")

  // Test graph structure
  sample_assert_true(ctx, "(member? 2 (neighbors g 1))")
  sample_assert_true(ctx, "(member? 3 (neighbors g 1))")
  sample_assert_true(ctx, "(member? 4 (neighbors g 2))")
  sample_assert_true(ctx, "(member? 5 (neighbors g 4))")

  // --- DFS (depth-first search) ---
  sample_eval(ctx,
    "(define (dfs graph start) (let ((visited '())) (define (visit node) (if (member node visited) '() (begin (set! visited (cons node visited)) (for-each (lambda (n) (visit n)) (neighbors graph node))))) (visit start) (reverse visited)))",
  )
  // DFS from 1 should visit all nodes 1-5
  sample_eval(ctx, "(define dfs-result (dfs g 1))")
  sample_assert_int(ctx, "(length dfs-result)", 5)
  sample_assert_true(ctx, "(member? 1 dfs-result)")
  sample_assert_true(ctx, "(member? 5 dfs-result)")

  // --- BFS (breadth-first search) ---
  sample_eval(ctx,
    "(define (bfs graph start) (let ((visited '()) (queue (list start))) (define (process) (if (null? queue) (reverse visited) (let ((node (car queue))) (set! queue (cdr queue)) (if (member node visited) (process) (begin (set! visited (cons node visited)) (for-each (lambda (n) (if (not (member n visited)) (set! queue (append queue (list n))))) (neighbors graph node)) (process)))))) (process)))",
  )
  sample_eval(ctx, "(define bfs-result (bfs g 1))")
  sample_assert_int(ctx, "(length bfs-result)", 5)
  // BFS visits 1 first
  sample_assert_int(ctx, "(car bfs-result)", 1)

  // --- Reachability ---
  sample_eval(ctx,
    "(define (reachable? graph from to) (let ((visited '())) (define (search node) (cond ((eqv? node to) #t) ((member node visited) #f) (else (set! visited (cons node visited)) (let loop ((ns (neighbors graph node))) (cond ((null? ns) #f) ((search (car ns)) #t) (else (loop (cdr ns)))))))) (search from)))",
  )
  sample_assert_true(ctx, "(reachable? g 1 5)")
  sample_assert_true(ctx, "(reachable? g 1 4)")
  sample_assert_true(ctx, "(reachable? g 2 5)")
  sample_assert_false(ctx, "(reachable? g 5 1)")

  // --- Topological sort (Kahn's algorithm) ---
  // DAG: a->b, a->c, b->d, c->d
  sample_eval(ctx,
    "(define dag (add-edge (add-edge (add-edge (add-edge (make-graph) 'a 'b) 'a 'c) 'b 'd) 'c 'd))",
  )

  sample_eval(ctx,
    "(define (all-nodes graph) (let ((nodes '())) (for-each (lambda (entry) (if (not (member (car entry) nodes)) (set! nodes (cons (car entry) nodes))) (for-each (lambda (n) (if (not (member n nodes)) (set! nodes (cons n nodes)))) (cdr entry))) graph) nodes))",
  )

  sample_eval(ctx,
    "(define (in-degree-remaining g node rem) (let ((count 0)) (for-each (lambda (entry) (if (not (member (car entry) rem)) (for-each (lambda (n) (if (eqv? n node) (set! count (+ count 1)))) (cdr entry)))) g) count))",
  )

  sample_eval(ctx,
    "(define (topo-sort graph) (let ((nodes (all-nodes graph)) (result '()) (removed '())) (define (find-zero-in) (let loop ((ns nodes)) (cond ((null? ns) #f) ((member (car ns) removed) (loop (cdr ns))) ((= (in-degree-remaining graph (car ns) removed) 0) (car ns)) (else (loop (cdr ns)))))) (let loop () (let ((node (find-zero-in))) (if node (begin (set! result (cons node result)) (set! removed (cons node removed)) (loop)) (reverse result))))))",
  )

  // --- Helper: list-index ---
  sample_eval(ctx,
    "(define (list-index lst item) (let loop ((l lst) (i 0)) (cond ((null? l) #f) ((eqv? (car l) item) i) (else (loop (cdr l) (+ i 1))))))",
  )

  sample_eval(ctx, "(define topo-result (topo-sort dag))")
  sample_assert_int(ctx, "(length topo-result)", 4)
  // 'a' must come before 'b' and 'c'; 'd' must come last
  sample_assert_true(ctx,
    "(let ((pos-a (list-index topo-result 'a)) (pos-d (list-index topo-result 'd))) (and pos-a pos-d (< pos-a pos-d)))",
  )

  // --- Cycle detection ---
  sample_eval(ctx,
    "(define (has-cycle? graph) (let ((visited '()) (in-stack '())) (define (visit node) (cond ((member node in-stack) #t) ((member node visited) #f) (else (set! visited (cons node visited)) (set! in-stack (cons node in-stack)) (let ((result (let loop ((ns (neighbors graph node))) (cond ((null? ns) #f) ((visit (car ns)) #t) (else (loop (cdr ns))))))) (set! in-stack (let remove-one ((l in-stack)) (cond ((null? l) '()) ((eqv? (car l) node) (cdr l)) (else (cons (car l) (remove-one (cdr l))))))) result)))) (let loop ((nodes (all-nodes graph))) (cond ((null? nodes) #f) ((visit (car nodes)) #t) (else (loop (cdr nodes)))))))",
  )

  // DAG has no cycle
  sample_assert_false(ctx, "(has-cycle? dag)")

  // Graph with cycle: a->b, b->c, c->a
  sample_eval(ctx,
    "(define cyclic (add-edge (add-edge (add-edge (make-graph) 'a 'b) 'b 'c) 'c 'a))",
  )
  sample_assert_true(ctx, "(has-cycle? cyclic)")

  // --- Path finding ---
  sample_eval(ctx,
    "(define (find-path graph from to) (let ((visited '())) (define (search node path) (cond ((eqv? node to) (reverse (cons node path))) ((member node visited) #f) (else (set! visited (cons node visited)) (let loop ((ns (neighbors graph node))) (cond ((null? ns) #f) (else (let ((result (search (car ns) (cons node path)))) (if result result (loop (cdr ns)))))))))) (search from '())))",
  )
  sample_eval(ctx, "(define path-1-5 (find-path g 1 5))")
  sample_assert_true(ctx, "(list? path-1-5)")
  sample_assert_int(ctx, "(car path-1-5)", 1)
  sample_assert_int(ctx, "(car (reverse path-1-5))", 5)

  // --- Combined verification ---
  sample_eval(ctx,
    "(define (graph-check) (and (= (length (dfs g 1)) 5) (= (length (bfs g 1)) 5) (reachable? g 1 5) (not (reachable? g 5 1)) (not (has-cycle? dag)) (has-cycle? cyclic) (list? (find-path g 1 5))))",
  )
  sample_assert_true(ctx, "(graph-check)")
}

// ============================================================
// samples/interpreter/interpreter.scm
// Mini language interpreter (metacircular-style)
// ============================================================

test "sample: interpreter" {
  let ctx = new_repl_context()

  // --- Environment ---
  sample_eval(ctx,
    "(define (mini-env-empty) '())",
  )
  sample_eval(ctx,
    "(define (mini-env-extend env names vals) (if (null? names) env (cons (cons (car names) (car vals)) (mini-env-extend env (cdr names) (cdr vals)))))",
  )
  sample_eval(ctx,
    "(define (mini-env-lookup env name) (cond ((null? env) (error \"mini: unbound variable\" name)) ((eq? (caar env) name) (cdar env)) (else (mini-env-lookup (cdr env) name))))",
  )

  // --- Values: numbers, booleans, closures, builtins ---
  sample_eval(ctx,
    "(define (mini-closure? v) (and (pair? v) (eq? (car v) 'closure)))",
  )
  sample_eval(ctx,
    "(define (make-mini-closure params body env) (list 'closure params body env))",
  )

  // --- Builtins ---
  sample_eval(ctx,
    "(define mini-builtins (list (cons '+ (lambda (args) (+ (car args) (cadr args)))) (cons '- (lambda (args) (- (car args) (cadr args)))) (cons '* (lambda (args) (* (car args) (cadr args)))) (cons '/ (lambda (args) (/ (car args) (cadr args)))) (cons '= (lambda (args) (= (car args) (cadr args)))) (cons '< (lambda (args) (< (car args) (cadr args)))) (cons '> (lambda (args) (> (car args) (cadr args)))) (cons 'zero? (lambda (args) (= (car args) 0))) (cons 'not (lambda (args) (not (car args))))))",
  )
  sample_eval(ctx,
    "(define (mini-lookup-builtin name) (let ((entry (assq name mini-builtins))) (if entry (cdr entry) #f)))",
  )

  // --- Evaluator ---
  sample_eval(ctx,
    "(define (mini-eval expr env) (cond ((number? expr) expr) ((boolean? expr) expr) ((symbol? expr) (mini-env-lookup env expr)) ((pair? expr) (let ((op (car expr))) (cond ((eq? op 'quote) (cadr expr)) ((eq? op 'if) (if (mini-eval (cadr expr) env) (mini-eval (caddr expr) env) (if (null? (cdr (cdr (cdr expr)))) #f (mini-eval (car (cdr (cdr (cdr expr)))) env)))) ((eq? op 'lambda) (make-mini-closure (cadr expr) (caddr expr) env)) ((eq? op 'let) (let ((bindings (cadr expr)) (body (caddr expr))) (let ((names (map car bindings)) (vals (map (lambda (b) (mini-eval (cadr b) env)) bindings))) (mini-eval body (mini-env-extend env names vals))))) ((eq? op 'begin) (let loop ((exprs (cdr expr)) (result #f)) (if (null? exprs) result (loop (cdr exprs) (mini-eval (car exprs) env))))) (else (let ((func (mini-eval op env)) (args (map (lambda (a) (mini-eval a env)) (cdr expr)))) (mini-apply func args)))))) (else (error \"mini: unknown expression\" expr))))",
  )

  // --- Apply ---
  sample_eval(ctx,
    "(define (mini-apply func args) (cond ((procedure? func) (func args)) ((mini-closure? func) (let ((params (cadr func)) (body (caddr func)) (clo-env (car (cdr (cdr (cdr func)))))) (mini-eval body (mini-env-extend clo-env params args)))) (else (error \"mini: not a function\" func))))",
  )

  // --- Initial environment with builtins ---
  sample_eval(ctx,
    "(define (mini-initial-env) (map (lambda (b) (cons (car b) (cdr b))) mini-builtins))",
  )

  // --- Test: basic arithmetic ---
  sample_assert_int(ctx,
    "(mini-eval '(+ 1 2) (mini-initial-env))",
    3,
  )
  sample_assert_int(ctx,
    "(mini-eval '(* 3 4) (mini-initial-env))",
    12,
  )
  sample_assert_int(ctx,
    "(mini-eval '(- 10 3) (mini-initial-env))",
    7,
  )

  // --- Test: nested expressions ---
  sample_assert_int(ctx,
    "(mini-eval '(+ (* 2 3) (- 10 4)) (mini-initial-env))",
    12,
  )

  // --- Test: if expression ---
  sample_assert_int(ctx,
    "(mini-eval '(if (< 1 2) 10 20) (mini-initial-env))",
    10,
  )
  sample_assert_int(ctx,
    "(mini-eval '(if (> 1 2) 10 20) (mini-initial-env))",
    20,
  )

  // --- Test: lambda and application ---
  sample_assert_int(ctx,
    "(mini-eval '((lambda (x) (+ x 1)) 5) (mini-initial-env))",
    6,
  )
  sample_assert_int(ctx,
    "(mini-eval '((lambda (x y) (+ x y)) 3 4) (mini-initial-env))",
    7,
  )

  // --- Test: let expressions ---
  sample_assert_int(ctx,
    "(mini-eval '(let ((x 10) (y 20)) (+ x y)) (mini-initial-env))",
    30,
  )

  // --- Test: factorial (recursive via Y-combinator style) ---
  // Since our mini-language doesn't have define/letrec, we use a self-application trick
  sample_eval(ctx,
    "(define fact-program '(let ((fact-helper (lambda (self n) (if (= n 0) 1 (* n (self self (- n 1))))))) (fact-helper fact-helper 10)))",
  )
  sample_assert_int(ctx,
    "(mini-eval fact-program (mini-initial-env))",
    3628800,
  )

  // --- Test: fibonacci (via self-application) ---
  sample_eval(ctx,
    "(define fib-program '(let ((fib-helper (lambda (self n) (if (< n 2) n (+ (self self (- n 1)) (self self (- n 2))))))) (fib-helper fib-helper 10)))",
  )
  sample_assert_int(ctx,
    "(mini-eval fib-program (mini-initial-env))",
    55,
  )

  // --- Test: higher-order function ---

  // --- Test: begin expression ---
  sample_assert_int(ctx,
    "(mini-eval '(begin 1 2 3) (mini-initial-env))",
    3,
  )
  sample_assert_int(ctx,
    "(mini-eval '(begin (+ 1 2) (* 3 4)) (mini-initial-env))",
    12,
  )

  // --- Test: quote ---
  sample_assert_true(ctx,
    "(eq? (mini-eval '(quote hello) (mini-initial-env)) 'hello)",
  )

  // --- Test: complex nested computation ---
  // sum of 1 to n via self-application
  sample_eval(ctx,
    "(define sum-program '(let ((sum-helper (lambda (self n) (if (= n 0) 0 (+ n (self self (- n 1))))))) (sum-helper sum-helper 100)))",
  )
  sample_assert_int(ctx,
    "(mini-eval sum-program (mini-initial-env))",
    5050,
  )

  // --- Test: boolean operations ---
  sample_assert_true(ctx,
    "(mini-eval '(zero? 0) (mini-initial-env))",
  )
  sample_assert_false(ctx,
    "(mini-eval '(zero? 5) (mini-initial-env))",
  )
  sample_assert_true(ctx,
    "(mini-eval '(not (> 1 2)) (mini-initial-env))",
  )

  // --- Test: closure captures environment ---
  sample_assert_int(ctx,
    "(mini-eval '(let ((x 10)) ((lambda (y) (+ x y)) 20)) (mini-initial-env))",
    30,
  )
  // Nested closures
  sample_assert_int(ctx,
    "(mini-eval '(let ((add (lambda (x) (lambda (y) (+ x y))))) ((add 3) 4)) (mini-initial-env))",
    7,
  )

  // --- Combined verification ---
  sample_eval(ctx,
    "(define (interpreter-check) (let ((env (mini-initial-env))) (and (= (mini-eval '(+ 1 2) env) 3) (= (mini-eval '(if (< 1 2) 10 20) env) 10) (= (mini-eval '((lambda (x) (+ x 1)) 5) env) 6) (= (mini-eval '(let ((x 10)) (+ x 5)) env) 15) (= (mini-eval fact-program env) 3628800) (= (mini-eval fib-program env) 55) (= (mini-eval sum-program env) 5050) (= (mini-eval '(let ((add (lambda (x) (lambda (y) (+ x y))))) ((add 3) 4)) env) 7))))",
  )
  sample_assert_true(ctx, "(interpreter-check)")
}

// ============================================================
// samples/huffman/huffman.scm
// Huffman coding: tree construction, encoding, decoding
// ============================================================

test "sample: huffman" {
  let ctx = new_repl_context()

  // Tree representation
  sample_eval(ctx, "(define (make-leaf symbol weight) (list 'leaf symbol weight))")
  sample_eval(ctx, "(define (leaf? tree) (eq? (car tree) 'leaf))")
  sample_eval(ctx, "(define (leaf-symbol tree) (cadr tree))")
  sample_eval(ctx, "(define (leaf-weight tree) (caddr tree))")
  sample_eval(ctx,
    "(define (make-tree left right) (list 'node left right (append (tree-symbols left) (tree-symbols right)) (+ (tree-weight left) (tree-weight right))))",
  )
  sample_eval(ctx, "(define (tree-left tree) (cadr tree))")
  sample_eval(ctx, "(define (tree-right tree) (caddr tree))")
  sample_eval(ctx,
    "(define (tree-symbols tree) (if (leaf? tree) (list (leaf-symbol tree)) (car (cdr (cdr (cdr tree))))))",
  )
  sample_eval(ctx,
    "(define (tree-weight tree) (if (leaf? tree) (leaf-weight tree) (car (cdr (cdr (cdr (cdr tree)))))))",
  )

  // Tree construction
  sample_eval(ctx,
    "(define (adjoin-set tree set) (cond ((null? set) (list tree)) ((< (tree-weight tree) (tree-weight (car set))) (cons tree set)) (else (cons (car set) (adjoin-set tree (cdr set))))))",
  )
  sample_eval(ctx,
    "(define (make-leaf-set pairs) (if (null? pairs) '() (adjoin-set (make-leaf (caar pairs) (cdar pairs)) (make-leaf-set (cdr pairs)))))",
  )
  sample_eval(ctx,
    "(define (build-huffman-tree pairs) (let ((leaves (make-leaf-set pairs))) (define (merge set) (if (null? (cdr set)) (car set) (let ((new-tree (make-tree (car set) (cadr set)))) (merge (adjoin-set new-tree (cdr (cdr set))))))) (merge leaves)))",
  )

  // Encoding
  sample_eval(ctx,
    "(define (encode-symbol symbol tree) (cond ((leaf? tree) (if (eq? symbol (leaf-symbol tree)) '() #f)) (else (let ((left-result (encode-symbol symbol (tree-left tree)))) (if left-result (cons 0 left-result) (let ((right-result (encode-symbol symbol (tree-right tree)))) (if right-result (cons 1 right-result) #f)))))))",
  )
  sample_eval(ctx,
    "(define (encode message tree) (if (null? message) '() (append (encode-symbol (car message) tree) (encode (cdr message) tree))))",
  )

  // Decoding
  sample_eval(ctx,
    "(define (decode bits tree) (define (decode-1 bits current) (if (leaf? current) (cons (leaf-symbol current) (decode-1 bits tree)) (if (null? bits) '() (if (= (car bits) 0) (decode-1 (cdr bits) (tree-left current)) (decode-1 (cdr bits) (tree-right current)))))) (decode-1 bits tree))",
  )

  // Build sample tree
  sample_eval(ctx, "(define sample-pairs '((a . 8) (b . 3) (c . 1) (d . 1) (e . 1) (f . 1) (g . 1) (h . 1)))")
  sample_eval(ctx, "(define sample-tree (build-huffman-tree sample-pairs))")

  // Test: 'a' has highest frequency => shortest code
  sample_assert_int(ctx, "(length (encode-symbol 'a sample-tree))", 1)

  // Test: round-trip encode/decode
  sample_eval(ctx, "(define sample-message '(a b a c a d a e))")
  sample_eval(ctx, "(define sample-bits (encode sample-message sample-tree))")
  sample_assert_list_eq(ctx, "(decode sample-bits sample-tree)", "'(a b a c a d a e)")

  // Test: roundtrip helper
  sample_eval(ctx, "(define (roundtrip msg tree) (equal? (decode (encode msg tree) tree) msg))")
  sample_assert_true(ctx, "(roundtrip '(a b c d e f g h) sample-tree)")
  sample_assert_true(ctx, "(roundtrip '(a a a b b c) sample-tree)")
  sample_assert_true(ctx, "(roundtrip '(h g f e d c b a) sample-tree)")

  // Test: encoding is more compact than fixed-width for skewed frequencies
  sample_assert_true(ctx, "(< (length sample-bits) (* 3 (length sample-message)))")

  // Combined verification
  sample_eval(ctx,
    "(define (huffman-check) (and (equal? (decode sample-bits sample-tree) sample-message) (= (length (encode-symbol 'a sample-tree)) 1) (roundtrip '(a b c d e f g h) sample-tree) (roundtrip '(a a a b b c) sample-tree) (< (length sample-bits) (* 3 (length sample-message)))))",
  )
  sample_assert_true(ctx, "(huffman-check)")
}

// ============================================================
// samples/matrix/matrix.scm
// Matrix operations using nested lists
// ============================================================

test "sample: matrix" {
  let ctx = new_repl_context()

  // Construction
  sample_eval(ctx,
    "(define (make-matrix m n val) (let loop-rows ((i 0) (rows '())) (if (= i m) (reverse rows) (loop-rows (+ i 1) (cons (let loop-cols ((j 0) (cols '())) (if (= j n) (reverse cols) (loop-cols (+ j 1) (cons val cols)))) rows)))))",
  )
  sample_eval(ctx,
    "(define (identity-matrix n) (let loop-rows ((i 0) (rows '())) (if (= i n) (reverse rows) (loop-rows (+ i 1) (cons (let loop-cols ((j 0) (cols '())) (if (= j n) (reverse cols) (loop-cols (+ j 1) (cons (if (= i j) 1 0) cols)))) rows)))))",
  )

  // Accessors
  sample_eval(ctx, "(define (matrix-ref mat i j) (list-ref (list-ref mat i) j))")
  sample_eval(ctx, "(define (matrix-rows mat) (length mat))")
  sample_eval(ctx, "(define (matrix-cols mat) (length (car mat)))")

  // Element-wise operations
  sample_eval(ctx, "(define (matrix-map f mat) (map (lambda (row) (map f row)) mat))")
  sample_eval(ctx, "(define (matrix-zip-with f mat1 mat2) (map (lambda (r1 r2) (map f r1 r2)) mat1 mat2))")
  sample_eval(ctx, "(define (matrix-add mat1 mat2) (matrix-zip-with + mat1 mat2))")
  sample_eval(ctx, "(define (matrix-sub mat1 mat2) (matrix-zip-with - mat1 mat2))")
  sample_eval(ctx, "(define (matrix-scale k mat) (matrix-map (lambda (x) (* k x)) mat))")

  // Transpose
  sample_eval(ctx,
    "(define (transpose mat) (if (null? (car mat)) '() (cons (map car mat) (transpose (map cdr mat)))))",
  )

  // Dot product and matrix multiply
  sample_eval(ctx, "(define (dot-product v1 v2) (fold-left + 0 (map * v1 v2)))")
  sample_eval(ctx,
    "(define (matrix-mul mat1 mat2) (let ((cols2 (transpose mat2))) (map (lambda (row1) (map (lambda (col2) (dot-product row1 col2)) cols2)) mat1)))",
  )

  // Determinant
  sample_eval(ctx,
    "(define (remove-col mat j) (map (lambda (row) (let loop ((k 0) (cells row) (result '())) (cond ((null? cells) (reverse result)) ((= k j) (loop (+ k 1) (cdr cells) result)) (else (loop (+ k 1) (cdr cells) (cons (car cells) result)))))) mat))",
  )
  sample_eval(ctx,
    "(define (determinant mat) (let ((n (matrix-rows mat))) (cond ((= n 1) (matrix-ref mat 0 0)) ((= n 2) (- (* (matrix-ref mat 0 0) (matrix-ref mat 1 1)) (* (matrix-ref mat 0 1) (matrix-ref mat 1 0)))) (else (let ((first-row (car mat)) (rest (cdr mat))) (let loop ((j 0) (cells first-row) (sign 1) (sum 0)) (if (null? cells) sum (loop (+ j 1) (cdr cells) (- sign) (+ sum (* sign (car cells) (determinant (remove-col rest j))))))))))))",
  )

  // Test: identity matrix
  sample_assert_list_eq(ctx, "(identity-matrix 3)", "'((1 0 0) (0 1 0) (0 0 1))")

  // Test: zero matrix
  sample_assert_list_eq(ctx, "(make-matrix 2 3 0)", "'((0 0 0) (0 0 0))")

  // Test: addition
  sample_assert_list_eq(ctx, "(matrix-add '((1 2) (3 4)) '((5 6) (7 8)))", "'((6 8) (10 12))")

  // Test: subtraction
  sample_assert_list_eq(ctx, "(matrix-sub '((5 6) (7 8)) '((1 2) (3 4)))", "'((4 4) (4 4))")

  // Test: scalar multiply
  sample_assert_list_eq(ctx, "(matrix-scale 2 '((1 2) (3 4)))", "'((2 4) (6 8))")

  // Test: transpose
  sample_assert_list_eq(ctx, "(transpose '((1 2 3) (4 5 6)))", "'((1 4) (2 5) (3 6))")

  // Test: dot product
  sample_assert_int(ctx, "(dot-product '(1 2 3) '(4 5 6))", 32)

  // Test: matrix multiply
  sample_assert_list_eq(ctx, "(matrix-mul '((1 2) (3 4)) '((5 6) (7 8)))", "'((19 22) (43 50))")

  // Test: identity is multiplicative identity
  sample_eval(ctx, "(define a '((1 2) (3 4)))")
  sample_eval(ctx, "(define id2 (identity-matrix 2))")
  sample_assert_list_eq(ctx, "(matrix-mul a id2)", "'((1 2) (3 4))")
  sample_assert_list_eq(ctx, "(matrix-mul id2 a)", "'((1 2) (3 4))")

  // Test: determinant
  sample_assert_int(ctx, "(determinant '((1 2) (3 4)))", -2)
  sample_assert_int(ctx, "(determinant '((1 2 3) (4 5 6) (7 8 0)))", 27)

  // Combined verification
  sample_eval(ctx,
    "(define (matrix-check) (and (equal? (matrix-add '((1 2) (3 4)) '((5 6) (7 8))) '((6 8) (10 12))) (equal? (transpose '((1 2) (3 4))) '((1 3) (2 4))) (equal? (matrix-mul '((1 2) (3 4)) '((5 6) (7 8))) '((19 22) (43 50))) (equal? (matrix-mul a id2) a) (= (determinant '((1 2) (3 4))) -2) (= (determinant '((1 2 3) (4 5 6) (7 8 0))) 27) (= (dot-product '(1 2 3) '(4 5 6)) 32)))",
  )
  sample_assert_true(ctx, "(matrix-check)")
}

// ============================================================
// samples/state-machine/state-machine.scm
// Finite state machine simulator
// ============================================================

test "sample: state-machine" {
  let ctx = new_repl_context()

  // DFA construction: (dfa start-state accept-states transitions)
  // transitions: ((state . ((input . next) ...)) ...)
  sample_eval(ctx, "(define (make-dfa start accepts transitions) (list 'dfa start accepts transitions))")
  sample_eval(ctx, "(define (dfa-start dfa) (cadr dfa))")
  sample_eval(ctx, "(define (dfa-accepts dfa) (caddr dfa))")
  sample_eval(ctx, "(define (dfa-transitions dfa) (car (cdr (cdr (cdr dfa)))))")

  // Transition lookup
  sample_eval(ctx,
    "(define (find-entry key alist) (cond ((null? alist) #f) ((equal? (caar alist) key) (cdar alist)) (else (find-entry key (cdr alist)))))",
  )
  sample_eval(ctx,
    "(define (dfa-next dfa state input) (let ((st (find-entry state (dfa-transitions dfa)))) (if st (find-entry input st) #f)))",
  )
  sample_eval(ctx,
    "(define (dfa-accept? dfa state) (if (member state (dfa-accepts dfa)) #t #f))",
  )

  // Run DFA on a list of inputs (numbers)
  sample_eval(ctx,
    "(define (dfa-run dfa inputs) (let loop ((st (dfa-start dfa)) (rem inputs)) (cond ((not st) #f) ((null? rem) (dfa-accept? dfa st)) (else (loop (dfa-next dfa st (car rem)) (cdr rem))))))",
  )

  // Convert string to list of integer char codes
  sample_eval(ctx,
    "(define (str->ints s) (map char->integer (string->list s)))",
  )
  sample_eval(ctx,
    "(define (dfa-run-str dfa s) (dfa-run dfa (str->ints s)))",
  )

  // Trace: return list of visited states
  sample_eval(ctx,
    "(define (dfa-trace dfa inputs) (let loop ((st (dfa-start dfa)) (rem inputs) (path (list (dfa-start dfa)))) (cond ((null? rem) (reverse path)) (else (let ((nx (dfa-next dfa st (car rem)))) (if nx (loop nx (cdr rem) (cons nx path)) (reverse (cons 'stuck path))))))))",
  )

  // --- Example 1: Binary strings divisible by 3 ---
  // Use integer inputs: 0=digit-zero, 1=digit-one
  sample_eval(ctx,
    "(define div3 (make-dfa 'r0 '(r0) (list (cons 'r0 (list (cons 0 'r0) (cons 1 'r1))) (cons 'r1 (list (cons 0 'r2) (cons 1 'r0))) (cons 'r2 (list (cons 0 'r1) (cons 1 'r2))))))",
  )
  // Run with explicit numeric lists
  sample_assert_true(ctx, "(dfa-run div3 '(0))")        // 0 div 3
  sample_assert_true(ctx, "(dfa-run div3 '(1 1 0))")    // 6 div 3
  sample_assert_true(ctx, "(dfa-run div3 '(1 0 0 1))")  // 9 div 3
  sample_assert_false(ctx, "(dfa-run div3 '(1 0 1))")   // 5 not div 3
  sample_assert_false(ctx, "(dfa-run div3 '(1 0))")     // 2 not div 3

  // Trace
  sample_assert_list_eq(ctx, "(dfa-trace div3 '(1 1 0))", "'(r0 r1 r0 r0)")

  // --- Example 2: Strings ending with "ab" ---
  // Use char codes: a=97, b=98
  sample_eval(ctx,
    "(define ends-ab (make-dfa 'q0 '(q2) (list (cons 'q0 (list (cons 97 'q1) (cons 98 'q0))) (cons 'q1 (list (cons 97 'q1) (cons 98 'q2))) (cons 'q2 (list (cons 97 'q1) (cons 98 'q0))))))",
  )
  sample_assert_true(ctx, "(dfa-run-str ends-ab \"ab\")")
  sample_assert_true(ctx, "(dfa-run-str ends-ab \"aab\")")
  sample_assert_false(ctx, "(dfa-run-str ends-ab \"abc\")")
  sample_assert_false(ctx, "(dfa-run-str ends-ab \"ba\")")

  // --- Example 3: Even number of zeros ---
  sample_eval(ctx,
    "(define even-z (make-dfa 'ev '(ev) (list (cons 'ev (list (cons 0 'od) (cons 1 'ev))) (cons 'od (list (cons 0 'ev) (cons 1 'od))))))",
  )
  sample_assert_true(ctx, "(dfa-run even-z '())")         // zero 0s (even)
  sample_assert_true(ctx, "(dfa-run even-z '(1 1))")      // zero 0s
  sample_assert_true(ctx, "(dfa-run even-z '(1 0 0 1))")  // two 0s
  sample_assert_false(ctx, "(dfa-run even-z '(1 0 0 0))") // three 0s

  // --- Composition ---
  sample_eval(ctx,
    "(define (all-accept? dfas inputs) (let loop ((ds dfas)) (cond ((null? ds) #t) ((not (dfa-run (car ds) inputs)) #f) (else (loop (cdr ds))))))",
  )
  sample_eval(ctx,
    "(define (any-accept? dfas inputs) (let loop ((ds dfas)) (cond ((null? ds) #f) ((dfa-run (car ds) inputs) #t) (else (loop (cdr ds))))))",
  )
  // '(1 1 0) = 6: div3 accepts, even-z does not (one zero)
  sample_assert_false(ctx, "(all-accept? (list div3 even-z) '(1 1 0))")
  sample_assert_true(ctx, "(any-accept? (list div3 even-z) '(1 1 0))")
  // '(1 0 0 1) = 9: div3 accepts, even-z accepts (two zeros)
  sample_assert_true(ctx, "(all-accept? (list div3 even-z) '(1 0 0 1))")

  // --- Combined verification ---
  sample_eval(ctx,
    "(define (state-machine-check) (and (dfa-run div3 '(1 1 0)) (not (dfa-run div3 '(1 0 1))) (dfa-run-str ends-ab \"ab\") (not (dfa-run-str ends-ab \"ba\")) (dfa-run even-z '(1 0 0 1)) (not (dfa-run even-z '(1 0 0 0))) (equal? (dfa-trace div3 '(1 1 0)) '(r0 r1 r0 r0)) (all-accept? (list div3 even-z) '(1 0 0 1))))",
  )
  sample_assert_true(ctx, "(state-machine-check)")
}

// ============================================================
// samples/regexp/regexp.scm
// Simple regular expression matcher using S-expression patterns
// ============================================================

test "sample: regexp" {
  let ctx = new_repl_context()

  // Pattern constructors
  sample_eval(ctx, "(define (lit c) (list 'lit c))")
  sample_eval(ctx, "(define (any) '(any))")
  sample_eval(ctx, "(define (seq p1 p2) (list 'seq p1 p2))")
  sample_eval(ctx, "(define (alt p1 p2) (list 'alt p1 p2))")
  sample_eval(ctx, "(define (star p) (list 'star p))")
  sample_eval(ctx, "(define (plus p) (list 'plus p))")
  sample_eval(ctx, "(define (opt p) (list 'opt p))")

  // Pattern predicates
  sample_eval(ctx, "(define (lit? p) (and (pair? p) (eq? (car p) 'lit)))")
  sample_eval(ctx, "(define (any? p) (and (pair? p) (eq? (car p) 'any)))")
  sample_eval(ctx, "(define (seq? p) (and (pair? p) (eq? (car p) 'seq)))")
  sample_eval(ctx, "(define (alt? p) (and (pair? p) (eq? (car p) 'alt)))")
  sample_eval(ctx, "(define (star? p) (and (pair? p) (eq? (car p) 'star)))")
  sample_eval(ctx, "(define (plus? p) (and (pair? p) (eq? (car p) 'plus)))")
  sample_eval(ctx, "(define (opt? p) (and (pair? p) (eq? (car p) 'opt)))")

  // Matcher: returns list of possible remaining char lists after matching
  sample_eval(ctx,
    "(define (re-match pat chars) (cond ((lit? pat) (if (and (pair? chars) (char=? (car chars) (cadr pat))) (list (cdr chars)) '())) ((any? pat) (if (pair? chars) (list (cdr chars)) '())) ((seq? pat) (let ((after-p1 (re-match (cadr pat) chars))) (let loop ((remaining after-p1) (results '())) (if (null? remaining) results (loop (cdr remaining) (append results (re-match (caddr pat) (car remaining)))))))) ((alt? pat) (append (re-match (cadr pat) chars) (re-match (caddr pat) chars))) ((star? pat) (let ((sub (cadr pat))) (define (star-expand worklist results) (if (null? worklist) results (let ((c (car worklist)) (rest (cdr worklist))) (if (member c results) (star-expand rest results) (let ((matches (re-match sub c))) (star-expand (append rest matches) (cons c results))))))) (star-expand (list chars) '()))) ((plus? pat) (let ((sub (cadr pat))) (let ((first-matches (re-match sub chars))) (let loop ((remaining first-matches) (results '())) (if (null? remaining) results (loop (cdr remaining) (append results (re-match (star sub) (car remaining))))))))) ((opt? pat) (append (list chars) (re-match (cadr pat) chars))) (else '())))",
  )

  // Full match check
  sample_eval(ctx,
    "(define (re-full-match? pat str) (let ((chars (string->list str))) (let ((results (re-match pat chars))) (if (member '() results) #t #f))))",
  )

  // --- Test: literal sequence ab ---
  sample_eval(ctx, "(define pat-ab (seq (lit #\\a) (lit #\\b)))")
  sample_assert_true(ctx, "(re-full-match? pat-ab \"ab\")")
  sample_assert_false(ctx, "(re-full-match? pat-ab \"abc\")")
  sample_assert_false(ctx, "(re-full-match? pat-ab \"a\")")

  // --- Test: alternation a|b ---
  sample_eval(ctx, "(define pat-a-or-b (alt (lit #\\a) (lit #\\b)))")
  sample_assert_true(ctx, "(re-full-match? pat-a-or-b \"a\")")
  sample_assert_true(ctx, "(re-full-match? pat-a-or-b \"b\")")
  sample_assert_false(ctx, "(re-full-match? pat-a-or-b \"c\")")

  // --- Test: star a* ---
  sample_eval(ctx, "(define pat-a-star (star (lit #\\a)))")
  sample_assert_true(ctx, "(re-full-match? pat-a-star \"\")")
  sample_assert_true(ctx, "(re-full-match? pat-a-star \"aaa\")")
  sample_assert_false(ctx, "(re-full-match? pat-a-star \"ab\")")

  // --- Test: plus a+b ---
  sample_eval(ctx, "(define pat-a-plus-b (seq (plus (lit #\\a)) (lit #\\b)))")
  sample_assert_true(ctx, "(re-full-match? pat-a-plus-b \"ab\")")
  sample_assert_true(ctx, "(re-full-match? pat-a-plus-b \"aaab\")")
  sample_assert_false(ctx, "(re-full-match? pat-a-plus-b \"b\")")

  // --- Test: any character a.b ---
  sample_eval(ctx, "(define pat-a-dot-b (seq (lit #\\a) (seq (any) (lit #\\b))))")
  sample_assert_true(ctx, "(re-full-match? pat-a-dot-b \"axb\")")
  sample_assert_false(ctx, "(re-full-match? pat-a-dot-b \"ab\")")

  // --- Test: optional colou?r ---
  sample_eval(ctx,
    "(define pat-color (seq (lit #\\c) (seq (lit #\\o) (seq (lit #\\l) (seq (lit #\\o) (seq (opt (lit #\\u)) (lit #\\r)))))))",
  )
  sample_assert_true(ctx, "(re-full-match? pat-color \"color\")")
  sample_assert_true(ctx, "(re-full-match? pat-color \"colour\")")
  sample_assert_false(ctx, "(re-full-match? pat-color \"colouur\")")

  // --- Test: .* matches anything ---
  sample_eval(ctx, "(define pat-any-star (star (any)))")
  sample_assert_true(ctx, "(re-full-match? pat-any-star \"\")")
  sample_assert_true(ctx, "(re-full-match? pat-any-star \"hello\")")

  // --- Combined verification ---
  sample_eval(ctx,
    "(define (regexp-check) (and (re-full-match? pat-ab \"ab\") (not (re-full-match? pat-ab \"abc\")) (re-full-match? pat-a-or-b \"a\") (re-full-match? pat-a-or-b \"b\") (not (re-full-match? pat-a-or-b \"c\")) (re-full-match? pat-a-star \"\") (re-full-match? pat-a-star \"aaa\") (not (re-full-match? pat-a-star \"ab\")) (re-full-match? pat-a-plus-b \"aaab\") (not (re-full-match? pat-a-plus-b \"b\")) (re-full-match? pat-a-dot-b \"axb\") (re-full-match? pat-color \"color\") (re-full-match? pat-color \"colour\") (re-full-match? pat-any-star \"hello\")))",
  )
  sample_assert_true(ctx, "(regexp-check)")
}
