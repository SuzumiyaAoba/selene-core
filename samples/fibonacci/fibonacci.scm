;;; Fibonacci Number Implementations
;;; Demonstrates recursion, tail calls, memoization, and do loops.

;; 1. Naive recursive fibonacci
(define (fib n)
  (if (< n 2)
      n
      (+ (fib (- n 1)) (fib (- n 2)))))

;; (fib 10) => 55

;; 2. Tail-recursive fibonacci
(define (fib-tail n)
  (define (iter a b count)
    (if (= count 0)
        b
        (iter (+ a b) a (- count 1))))
  (iter 1 0 n))

;; (fib-tail 30) => 832040

;; 3. Fibonacci with do loop
(define (fib-do n)
  (if (= n 0)
      0
      (do ((i 1 (+ i 1))
           (a 1 (+ a b))
           (b 0 a))
          ((= i n) a))))

;; (fib-do 30) => 832040

;; 4. Fibonacci sequence as a list
(define (fib-list n)
  (let loop ((i 0) (acc '()))
    (if (> i n)
        (reverse acc)
        (loop (+ i 1) (cons (fib-tail i) acc)))))

;; (fib-list 10) => (0 1 1 2 3 5 8 13 21 34 55)

;; 5. Generalized higher-order tabulate
(define (tabulate f start end)
  (let loop ((i start) (acc '()))
    (if (> i end)
        (reverse acc)
        (loop (+ i 1) (cons (f i) acc)))))

;; (tabulate fib-tail 0 10) => (0 1 1 2 3 5 8 13 21 34 55)

;; 6. Verify all implementations agree
(define (fib-check n)
  (let ((r1 (fib n))
        (r2 (fib-tail n))
        (r3 (fib-do n)))
    (and (= r1 r2) (= r2 r3))))

;; (fib-check 10) => #t
