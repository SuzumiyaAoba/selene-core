;;; Sorting Algorithms on Lists
;;; Demonstrates higher-order functions, list recursion, and divide-and-conquer.

;; --- Utility ---

(define (filter pred lst)
  (let loop ((l lst) (acc '()))
    (cond ((null? l) (reverse acc))
          ((pred (car l)) (loop (cdr l) (cons (car l) acc)))
          (else (loop (cdr l) acc)))))

;; --- Insertion Sort ---

(define (insert x sorted less?)
  (cond ((null? sorted) (list x))
        ((less? x (car sorted)) (cons x sorted))
        (else (cons (car sorted) (insert x (cdr sorted) less?)))))

(define (insertion-sort lst less?)
  (let loop ((l lst) (acc '()))
    (if (null? l)
        acc
        (loop (cdr l) (insert (car l) acc less?)))))

;; (insertion-sort '(5 3 8 1 9 2 7 4 6) <) => (1 2 3 4 5 6 7 8 9)

;; --- Quicksort ---

(define (quicksort lst less?)
  (if (or (null? lst) (null? (cdr lst)))
      lst
      (let ((pivot (car lst))
            (rest (cdr lst)))
        (let ((lo (filter (lambda (x) (less? x pivot)) rest))
              (hi (filter (lambda (x) (not (less? x pivot))) rest)))
          (append (quicksort lo less?)
                  (cons pivot (quicksort hi less?)))))))

;; (quicksort '(5 3 8 1 9 2 7 4 6) <) => (1 2 3 4 5 6 7 8 9)

;; --- Merge Sort ---

(define (merge xs ys less?)
  (cond ((null? xs) ys)
        ((null? ys) xs)
        ((less? (car xs) (car ys))
         (cons (car xs) (merge (cdr xs) ys less?)))
        (else
         (cons (car ys) (merge xs (cdr ys) less?)))))

(define (split lst)
  (let loop ((l lst) (left '()) (right '()) (toggle #t))
    (if (null? l)
        (list (reverse left) (reverse right))
        (if toggle
            (loop (cdr l) (cons (car l) left) right #f)
            (loop (cdr l) left (cons (car l) right) #t)))))

(define (merge-sort lst less?)
  (if (or (null? lst) (null? (cdr lst)))
      lst
      (let ((halves (split lst)))
        (merge (merge-sort (car halves) less?)
               (merge-sort (cadr halves) less?)
               less?))))

;; (merge-sort '(5 3 8 1 9 2 7 4 6) <) => (1 2 3 4 5 6 7 8 9)

;; --- Verify all sorts produce the same result ---

(define (sort-check)
  (let ((data '(38 27 43 3 9 82 10 1 57 24)))
    (let ((r1 (insertion-sort data <))
          (r2 (quicksort data <))
          (r3 (merge-sort data <)))
      (and (equal? r1 r2) (equal? r2 r3)
           (equal? r1 '(1 3 9 10 24 27 38 43 57 82))))))

;; (sort-check) => #t
