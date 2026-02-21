/// Raytracer demo - generates actual PPM output for visual verification

test "raytracer: generate 5x3 PPM image" {
  let ctx = new_repl_context()

  // Vector operations
  match repl_eval(ctx, "(define (vec3 x y z) (list x y z))") {
    Ok(_) => ()
    Err(e) => fail("vec3: " + e)
  }
  match repl_eval(ctx, "(define (vec-x v) (car v))") {
    Ok(_) => ()
    Err(e) => fail("vec-x: " + e)
  }
  match repl_eval(ctx, "(define (vec-y v) (cadr v))") {
    Ok(_) => ()
    Err(e) => fail("vec-y: " + e)
  }
  match repl_eval(ctx, "(define (vec-z v) (caddr v))") {
    Ok(_) => ()
    Err(e) => fail("vec-z: " + e)
  }

  // Color conversion
  match repl_eval(ctx, "(define (clamp x) (max 0 (min 255 (truncate (* 255 x)))))") {
    Ok(_) => ()
    Err(e) => fail("clamp: " + e)
  }
  match repl_eval(ctx, "(define (color-to-rgb c) (list (clamp (vec-x c)) (clamp (vec-y c)) (clamp (vec-z c))))") {
    Ok(_) => ()
    Err(e) => fail("color-to-rgb: " + e)
  }

  // Simple gradient function
  match repl_eval(ctx, "(define (simple-gradient x y width height) (let ((u (/ x width)) (v (/ y height))) (vec3 u v (+ (* 0.5 (- 1 u)) (* 0.5 v)))))") {
    Ok(_) => ()
    Err(e) => fail("simple-gradient: " + e)
  }

  // Render a 5x3 image
  match repl_eval(ctx, "(define (render-row y width height) (define (iter x acc) (if (< x width) (iter (+ x 1) (cons (color-to-rgb (simple-gradient x y width height)) acc)) (reverse acc))) (iter 0 '()))") {
    Ok(_) => ()
    Err(e) => fail("render-row: " + e)
  }

  match repl_eval(ctx, "(define (render-image width height) (define (iter y acc) (if (< y height) (iter (+ y 1) (cons (render-row y width height) acc)) (reverse acc))) (iter 0 '()))") {
    Ok(_) => ()
    Err(e) => fail("render-image: " + e)
  }

  // Generate image data
  match repl_eval(ctx, "(define tiny-image (render-image 5 3))") {
    Ok(_) => ()
    Err(e) => fail("tiny-image: " + e)
  }

  // Print PPM header and image data
  println("\n=== Generated 5x3 PPM Image ===")
  println("P3")
  println("5 3")
  println("255")

  // Extract and print pixel data
  match repl_eval(ctx, "tiny-image") {
    Ok(image) => {
      println("# Image data (as Scheme value):")
      println("# " + image.to_string())
      println("\n# To view this image:")
      println("# 1. Copy the P3 header and RGB values to a file (e.g., tiny.ppm)")
      println("# 2. Use: open tiny.ppm (macOS) or convert tiny.ppm tiny.png")
      ()
    }
    Err(e) => fail("Failed to get image: " + e)
  }

  // Verify structure
  match repl_eval(ctx, "(length tiny-image)") {
    Ok(Value::Number(Number::Int(3))) => ()  // 3 rows
    Ok(v) => fail("expected 3 rows, got " + v.to_string())
    Err(e) => fail("length check: " + e)
  }

  println("\n=== Raytracer Demo Complete ===")
}
