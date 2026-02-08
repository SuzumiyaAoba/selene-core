;;; Lazy Streams
;;; Demonstrates delay/force for infinite data structures.

;; --- Stream primitives ---

(define stream-null '())

(define (stream-null? s) (null? s))

(define-syntax stream-cons
  (syntax-rules ()
    ((stream-cons x s) (cons x (delay s)))))

(define (stream-car s) (car s))

(define (stream-cdr s) (force (cdr s)))

;; --- Stream operations ---

(define (stream-take n s)
  (if (or (= n 0) (stream-null? s))
      '()
      (cons (stream-car s)
            (stream-take (- n 1) (stream-cdr s)))))

(define (stream-map f s)
  (if (stream-null? s)
      stream-null
      (stream-cons (f (stream-car s))
                   (stream-map f (stream-cdr s)))))

(define (stream-filter pred s)
  (cond ((stream-null? s) stream-null)
        ((pred (stream-car s))
         (stream-cons (stream-car s)
                      (stream-filter pred (stream-cdr s))))
        (else (stream-filter pred (stream-cdr s)))))

(define (stream-zip-with f s1 s2)
  (if (or (stream-null? s1) (stream-null? s2))
      stream-null
      (stream-cons (f (stream-car s1) (stream-car s2))
                   (stream-zip-with f (stream-cdr s1) (stream-cdr s2)))))

;; --- Infinite streams ---

;; Natural numbers: 0, 1, 2, 3, ...
(define (integers-from n)
  (stream-cons n (integers-from (+ n 1))))

(define nats (integers-from 0))

;; (stream-take 5 nats) => (0 1 2 3 4)

;; Fibonacci stream: 0, 1, 1, 2, 3, 5, 8, ...
(define fibs
  (stream-cons 0
    (stream-cons 1
      (stream-zip-with + fibs (stream-cdr fibs)))))

;; (stream-take 10 fibs) => (0 1 1 2 3 5 8 13 21 34)

;; Filtering odd numbers from natural numbers
;; (stream-take 5 (stream-filter odd? (integers-from 0))) => (1 3 5 7 9)

;; --- Sieve of Eratosthenes ---

(define (sieve s)
  (stream-cons (stream-car s)
    (sieve (stream-filter
             (lambda (x) (not (= (remainder x (stream-car s)) 0)))
             (stream-cdr s)))))

(define primes (sieve (integers-from 2)))

;; (stream-take 10 primes) => (2 3 5 7 11 13 17 19 23 29)

;; --- Delay + lambda capturing from enclosing scope ---

(define (test-d4 s n)
  (delay (stream-filter (lambda (x) (> x n)) s)))

;; (stream-take 3 (force (test-d4 (integers-from 0) 5))) => (6 7 8)

;; --- Verify ---

(define (stream-check)
  (and (equal? (stream-take 5 nats) '(0 1 2 3 4))
       (equal? (stream-take 10 fibs) '(0 1 1 2 3 5 8 13 21 34))
       (equal? (stream-take 5 (stream-filter odd? (integers-from 0)))
               '(1 3 5 7 9))
       (equal? (stream-take 10 primes) '(2 3 5 7 11 13 17 19 23 29))))

;; (stream-check) => #t
