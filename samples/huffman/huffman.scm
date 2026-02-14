;;; Huffman Coding
;;; Demonstrates binary tree construction, encoding, and decoding.
;;; Based on SICP Section 2.3.4.

;; --- Tree representation ---
;; Leaf: (leaf symbol weight)
;; Node: (node left right symbols weight)

(define (make-leaf symbol weight)
  (list 'leaf symbol weight))

(define (leaf? tree)
  (eq? (car tree) 'leaf))

(define (leaf-symbol tree) (cadr tree))
(define (leaf-weight tree) (caddr tree))

(define (make-tree left right)
  (list 'node left right
        (append (tree-symbols left) (tree-symbols right))
        (+ (tree-weight left) (tree-weight right))))

(define (tree-left tree) (cadr tree))
(define (tree-right tree) (caddr tree))

(define (tree-symbols tree)
  (if (leaf? tree)
      (list (leaf-symbol tree))
      (car (cdr (cdr (cdr tree))))))

(define (tree-weight tree)
  (if (leaf? tree)
      (leaf-weight tree)
      (car (cdr (cdr (cdr (cdr tree)))))))

;; --- Building a Huffman tree ---

;; Insert a tree into a sorted list (by weight, ascending)
(define (adjoin-set tree set)
  (cond ((null? set) (list tree))
        ((< (tree-weight tree) (tree-weight (car set)))
         (cons tree set))
        (else (cons (car set) (adjoin-set tree (cdr set))))))

;; Build initial leaf set from pairs of (symbol . weight)
(define (make-leaf-set pairs)
  (if (null? pairs)
      '()
      (adjoin-set (make-leaf (caar pairs) (cdar pairs))
                  (make-leaf-set (cdr pairs)))))

;; Successive merging: combine two lightest trees until one remains
(define (build-huffman-tree pairs)
  (let ((leaves (make-leaf-set pairs)))
    (define (merge set)
      (if (null? (cdr set))
          (car set)
          (let ((new-tree (make-tree (car set) (cadr set))))
            (merge (adjoin-set new-tree (cdr (cdr set)))))))
    (merge leaves)))

;; --- Encoding ---

;; Encode a single symbol: traverse tree to find the path
(define (encode-symbol symbol tree)
  (cond ((leaf? tree)
         (if (eq? symbol (leaf-symbol tree))
             '()
             #f))
        (else
         (let ((left-result (encode-symbol symbol (tree-left tree))))
           (if left-result
               (cons 0 left-result)
               (let ((right-result (encode-symbol symbol (tree-right tree))))
                 (if right-result
                     (cons 1 right-result)
                     #f)))))))

;; Encode a message (list of symbols) into bits
(define (encode message tree)
  (if (null? message)
      '()
      (append (encode-symbol (car message) tree)
              (encode (cdr message) tree))))

;; --- Decoding ---

;; Decode a list of bits back to symbols
(define (decode bits tree)
  (define (decode-1 bits current)
    (if (leaf? current)
        (cons (leaf-symbol current) (decode-1 bits tree))
        (if (null? bits)
            '()
            (if (= (car bits) 0)
                (decode-1 (cdr bits) (tree-left current))
                (decode-1 (cdr bits) (tree-right current))))))
  (decode-1 bits tree))

;; --- Example: build tree and encode/decode ---

;; Character frequencies for a simple alphabet
(define sample-pairs
  '((a . 8) (b . 3) (c . 1) (d . 1) (e . 1) (f . 1) (g . 1) (h . 1)))

(define sample-tree (build-huffman-tree sample-pairs))

;; Encode and decode a message
(define sample-message '(a b a c a d a e))

(define sample-bits (encode sample-message sample-tree))

(define decoded-message (decode sample-bits sample-tree))

;; decoded-message should equal sample-message
;; (equal? decoded-message sample-message) => #t

;; 'a' should have the shortest encoding (highest frequency)
;; (length (encode-symbol 'a sample-tree)) => 1

;; Verify round-trip for different messages
(define (roundtrip msg tree)
  (equal? (decode (encode msg tree) tree) msg))

;; --- Verify ---

(define (huffman-check)
  (and (equal? decoded-message sample-message)
       (= (length (encode-symbol 'a sample-tree)) 1)
       (roundtrip '(a b c d e f g h) sample-tree)
       (roundtrip '(a a a b b c) sample-tree)
       (roundtrip '(h g f e d c b a) sample-tree)
       ;; Encoding should be shorter than fixed-width for skewed frequencies
       (< (length sample-bits) (* 3 (length sample-message)))))

;; (huffman-check) => #t
