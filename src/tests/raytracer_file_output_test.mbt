/// Test raytracer with file output using open-output-file

test "raytracer: output to file (500x375 pixels - deep reflections)" {
  let ctx = new_repl_context()

  // Define all raytracer functions
  let _ = repl_eval(ctx, "(define (vec3 x y z) (list x y z))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-x v) (car v))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-y v) (cadr v))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-z v) (caddr v))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-add u v) (vec3 (+ (vec-x u) (vec-x v)) (+ (vec-y u) (vec-y v)) (+ (vec-z u) (vec-z v))))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-sub u v) (vec3 (- (vec-x u) (vec-x v)) (- (vec-y u) (vec-y v)) (- (vec-z u) (vec-z v))))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-scale v s) (vec3 (* (vec-x v) s) (* (vec-y v) s) (* (vec-z v) s)))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-dot u v) (+ (* (vec-x u) (vec-x v)) (* (vec-y u) (vec-y v)) (* (vec-z u) (vec-z v))))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-length v) (sqrt (vec-dot v v)))").unwrap()
  let _ = repl_eval(ctx, "(define (vec-normalize v) (let ((len (vec-length v))) (if (> len 0) (vec-scale v (/ 1 len)) v)))").unwrap()

  let _ = repl_eval(ctx, "(define (make-ray origin direction) (list origin direction))").unwrap()
  let _ = repl_eval(ctx, "(define (ray-origin r) (car r))").unwrap()
  let _ = repl_eval(ctx, "(define (ray-direction r) (cadr r))").unwrap()
  let _ = repl_eval(ctx, "(define (ray-at r t) (vec-add (ray-origin r) (vec-scale (ray-direction r) t)))").unwrap()

  let _ = repl_eval(ctx, "(define (cadddr x) (car (cdr (cdr (cdr x)))))").unwrap()
  // Sphere with material (color + reflectivity)
  let _ = repl_eval(ctx, "(define (make-sphere center radius color reflectivity) (list 'sphere center radius color reflectivity))").unwrap()
  let _ = repl_eval(ctx, "(define (sphere-center s) (cadr s))").unwrap()
  let _ = repl_eval(ctx, "(define (sphere-radius s) (caddr s))").unwrap()
  let _ = repl_eval(ctx, "(define (sphere-color s) (cadddr s))").unwrap()
  let _ = repl_eval(ctx, "(define (sphere-reflectivity s) (car (cdr (cdr (cdr (cdr s))))))").unwrap()

  let _ = repl_eval(ctx, "(define (hit-sphere sphere ray) (let* ((oc (vec-sub (ray-origin ray) (sphere-center sphere))) (a (vec-dot (ray-direction ray) (ray-direction ray))) (b (* 2 (vec-dot oc (ray-direction ray)))) (c (- (vec-dot oc oc) (* (sphere-radius sphere) (sphere-radius sphere)))) (discriminant (- (* b b) (* 4 a c)))) (if (< discriminant 0) #f (let ((t (/ (- (- b) (sqrt discriminant)) (* 2 a)))) (if (> t 0.001) t #f)))))").unwrap()

  let _ = repl_eval(ctx, "(define (find-closest-hit ray spheres) (define (iter remaining closest-t closest-sphere) (if (null? remaining) (if closest-sphere (list closest-t closest-sphere) #f) (let* ((sphere (car remaining)) (t (hit-sphere sphere ray))) (if (and t (or (not closest-t) (< t closest-t))) (iter (cdr remaining) t sphere) (iter (cdr remaining) closest-t closest-sphere))))) (iter spheres #f #f))").unwrap()

  // Helper: reflect vector v around normal n
  let _ = repl_eval(ctx, "(define (vec-reflect v n) (vec-sub v (vec-scale n (* 2 (vec-dot v n)))))").unwrap()

  // Optimized ray color with deep reflections (max depth 5, early exit for low reflectivity)
  let _ = repl_eval(ctx, "(define (ray-color-recursive ray spheres depth) (if (> depth 5) (vec3 0 0 0) (let ((hit (find-closest-hit ray spheres))) (if hit (let* ((t (car hit)) (sphere (cadr hit)) (hit-point (ray-at ray t)) (normal (vec-normalize (vec-sub hit-point (sphere-center sphere)))) (reflectivity (sphere-reflectivity sphere)) (sphere-col (sphere-color sphere)) (r (/ (+ 1 (vec-x normal)) 2)) (g (/ (+ 1 (vec-y normal)) 2)) (b (/ (+ 1 (vec-z normal)) 2)) (surface-col (vec3 (* r (vec-x sphere-col)) (* g (vec-y sphere-col)) (* b (vec-z sphere-col))))) (if (> reflectivity 0.01) (let* ((reflected-dir (vec-reflect (ray-direction ray) normal)) (reflected-ray (make-ray hit-point reflected-dir)) (reflected-color (ray-color-recursive reflected-ray spheres (+ depth 1)))) (vec-add (vec-scale surface-col (- 1.0 reflectivity)) (vec-scale reflected-color reflectivity))) surface-col)) (let* ((unit-dir (vec-normalize (ray-direction ray))) (t (* 0.5 (+ (vec-y unit-dir) 1.0))) (white (vec3 1.0 1.0 1.0)) (blue (vec3 0.5 0.7 1.0))) (vec-add (vec-scale white (- 1.0 t)) (vec-scale blue t)))))))").unwrap()

  let _ = repl_eval(ctx, "(define (ray-color ray spheres) (ray-color-recursive ray spheres 0))").unwrap()

  let _ = repl_eval(ctx, "(define (color-to-rgb color) (define (clamp x) (max 0 (min 255 (truncate (* 255 x))))) (list (clamp (vec-x color)) (clamp (vec-y color)) (clamp (vec-z color))))").unwrap()

  // Define a scene with reflective spheres (mirrors) and diffuse spheres
  // Reflectivity: 0.0 = diffuse, 0.5 = semi-reflective, 0.9 = mirror
  let _ = repl_eval(ctx, "(define mirror-spheres (list (make-sphere (vec3 0 0 -1) 0.5 (vec3 0.9 0.9 0.9) 0.9) (make-sphere (vec3 -1.2 0 -1.5) 0.4 (vec3 0.8 0.3 0.3) 0.0) (make-sphere (vec3 1.2 0 -1.5) 0.4 (vec3 0.3 0.3 0.8) 0.0) (make-sphere (vec3 0 0.6 -1) 0.3 (vec3 1.0 0.8 0.2) 0.5) (make-sphere (vec3 -0.6 -0.3 -0.8) 0.25 (vec3 0.3 0.8 0.3) 0.3) (make-sphere (vec3 0 -100.5 -1) 100 (vec3 0.8 0.8 0.0) 0.2)))").unwrap()

  // Define helper function to output PPM to a file
  match repl_eval(ctx, "(define (output-ppm-to-file filename width height pixels) (let ((port (open-output-file filename))) (display \"P3\" port) (newline port) (display width port) (display \" \" port) (display height port) (newline port) (display \"255\" port) (newline port) (letrec ((output-row (lambda (row) (if (not (null? row)) (begin (let ((pixel (car row))) (display (car pixel) port) (display \" \" port) (display (cadr pixel) port) (display \" \" port) (display (caddr pixel) port) (display \" \" port)) (output-row (cdr row)))))) (output-rows (lambda (rows) (if (not (null? rows)) (begin (output-row (car rows)) (newline port) (output-rows (cdr rows))))))) (output-rows pixels)) (close-output-port port)))") {
    Ok(_) => ()
    Err(e) => fail("Failed to define output-ppm-to-file: " + e)
  }

  // Render a tiny 3x2 image
  match repl_eval(ctx, "(define (render-tiny width height spheres) (let* ((aspect-ratio (/ width height)) (viewport-height 2.0) (viewport-width (* aspect-ratio viewport-height)) (focal-length 1.0) (camera-center (vec3 0 0 0)) (viewport-u (vec3 viewport-width 0 0)) (viewport-v (vec3 0 (- viewport-height) 0)) (pixel-delta-u (vec-scale viewport-u (/ 1.0 width))) (pixel-delta-v (vec-scale viewport-v (/ 1.0 height))) (viewport-upper-left (vec-sub (vec-sub (vec-sub camera-center (vec3 0 0 focal-length)) (vec-scale viewport-u 0.5)) (vec-scale viewport-v 0.5))) (pixel00-loc (vec-add viewport-upper-left (vec-scale (vec-add pixel-delta-u pixel-delta-v) 0.5)))) (letrec ((render-pixel (lambda (x y) (let* ((pixel-center (vec-add pixel00-loc (vec-add (vec-scale pixel-delta-u x) (vec-scale pixel-delta-v y)))) (ray-dir (vec-normalize (vec-sub pixel-center camera-center))) (ray (make-ray camera-center ray-dir)) (color (ray-color ray spheres))) (color-to-rgb color)))) (render-col (lambda (x y width) (if (< x width) (cons (render-pixel x y) (render-col (+ x 1) y width)) (quote ())))) (render-row (lambda (y width) (render-col 0 y width))) (render-rows (lambda (y height width) (if (< y height) (cons (render-row y width) (render-rows (+ y 1) height width)) (quote ()))))) (render-rows 0 height width))))") {
    Ok(_) => ()
    Err(e) => fail("Failed to define render-tiny: " + e)
  }

  // Generate a very high-resolution raytracing image with deep reflections
  println("Rendering 500x375 pixel raytracing scene with DEEP reflections...")
  println("Scene: Mirror sphere (center) + colored spheres + reflective ground")
  println("Optimizations: Early exit for low reflectivity, reduced duplicate calculations")
  println("Features: Recursive ray tracing with reflections (max depth 5)")
  println("Resolution: 500x375 pixels (187,500 pixels)")
  println("WARNING: This will take 10-15 minutes or more...")
  println("")
  match repl_eval(ctx, "(output-ppm-to-file \"/Users/suzumiyaaoba/ghq/github.com/SuzumiyaAoba/selene-core/raytraced_ultra.ppm\" 500 375 (render-tiny 500 375 mirror-spheres))") {
    Ok(_) => {
      println("")
      println("SUCCESS! Ultra high-resolution raytraced image saved!")
      println("File: raytraced_ultra.ppm")
      println("Resolution: 500x375 pixels (187,500 pixels)")
      println("Reflection depth: 5 levels")
      println("Objects: 1 mirror sphere + 4 colored spheres + reflective ground")
    }
    Err(e) => fail("Failed to generate image: " + e)
  }
}
