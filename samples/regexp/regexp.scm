;;; Simple Regular Expression Matcher
;;; Patterns are represented as S-expressions:
;;;   (lit c)       - match character c
;;;   (any)         - match any single character
;;;   (seq p1 p2)   - match p1 followed by p2
;;;   (alt p1 p2)   - match p1 or p2
;;;   (star p)      - match zero or more of p
;;;   (plus p)      - match one or more of p
;;;   (opt p)       - match zero or one of p
;;; Matching is done on lists of characters.

;; --- Pattern constructors ---

(define (lit c) (list 'lit c))
(define (any) '(any))
(define (seq p1 p2) (list 'seq p1 p2))
(define (alt p1 p2) (list 'alt p1 p2))
(define (star p) (list 'star p))
(define (plus p) (list 'plus p))
(define (opt p) (list 'opt p))

;; --- Pattern predicates ---

(define (lit? p) (and (pair? p) (eq? (car p) 'lit)))
(define (any? p) (and (pair? p) (eq? (car p) 'any)))
(define (seq? p) (and (pair? p) (eq? (car p) 'seq)))
(define (alt? p) (and (pair? p) (eq? (car p) 'alt)))
(define (star? p) (and (pair? p) (eq? (car p) 'star)))
(define (plus? p) (and (pair? p) (eq? (car p) 'plus)))
(define (opt? p) (and (pair? p) (eq? (car p) 'opt)))

;; --- Matcher ---
;; re-match takes a pattern and a list of chars.
;; Returns a list of possible remaining character lists after matching.
;; An empty list means no match.
;; A list containing '() means a full match was achieved.

(define (re-match pat chars)
  (cond
    ;; Literal: match exact character
    ((lit? pat)
     (if (and (pair? chars) (char=? (car chars) (cadr pat)))
         (list (cdr chars))
         '()))

    ;; Any: match any single character
    ((any? pat)
     (if (pair? chars)
         (list (cdr chars))
         '()))

    ;; Sequence: match p1 then p2
    ((seq? pat)
     (let ((after-p1 (re-match (cadr pat) chars)))
       (let loop ((remaining after-p1) (results '()))
         (if (null? remaining)
             results
             (loop (cdr remaining)
                   (append results
                           (re-match (caddr pat) (car remaining))))))))

    ;; Alternation: match p1 or p2
    ((alt? pat)
     (append (re-match (cadr pat) chars)
             (re-match (caddr pat) chars)))

    ;; Star: zero or more (worklist-based to avoid set!/closure issues)
    ((star? pat)
     (let ((sub (cadr pat)))
       (define (star-expand worklist results)
         (if (null? worklist)
             results
             (let ((c (car worklist))
                   (rest (cdr worklist)))
               (if (member c results)
                   (star-expand rest results)
                   (let ((matches (re-match sub c)))
                     (star-expand (append rest matches)
                                  (cons c results)))))))
       (star-expand (list chars) '())))

    ;; Plus: one or more = one match then star
    ((plus? pat)
     (let ((sub (cadr pat)))
       (let ((first-matches (re-match sub chars)))
         (let loop ((remaining first-matches) (results '()))
           (if (null? remaining)
               results
               (loop (cdr remaining)
                     (append results
                             (re-match (star sub) (car remaining)))))))))

    ;; Optional: zero or one
    ((opt? pat)
     (append (list chars) (re-match (cadr pat) chars)))

    (else '())))

;; --- Convenience: full match check ---

(define (re-full-match? pat str)
  (let ((chars (string->list str)))
    (let ((results (re-match pat chars)))
      (if (member '() results) #t #f))))

;; ============================================================
;; Examples
;; ============================================================

;; Pattern: ab (literal sequence)
(define pat-ab (seq (lit #\a) (lit #\b)))
;; (re-full-match? pat-ab "ab")  => #t
;; (re-full-match? pat-ab "abc") => #f

;; Pattern: a|b (alternation)
(define pat-a-or-b (alt (lit #\a) (lit #\b)))
;; (re-full-match? pat-a-or-b "a") => #t
;; (re-full-match? pat-a-or-b "c") => #f

;; Pattern: a* (zero or more)
(define pat-a-star (star (lit #\a)))
;; (re-full-match? pat-a-star "")    => #t
;; (re-full-match? pat-a-star "aaa") => #t
;; (re-full-match? pat-a-star "ab")  => #f

;; Pattern: a+b (one or more a's followed by b)
(define pat-a-plus-b (seq (plus (lit #\a)) (lit #\b)))
;; (re-full-match? pat-a-plus-b "aaab") => #t
;; (re-full-match? pat-a-plus-b "b")    => #f

;; Pattern: a.b (a, any char, b)
(define pat-a-dot-b (seq (lit #\a) (seq (any) (lit #\b))))
;; (re-full-match? pat-a-dot-b "axb") => #t
;; (re-full-match? pat-a-dot-b "ab")  => #f

;; Pattern: .* (any characters)
(define pat-any-star (star (any)))

;; Pattern: colou?r (optional u)
(define pat-color
  (seq (lit #\c)
    (seq (lit #\o)
      (seq (lit #\l)
        (seq (lit #\o)
          (seq (opt (lit #\u))
            (lit #\r)))))))
;; (re-full-match? pat-color "color")  => #t
;; (re-full-match? pat-color "colour") => #t

;; --- Verify ---

(define (regexp-check)
  (and
   (re-full-match? pat-ab "ab")
   (not (re-full-match? pat-ab "abc"))
   (re-full-match? pat-a-or-b "a")
   (re-full-match? pat-a-or-b "b")
   (not (re-full-match? pat-a-or-b "c"))
   (re-full-match? pat-a-star "")
   (re-full-match? pat-a-star "aaa")
   (not (re-full-match? pat-a-star "ab"))
   (re-full-match? pat-a-plus-b "ab")
   (re-full-match? pat-a-plus-b "aaab")
   (not (re-full-match? pat-a-plus-b "b"))
   (re-full-match? pat-a-dot-b "axb")
   (not (re-full-match? pat-a-dot-b "ab"))
   (re-full-match? pat-color "color")
   (re-full-match? pat-color "colour")
   (not (re-full-match? pat-color "colouur"))
   (re-full-match? pat-any-star "")
   (re-full-match? pat-any-star "hello")))

;; (regexp-check) => #t
