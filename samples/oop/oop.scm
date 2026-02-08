;;; Object-Oriented Programming Patterns
;;; Demonstrates message-passing OOP using closures.

;; --- 1. Counter object ---

(define (make-counter . args)
  (let ((count (if (null? args) 0 (car args))))
    (define (dispatch msg . params)
      (cond ((eq? msg 'inc)
             (set! count (+ count 1))
             count)
            ((eq? msg 'dec)
             (set! count (- count 1))
             count)
            ((eq? msg 'get) count)
            ((eq? msg 'reset)
             (set! count 0)
             count)
            (else (string-append "Unknown message: "
                                 (symbol->string msg)))))
    dispatch))

;; (define c (make-counter))
;; (c 'inc) => 1, (c 'inc) => 2, (c 'get) => 2, (c 'reset) => 0

;; --- 2. Stack object ---

(define (make-stack)
  (let ((items '()))
    (define (dispatch msg . params)
      (cond ((eq? msg 'push)
             (set! items (cons (car params) items))
             items)
            ((eq? msg 'pop)
             (if (null? items)
                 'empty
                 (let ((top (car items)))
                   (set! items (cdr items))
                   top)))
            ((eq? msg 'peek)
             (if (null? items) 'empty (car items)))
            ((eq? msg 'size) (length items))
            ((eq? msg 'empty?) (null? items))
            ((eq? msg 'to-list) items)
            (else "unknown")))
    dispatch))

;; --- 3. Bank account with transaction log ---

(define (make-account name initial-balance)
  (let ((balance initial-balance)
        (log '()))
    (define (record! action amount)
      (set! log (cons (list action amount balance) log)))
    (define (dispatch msg . params)
      (cond ((eq? msg 'deposit)
             (let ((amount (car params)))
               (set! balance (+ balance amount))
               (record! 'deposit amount)
               balance))
            ((eq? msg 'withdraw)
             (let ((amount (car params)))
               (if (< balance amount)
                   'insufficient-funds
                   (begin
                     (set! balance (- balance amount))
                     (record! 'withdraw amount)
                     balance))))
            ((eq? msg 'balance) balance)
            ((eq? msg 'name) name)
            ((eq? msg 'history) (reverse log))
            (else "unknown")))
    dispatch))

;; --- 4. Inheritance via delegation ---
;; A savings account extends a regular account with interest.
;; The interest rate is given as an integer percentage:
;; rate=10 means 10%, so interest = balance * rate / 100.

(define (make-savings-account name initial-balance interest-pct)
  (let ((base (make-account name initial-balance)))
    (define (dispatch msg . params)
      (cond ((eq? msg 'add-interest)
             (let ((interest (quotient (* (base 'balance) interest-pct) 100)))
               (base 'deposit interest)))
            ((eq? msg 'rate) interest-pct)
            (else (apply base (cons msg params)))))
    dispatch))

;; (define sav (make-savings-account "Bob" 1000 10))
;; (sav 'add-interest) => deposits 100 (10% of 1000)
;; (sav 'balance) => 1100

;; --- Verify ---

(define (oop-check)
  ;; Counter test
  (let ((c (make-counter 10)))
    (c 'inc) (c 'inc) (c 'inc)
    (let ((counter-ok (= (c 'get) 13)))

      ;; Stack test
      (let ((s (make-stack)))
        (s 'push 1)
        (s 'push 2)
        (s 'push 3)
        (let ((stack-ok (and (= (s 'peek) 3)
                             (= (s 'size) 3)
                             (= (s 'pop) 3)
                             (= (s 'pop) 2)
                             (= (s 'size) 1))))

          ;; Account test
          (let ((acc (make-account "Alice" 1000)))
            (acc 'deposit 500)
            (acc 'withdraw 200)
            (let ((account-ok (and (= (acc 'balance) 1300)
                                   (= (length (acc 'history)) 2))))

              ;; Savings account test
              (let ((sav (make-savings-account "Bob" 1000 10)))
                (sav 'add-interest)
                (let ((savings-ok (= (sav 'balance) 1100)))
                  (and counter-ok stack-ok account-ok savings-ok))))))))))

;; (oop-check) => #t
