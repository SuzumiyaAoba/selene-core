;;; Simple Ray Tracer in Scheme
;;; Renders a scene with spheres using basic ray tracing

;; Vector operations
(define (vec3 x y z) (list x y z))
(define (vec-x v) (car v))
(define (vec-y v) (cadr v))
(define (vec-z v) (caddr v))

(define (vec-add u v)
  (vec3 (+ (vec-x u) (vec-x v))
        (+ (vec-y u) (vec-y v))
        (+ (vec-z u) (vec-z v))))

(define (vec-sub u v)
  (vec3 (- (vec-x u) (vec-x v))
        (- (vec-y u) (vec-y v))
        (- (vec-z u) (vec-z v))))

(define (vec-scale v s)
  (vec3 (* (vec-x v) s)
        (* (vec-y v) s)
        (* (vec-z v) s)))

(define (vec-dot u v)
  (+ (* (vec-x u) (vec-x v))
     (* (vec-y u) (vec-y v))
     (* (vec-z u) (vec-z v))))

(define (vec-length v)
  (sqrt (vec-dot v v)))

(define (vec-normalize v)
  (let ((len (vec-length v)))
    (if (> len 0)
        (vec-scale v (/ 1 len))
        v)))

;; Ray definition
(define (make-ray origin direction)
  (list origin direction))

(define (ray-origin r) (car r))
(define (ray-direction r) (cadr r))

(define (ray-at r t)
  (vec-add (ray-origin r) (vec-scale (ray-direction r) t)))

;; Sphere definition
(define (make-sphere center radius color)
  (list 'sphere center radius color))

(define (sphere? s) (eq? (car s) 'sphere))
(define (sphere-center s) (cadr s))
(define (sphere-radius s) (caddr s))
(define (sphere-color s) (cadddr s))

;; Ray-sphere intersection
(define (hit-sphere sphere ray)
  (let* ((oc (vec-sub (ray-origin ray) (sphere-center sphere)))
         (a (vec-dot (ray-direction ray) (ray-direction ray)))
         (b (* 2 (vec-dot oc (ray-direction ray))))
         (c (- (vec-dot oc oc) (* (sphere-radius sphere) (sphere-radius sphere))))
         (discriminant (- (* b b) (* 4 a c))))
    (if (< discriminant 0)
        #f
        (let ((t (/ (- (- b) (sqrt discriminant)) (* 2 a))))
          (if (> t 0.001)
              t
              #f)))))

;; Find closest hit in scene
(define (find-closest-hit ray spheres)
  (define (iter remaining closest-t closest-sphere)
    (if (null? remaining)
        (if closest-sphere
            (list closest-t closest-sphere)
            #f)
        (let* ((sphere (car remaining))
               (t (hit-sphere sphere ray)))
          (if (and t (or (not closest-t) (< t closest-t)))
              (iter (cdr remaining) t sphere)
              (iter (cdr remaining) closest-t closest-sphere)))))
  (iter spheres #f #f))

;; Calculate color for a ray
(define (ray-color ray spheres)
  (let ((hit (find-closest-hit ray spheres)))
    (if hit
        (let* ((t (car hit))
               (sphere (cadr hit))
               (hit-point (ray-at ray t))
               (normal (vec-normalize (vec-sub hit-point (sphere-center sphere))))
               ;; Map normal to color (0.0 to 1.0)
               (r (/ (+ 1 (vec-x normal)) 2))
               (g (/ (+ 1 (vec-y normal)) 2))
               (b (/ (+ 1 (vec-z normal)) 2))
               ;; Mix with sphere color
               (sphere-col (sphere-color sphere)))
          (vec3 (* r (vec-x sphere-col))
                (* g (vec-y sphere-col))
                (* b (vec-z sphere-col))))
        ;; Background gradient
        (let* ((unit-dir (vec-normalize (ray-direction ray)))
               (t (* 0.5 (+ (vec-y unit-dir) 1.0)))
               (white (vec3 1.0 1.0 1.0))
               (blue (vec3 0.5 0.7 1.0)))
          (vec-add (vec-scale white (- 1.0 t))
                   (vec-scale blue t))))))

;; Color conversion to 0-255 range
(define (color-to-rgb color)
  (define (clamp x) (max 0 (min 255 (truncate (* 255 x)))))
  (vec3 (clamp (vec-x color))
        (clamp (vec-y color))
        (clamp (vec-z color))))

;; Render scene
(define (render-scene width height spheres)
  (let* ((aspect-ratio (/ width height))
         (viewport-height 2.0)
         (viewport-width (* aspect-ratio viewport-height))
         (focal-length 1.0)
         (camera-center (vec3 0 0 0))
         (viewport-u (vec3 viewport-width 0 0))
         (viewport-v (vec3 0 (- viewport-height) 0))
         (pixel-delta-u (vec-scale viewport-u (/ 1.0 width)))
         (pixel-delta-v (vec-scale viewport-v (/ 1.0 height)))
         (viewport-upper-left
          (vec-sub (vec-sub (vec-sub camera-center (vec3 0 0 focal-length))
                            (vec-scale viewport-u 0.5))
                   (vec-scale viewport-v 0.5)))
         (pixel00-loc (vec-add viewport-upper-left
                               (vec-scale (vec-add pixel-delta-u pixel-delta-v) 0.5))))

    ;; Generate image data
    (define (render-pixel x y)
      (let* ((pixel-center (vec-add pixel00-loc
                                    (vec-add (vec-scale pixel-delta-u x)
                                            (vec-scale pixel-delta-v y))))
             (ray-dir (vec-normalize (vec-sub pixel-center camera-center)))
             (ray (make-ray camera-center ray-dir))
             (color (ray-color ray spheres)))
        (color-to-rgb color)))

    (define (render-row y)
      (define (render-col x)
        (if (< x width)
            (cons (render-pixel x y) (render-col (+ x 1)))
            '()))
      (render-col 0))

    (define (render-rows y)
      (if (< y height)
          (cons (render-row y) (render-rows (+ y 1)))
          '()))

    (render-rows 0)))

;; Output PPM format
(define (output-ppm width height image-data)
  (display "P3\n")
  (display width)
  (display " ")
  (display height)
  (display "\n255\n")

  (define (output-pixel color)
    (display (vec-x color))
    (display " ")
    (display (vec-y color))
    (display " ")
    (display (vec-z color))
    (display "\n"))

  (define (output-row row)
    (if (not (null? row))
        (begin
          (output-pixel (car row))
          (output-row (cdr row)))))

  (define (output-rows rows)
    (if (not (null? rows))
        (begin
          (output-row (car rows))
          (output-rows (cdr rows)))))

  (output-rows image-data))

;; Main rendering function
(define (raytrace width height)
  (let ((spheres (list
                  (make-sphere (vec3 0 0 -1) 0.5 (vec3 0.8 0.3 0.3))
                  (make-sphere (vec3 -1 0 -1) 0.5 (vec3 0.3 0.8 0.3))
                  (make-sphere (vec3 1 0 -1) 0.5 (vec3 0.3 0.3 0.8))
                  (make-sphere (vec3 0 -100.5 -1) 100 (vec3 0.8 0.8 0.0)))))
    (display "Rendering scene...\n")
    (let ((image (render-scene width height spheres)))
      (output-ppm width height image)
      (display "Done!\n"))))

;; Render a small image (increase size for better quality)
(raytrace 40 20)
