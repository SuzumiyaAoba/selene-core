;;; Finite State Machine Simulator
;;; Demonstrates alist lookup, recursive state processing, and closures.
;;; DFA inputs can be any type (symbols, integers, characters).

;; --- DFA representation ---
;; A DFA is: (dfa start-state accept-states transitions)
;; transitions: ((state . ((input . next-state) ...)) ...)

(define (make-dfa start accepts transitions)
  (list 'dfa start accepts transitions))

(define (dfa-start dfa) (cadr dfa))
(define (dfa-accepts dfa) (caddr dfa))
(define (dfa-transitions dfa) (car (cdr (cdr (cdr dfa)))))

;; --- Transition lookup ---

(define (find-entry key alist)
  (cond ((null? alist) #f)
        ((equal? (caar alist) key) (cdar alist))
        (else (find-entry key (cdr alist)))))

(define (dfa-next dfa state input)
  (let ((st (find-entry state (dfa-transitions dfa))))
    (if st (find-entry input st) #f)))

(define (dfa-accept? dfa state)
  (if (member state (dfa-accepts dfa)) #t #f))

;; --- Run DFA on a list of inputs ---

(define (dfa-run dfa inputs)
  (let loop ((st (dfa-start dfa)) (rem inputs))
    (cond ((not st) #f)
          ((null? rem) (dfa-accept? dfa st))
          (else (loop (dfa-next dfa st (car rem))
                      (cdr rem))))))

;; --- Run DFA on a string (via char codes) ---

(define (str->ints s)
  (map char->integer (string->list s)))

(define (dfa-run-str dfa s)
  (dfa-run dfa (str->ints s)))

;; --- Trace: return list of visited states ---

(define (dfa-trace dfa inputs)
  (let loop ((st (dfa-start dfa))
             (rem inputs)
             (path (list (dfa-start dfa))))
    (cond ((null? rem) (reverse path))
          (else
           (let ((nx (dfa-next dfa st (car rem))))
             (if nx
                 (loop nx (cdr rem) (cons nx path))
                 (reverse (cons 'stuck path))))))))

;; ============================================================
;; Example 1: Binary numbers divisible by 3
;; States: r0 (rem 0), r1 (rem 1), r2 (rem 2)
;; Inputs: 0, 1 (integers)
;; ============================================================

(define div3
  (make-dfa 'r0 '(r0)
    (list (cons 'r0 (list (cons 0 'r0) (cons 1 'r1)))
          (cons 'r1 (list (cons 0 'r2) (cons 1 'r0)))
          (cons 'r2 (list (cons 0 'r1) (cons 1 'r2))))))

;; (dfa-run div3 '(1 1 0))   => #t  (110 = 6, divisible by 3)
;; (dfa-run div3 '(1 0 1))   => #f  (101 = 5, not divisible)
;; (dfa-trace div3 '(1 1 0)) => (r0 r1 r0 r0)

;; ============================================================
;; Example 2: Strings ending with "ab"
;; Uses char codes: a=97, b=98
;; ============================================================

(define ends-ab
  (make-dfa 'q0 '(q2)
    (list (cons 'q0 (list (cons 97 'q1) (cons 98 'q0)))
          (cons 'q1 (list (cons 97 'q1) (cons 98 'q2)))
          (cons 'q2 (list (cons 97 'q1) (cons 98 'q0))))))

;; (dfa-run-str ends-ab "ab")  => #t
;; (dfa-run-str ends-ab "abc") => #f

;; ============================================================
;; Example 3: Even number of zeros
;; Inputs: 0, 1 (integers)
;; ============================================================

(define even-z
  (make-dfa 'ev '(ev)
    (list (cons 'ev (list (cons 0 'od) (cons 1 'ev)))
          (cons 'od (list (cons 0 'ev) (cons 1 'od))))))

;; (dfa-run even-z '(1 0 0 1)) => #t  (two zeros)
;; (dfa-run even-z '(1 0 0 0)) => #f  (three zeros)

;; ============================================================
;; DFA Composition
;; ============================================================

(define (all-accept? dfas inputs)
  (let loop ((ds dfas))
    (cond ((null? ds) #t)
          ((not (dfa-run (car ds) inputs)) #f)
          (else (loop (cdr ds))))))

(define (any-accept? dfas inputs)
  (let loop ((ds dfas))
    (cond ((null? ds) #f)
          ((dfa-run (car ds) inputs) #t)
          (else (loop (cdr ds))))))

;; --- Verify ---

(define (state-machine-check)
  (and (dfa-run div3 '(1 1 0))
       (not (dfa-run div3 '(1 0 1)))
       (dfa-run-str ends-ab "ab")
       (not (dfa-run-str ends-ab "ba"))
       (dfa-run even-z '(1 0 0 1))
       (not (dfa-run even-z '(1 0 0 0)))
       (equal? (dfa-trace div3 '(1 1 0)) '(r0 r1 r0 r0))
       (all-accept? (list div3 even-z) '(1 0 0 1))))

;; (state-machine-check) => #t
