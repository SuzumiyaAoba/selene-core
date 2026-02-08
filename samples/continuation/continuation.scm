;;; Continuation Applications
;;; Demonstrates call/cc for non-local exit, exceptions, and tree traversal.

;; --- 1. Non-local exit (early return) ---

(define (find-first pred lst)
  (call/cc
    (lambda (return)
      (for-each (lambda (x)
                  (if (pred x) (return x)))
                lst)
      #f)))

;; (find-first even? '(1 3 5 4 7)) => 4
;; (find-first even? '(1 3 5 7))   => #f

;; --- 2. Exception handling with call/cc ---

(define (try thunk handler)
  (call/cc
    (lambda (exit)
      (let ((raise (lambda (err) (exit (handler err)))))
        (thunk raise)))))

(define (safe-divide a b)
  (try
    (lambda (raise)
      (if (= b 0)
          (raise "division by zero")
          (quotient a b)))
    (lambda (err) (string-append "Error: " err))))

;; (safe-divide 10 3) => 3
;; (safe-divide 10 0) => "Error: division by zero"

;; --- 3. Collect results with continuation ---

(define (collect-matches pred lst)
  (let ((results '()))
    (call/cc
      (lambda (done)
        (for-each
          (lambda (x)
            (if (pred x)
                (set! results (cons x results))))
          lst)
        (reverse results)))))

;; (collect-matches odd? '(1 2 3 4 5 6 7 8 9)) => (1 3 5 7 9)

;; --- 4. Tree traversal with early exit ---

;; A tree is either a number (leaf) or a list of subtrees (node).
;; tree-walk is a helper that traverses the tree, accumulating a sum.
;; If a negative number is encountered, abort immediately with the
;; partial sum computed so far.

(define (tree-walk t sum abort)
  (cond ((number? t)
         (if (< t 0)
             (abort sum)
             (+ sum t)))
        ((null? t) sum)
        (else
         (tree-walk (cdr t)
                    (tree-walk (car t) sum abort)
                    abort))))

(define (tree-sum-until-negative tree)
  (call/cc (lambda (abort)
    (tree-walk tree 0 abort))))

;; (tree-sum-until-negative '(1 (2 3) (4 (5 6)))) => 21
;; (tree-sum-until-negative '(1 (2 -1) (4 (5 6)))) => 3

;; --- 5. Range collection ---

(define (range-collect start end)
  (let loop ((i end) (result '()))
    (if (< i start)
        result
        (loop (- i 1) (cons i result)))))

;; (range-collect 1 5) => (1 2 3 4 5)

;; --- Verify ---

(define (continuation-check)
  (and (= (find-first even? '(1 3 5 4 7)) 4)
       (eq? (find-first even? '(1 3 5 7)) #f)
       (= (safe-divide 10 3) 3)
       (string=? (safe-divide 10 0) "Error: division by zero")
       (equal? (collect-matches odd? '(1 2 3 4 5 6 7 8 9))
               '(1 3 5 7 9))
       (= (tree-sum-until-negative '(1 (2 3) (4 (5 6)))) 21)
       (= (tree-sum-until-negative '(1 (2 -1) (4 (5 6)))) 3)
       (equal? (range-collect 1 5) '(1 2 3 4 5))))

;; (continuation-check) => #t
