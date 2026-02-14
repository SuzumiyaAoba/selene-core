;;; Matrix Operations
;;; Demonstrates nested list manipulation, map, fold, and numeric computation.
;;; A matrix is represented as a list of rows, where each row is a list of numbers.

;; --- Construction ---

;; Create an m x n matrix filled with a value
(define (make-matrix m n val)
  (let loop-rows ((i 0) (rows '()))
    (if (= i m)
        (reverse rows)
        (loop-rows (+ i 1)
                   (cons (let loop-cols ((j 0) (cols '()))
                           (if (= j n) (reverse cols)
                               (loop-cols (+ j 1) (cons val cols))))
                         rows)))))

;; Create an n x n identity matrix
(define (identity-matrix n)
  (let loop-rows ((i 0) (rows '()))
    (if (= i n)
        (reverse rows)
        (loop-rows (+ i 1)
                   (cons (let loop-cols ((j 0) (cols '()))
                           (if (= j n) (reverse cols)
                               (loop-cols (+ j 1) (cons (if (= i j) 1 0) cols))))
                         rows)))))

;; (identity-matrix 3) => ((1 0 0) (0 1 0) (0 0 1))

;; --- Accessors ---

(define (matrix-ref mat i j)
  (list-ref (list-ref mat i) j))

(define (matrix-rows mat) (length mat))
(define (matrix-cols mat) (length (car mat)))

;; --- Element-wise operations ---

(define (matrix-map f mat)
  (map (lambda (row) (map f row)) mat))

(define (matrix-zip-with f mat1 mat2)
  (map (lambda (r1 r2) (map f r1 r2)) mat1 mat2))

(define (matrix-add mat1 mat2)
  (matrix-zip-with + mat1 mat2))

(define (matrix-sub mat1 mat2)
  (matrix-zip-with - mat1 mat2))

(define (matrix-scale k mat)
  (matrix-map (lambda (x) (* k x)) mat))

;; --- Transpose ---

(define (transpose mat)
  (if (null? (car mat))
      '()
      (cons (map car mat)
            (transpose (map cdr mat)))))

;; (transpose '((1 2 3) (4 5 6))) => ((1 4) (2 5) (3 6))

;; --- Dot product ---

(define (dot-product v1 v2)
  (fold-left + 0 (map * v1 v2)))

;; (dot-product '(1 2 3) '(4 5 6)) => 32

;; --- Matrix multiplication ---

(define (matrix-mul mat1 mat2)
  (let ((cols2 (transpose mat2)))
    (map (lambda (row1)
           (map (lambda (col2) (dot-product row1 col2))
                cols2))
         mat1)))

;; (matrix-mul '((1 2) (3 4)) '((5 6) (7 8))) => ((19 22) (43 50))

;; --- Determinant (for small matrices) ---

;; Remove column j from a matrix (for cofactor expansion)
(define (remove-col mat j)
  (map (lambda (row)
         (let loop ((k 0) (cells row) (result '()))
           (cond ((null? cells) (reverse result))
                 ((= k j) (loop (+ k 1) (cdr cells) result))
                 (else (loop (+ k 1) (cdr cells) (cons (car cells) result))))))
       mat))

;; Determinant via cofactor expansion along the first row
(define (determinant mat)
  (let ((n (matrix-rows mat)))
    (cond ((= n 1) (matrix-ref mat 0 0))
          ((= n 2)
           (- (* (matrix-ref mat 0 0) (matrix-ref mat 1 1))
              (* (matrix-ref mat 0 1) (matrix-ref mat 1 0))))
          (else
           (let ((first-row (car mat))
                 (rest (cdr mat)))
             (let loop ((j 0) (cells first-row) (sign 1) (sum 0))
               (if (null? cells)
                   sum
                   (loop (+ j 1) (cdr cells) (- sign)
                         (+ sum (* sign (car cells)
                                   (determinant (remove-col rest j))))))))))))

;; (determinant '((1 2) (3 4))) => -2
;; (determinant '((1 2 3) (4 5 6) (7 8 0))) => 27

;; --- Matrix equality ---

(define (matrix-equal? mat1 mat2)
  (equal? mat1 mat2))

;; --- Verify ---

(define (matrix-check)
  (let ((a '((1 2) (3 4)))
        (b '((5 6) (7 8)))
        (id2 (identity-matrix 2)))
    (and
     ;; Addition
     (matrix-equal? (matrix-add a b) '((6 8) (10 12)))
     ;; Subtraction
     (matrix-equal? (matrix-sub b a) '((4 4) (4 4)))
     ;; Scalar multiplication
     (matrix-equal? (matrix-scale 2 a) '((2 4) (6 8)))
     ;; Transpose
     (matrix-equal? (transpose a) '((1 3) (2 4)))
     ;; Matrix multiply
     (matrix-equal? (matrix-mul a b) '((19 22) (43 50)))
     ;; Identity matrix
     (matrix-equal? (matrix-mul a id2) a)
     (matrix-equal? (matrix-mul id2 a) a)
     ;; Determinant
     (= (determinant a) -2)
     (= (determinant '((1 2 3) (4 5 6) (7 8 0))) 27)
     ;; Dot product
     (= (dot-product '(1 2 3) '(4 5 6)) 32)
     ;; Zero matrix
     (matrix-equal? (make-matrix 2 3 0) '((0 0 0) (0 0 0))))))

;; (matrix-check) => #t
