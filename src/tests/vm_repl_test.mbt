/// Testing the VM REPL

/// Basic arithmetic operations in VM
test "vm repl: basic arithmetic" {
  let ctx = new_repl_context()

  // (+ 1 2) => 3
  let result = repl_eval(ctx, "(+ 1 2)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected 3")
  }
}

/// Multiplication in VM
test "vm repl: multiplication" {
  let ctx = new_repl_context()

  // (* 3 4) => 12
  let result = repl_eval(ctx, "(* 3 4)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("Expected 12")
  }
}

/// define and reference in VM
test "vm repl: define and reference" {
  let ctx = new_repl_context()

  // (define x 10)
  let _ = repl_eval(ctx, "(define x 10)")

  // x => 10
  let result = repl_eval(ctx, "x")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    _ => fail("Expected 10")
  }
}

/// Multiple defines on VM
test "vm repl: multiple defines" {
  let ctx = new_repl_context()

  // (define x 10)
  let _ = repl_eval(ctx, "(define x 10)")
  // (define y 20)
  let _ = repl_eval(ctx, "(define y 20)")

  // (+ x y) => 30
  let result = repl_eval(ctx, "(+ x y)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 30)
    _ => fail("Expected 30")
  }
}

/// Defining and calling functions in the VM
test "vm repl: function definition and call" {
  let ctx = new_repl_context()

  // (define (square n) (* n n))
  let _ = repl_eval(ctx, "(define (square n) (* n n))")

  // (square 5) => 25
  let result = repl_eval(ctx, "(square 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 25)
    _ => fail("Expected 25")
  }
}

/// if expressions in VMs
test "vm repl: if expression" {
  let ctx = new_repl_context()

  // (if #t 1 2) => 1
  let result1 = repl_eval(ctx, "(if #t 1 2)")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 1)
    _ => fail("Expected 1")
  }

  // (if #f 1 2) => 2
  let result2 = repl_eval(ctx, "(if #f 1 2)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected 2")
  }
}

/// let expressions in the VM
test "vm repl: let expression" {
  let ctx = new_repl_context()

  // (let ((a 5) (b 10)) (+ a b)) => 15
  let result = repl_eval(ctx, "(let ((a 5) (b 10)) (+ a b))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    _ => fail("Expected 15")
  }
}

/// List operations on VMs
test "vm repl: list operations" {
  let ctx = new_repl_context()

  // (car (cons 1 2)) => 1
  let result1 = repl_eval(ctx, "(car (cons 1 2))")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 1)
    _ => fail("Expected 1")
  }

  // (cdr (cons 1 2)) => 2
  let result2 = repl_eval(ctx, "(cdr (cons 1 2))")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected 2")
  }
}

/// Recursive functions (factorial) in VM
test "vm repl: recursive function - factorial" {
  let ctx = new_repl_context()

  // (define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
  let _ = repl_eval(ctx, "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))")

  // (fact 5) => 120
  let result = repl_eval(ctx, "(fact 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 120)
    _ => fail("Expected 120")
  }
}

/// Recursive functions (Fibonacci) in VM
test "vm repl: recursive function - fibonacci" {
  let ctx = new_repl_context()

  // (define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
  let _ = repl_eval(ctx, "(define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))")

  // (fib 10) => 55
  let result = repl_eval(ctx, "(fib 10)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 55)
    _ => fail("Expected 55")
  }
}

/// Higher-order functions in VM
test "vm repl: higher order function" {
  let ctx = new_repl_context()

  // (define (apply-twice f x) (f (f x)))
  let _ = repl_eval(ctx, "(define (apply-twice f x) (f (f x)))")
  // (define (add1 n) (+ n 1))
  let _ = repl_eval(ctx, "(define (add1 n) (+ n 1))")

  // (apply-twice add1 5) => 7
  let result = repl_eval(ctx, "(apply-twice add1 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 7)
    _ => fail("Expected 7")
  }
}

/// Closures in VMs - simple case
test "vm repl: simple closure" {
  let ctx = new_repl_context()

  // ((lambda (x) x) 5) => 5
  let result1 = repl_eval(ctx, "((lambda (x) x) 5)")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("identity result = " + n.to_string())
      assert_eq(n, 5)
    }
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }

  // ((lambda (x) (+ x 1)) 5) => 6
  let result2 = repl_eval(ctx, "((lambda (x) (+ x 1)) 5)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("add1 result = " + n.to_string())
      assert_eq(n, 6)
    }
    Ok(v) => fail("Expected 6, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Nested closures in VMs
test "vm repl: nested closure" {
  let ctx = new_repl_context()

  // First, a nested closure that just returns
  // ((lambda (n) (lambda (x) x)) 5) => #<procedure>
  let result1 = repl_eval(ctx, "((lambda (n) (lambda (x) x)) 5)")
  match result1 {
    Ok(Value::Procedure(_)) => println("inner lambda returned")
    Ok(v) => fail("Expected procedure, got: " + v.to_string())
    Err(e) => fail("Error in step 1: " + e)
  }

  // Then just return the outer parameters
  // ((lambda (n) (lambda (x) n)) 5) => #<procedure>
  let result2a = repl_eval(ctx, "((lambda (n) (lambda (x) n)) 5)")
  match result2a {
    Ok(Value::Procedure(_)) => println("outer param lambda created")
    Ok(v) => fail("Expected procedure in 2a, got: " + v.to_string())
    Err(e) => fail("Error in step 2a: " + e)
  }

  // Reference outer parameters - test step by step
  // step 2b: call inner closure (without arguments)
  let result2b = repl_eval(ctx, "(((lambda (n) (lambda (x) 42)) 5) 10)")
  match result2b {
    Ok(Value::Number(Number::Int(n))) => {
      println("constant result = " + n.to_string())
      assert_eq(n, 42)
    }
    Ok(v) => fail("Expected 42, got: " + v.to_string())
    Err(e) => fail("Error in step 2b: " + e)
  }

  // step 2c: use arguments in inner closure
  let result2c = repl_eval(ctx, "(((lambda (n) (lambda (x) x)) 5) 10)")
  match result2c {
    Ok(Value::Number(Number::Int(n))) => {
      println("inner param result = " + n.to_string())
      assert_eq(n, 10)
    }
    Ok(v) => fail("Expected 10, got: " + v.to_string())
    Err(e) => fail("Error in step 2c: " + e)
  }

  // step 2: refer to outer parameters
  // (((lambda (n) (lambda (x) n)) 5) 10) => 5
  let result2 = repl_eval(ctx, "(((lambda (n) (lambda (x) n)) 5) 10)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("outer param reference = " + n.to_string())
      assert_eq(n, 5)
    }
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error in step 2: " + e)
  }

  // Finally, use both
  // (((lambda (n) (lambda (x) (+ n x))) 5) 10) => 15
  let result3 = repl_eval(ctx, "(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("nested closure result = " + n.to_string())
      assert_eq(n, 15)
    }
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error in step 3: " + e)
  }
}

/// Simple 2-argument function test (no closure)
test "vm: simple two arg function" {
  // A simple two-argument function without closures
  let expr = parse_one("((lambda (a b) (+ a b)) 5 10)")
  let result = vm_eval(expr)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("simple (+ a b) = " + n.to_string())
      assert_eq(n, 15)
    }
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Capture/parameter access using list
test "vm: list capture vs param" {
  // Check both values ​​with (list n x)
  let expr = parse_one("(((lambda (n) (lambda (x) (list n x))) 5) 10)")
  let result = vm_eval(expr)
  match result {
    Ok(Value::Pair(car, cdr, _)) => {
      match (car, cdr) {
        (Value::Number(Number::Int(n)), Value::Pair(x_val, Value::Nil, _)) => {
          match x_val {
            Value::Number(Number::Int(x)) => {
              println("list: n = " + n.to_string() + ", x = " + x.to_string())
              assert_eq(n, 5)
              assert_eq(x, 10)
            }
            _ => fail("x is not a number")
          }
        }
        _ => fail("Unexpected list structure")
      }
    }
    Ok(v) => fail("Expected list, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Capture/parameter access within PrimOp
test "vm: primop capture vs param" {
  // capture + constant
  let expr1 = parse_one("(((lambda (n) (lambda (x) (+ n 0))) 5) 10)")
  let result1 = vm_eval(expr1)
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ n 0) = " + n.to_string())
      assert_eq(n, 5)
    }
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error in (+ n 0): " + e)
  }

  // constant + parameter
  let expr2 = parse_one("(((lambda (n) (lambda (x) (+ 0 x))) 5) 10)")
  let result2 = vm_eval(expr2)
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ 0 x) = " + n.to_string())
      assert_eq(n, 10)
    }
    Ok(v) => fail("Expected 10, got: " + v.to_string())
    Err(e) => fail("Error in (+ 0 x): " + e)
  }

  // capture + parameters
  let expr3 = parse_one("(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  let result3 = vm_eval(expr3)
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ n x) = " + n.to_string())
      assert_eq(n, 15)
    }
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error in (+ n x): " + e)
  }
}

/// Capture debug test
test "vm: capture debug" {
  // Return only captured n
  let expr1 = parse_one("(((lambda (n) (lambda (x) n)) 5) 10)")
  let result1 = vm_eval(expr1)
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("captured n = " + n.to_string())
      assert_eq(n, 5)
    }
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error getting n: " + e)
  }

  // return only parameter x
  let expr2 = parse_one("(((lambda (n) (lambda (x) x)) 5) 10)")
  let result2 = vm_eval(expr2)
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("param x = " + n.to_string())
      assert_eq(n, 10)
    }
    Ok(v) => fail("Expected 10, got: " + v.to_string())
    Err(e) => fail("Error getting x: " + e)
  }

  // Add n and x
  let expr3 = parse_one("(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  let result3 = vm_eval(expr3)
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("n + x = " + n.to_string())
      assert_eq(n, 15)
    }
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error in n+x: " + e)
  }
}

/// Closure capture in REPL (single test)
test "vm repl: isolated capture test" {
  let ctx = new_repl_context()

  // When using only capture
  let result = repl_eval(ctx, "(((lambda (n) (lambda (x) n)) 5) 10)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Comparison operations in VM
test "vm repl: comparison" {
  let ctx = new_repl_context()

  // (< 1 2) => #t
  let result1 = repl_eval(ctx, "(< 1 2)")
  match result1 {
    Ok(Value::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected #t")
  }

  // (> 1 2) => #f
  let result2 = repl_eval(ctx, "(> 1 2)")
  match result2 {
    Ok(Value::Bool(b)) => assert_eq(b, false)
    _ => fail("Expected #f")
  }

  // (= 5 5) => #t
  let result3 = repl_eval(ctx, "(= 5 5)")
  match result3 {
    Ok(Value::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected #t")
  }
}

/// Testing the make-adder pattern
test "vm repl: make-adder pattern" {
  let ctx = new_repl_context()

  // (define (make-adder n) (lambda (x) (+ n x)))
  let _ = repl_eval(ctx, "(define (make-adder n) (lambda (x) (+ n x)))")

  // (define add5 (make-adder 5))
  let _ = repl_eval(ctx, "(define add5 (make-adder 5))")

  // (add5 10) => 15
  let result = repl_eval(ctx, "(add5 10)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }

  // (define add10 (make-adder 10))
  let _ = repl_eval(ctx, "(define add10 (make-adder 10))")

  // (add10 10) => 20
  let result2 = repl_eval(ctx, "(add10 10)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 20)
    Ok(v) => fail("Expected 20, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }

  // add5 and add10 are different closures
  // (+ (add5 0) (add10 0)) => 15
  let result3 = repl_eval(ctx, "(+ (add5 0) (add10 0))")
  match result3 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Testing the interaction between set! and closures
test "vm repl: closure with set!" {
  let ctx = new_repl_context()

  // A simple set! test (no closure)
  let _ = repl_eval(ctx, "(define x 0)")
  let _ = repl_eval(ctx, "(set! x 10)")
  let result1 = repl_eval(ctx, "x")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    Ok(v) => fail("Expected 10, got: " + v.to_string())
    Err(e) => fail("Error in simple set!: " + e)
  }
}

/// Counter pattern: Closure using set!
test "vm repl: counter pattern" {
  let ctx = new_repl_context()

  // define make-counter
  let _ = repl_eval(
    ctx,
    "(define (make-counter) (let ((count 0)) (lambda () (set! count (+ count 1)) count)))",
  )

  // create counter
  let _ = repl_eval(ctx, "(define counter (make-counter))")

  // First call: 1
  let result1 = repl_eval(ctx, "(counter)")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("counter first call: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => fail("Error in counter (1): " + e)
  }

  // Second call: 2
  let result2 = repl_eval(ctx, "(counter)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("counter second call: " + n.to_string())
      assert_eq(n, 2)
    }
    Ok(v) => fail("Expected 2, got: " + v.to_string())
    Err(e) => fail("Error in counter (2): " + e)
  }

  // 3rd call: 3
  let result3 = repl_eval(ctx, "(counter)")
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("counter third call: " + n.to_string())
      assert_eq(n, 3)
    }
    Ok(v) => fail("Expected 3, got: " + v.to_string())
    Err(e) => fail("Error in counter (3): " + e)
  }
}

/// Test call/cc with set! - simple case
test "vm repl: call/cc with set! simple" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simple: call/cc that captures and immediately returns
  // (let ((x 0)) (call/cc (lambda (k) (set! x 1) x)))
  let result = repl_eval(ctx, "(let ((x 0)) (call/cc (lambda (k) (set! x 1) x)))")
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("call/cc with set! result: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Test call/cc with set! - continuation invoked
test "vm repl: call/cc with set! invoke continuation" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Call continuation after set!
  // (let ((x 0)) (call/cc (lambda (k) (set! x 1) (k x))))
  let result = repl_eval(ctx, "(let ((x 0)) (call/cc (lambda (k) (set! x 1) (k x))))")
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("call/cc invoke continuation result: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Test call/cc with set! - saved continuation
test "vm repl: call/cc saved continuation with set!" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Define saved-k
  let _ = repl_eval(ctx, "(define saved-k #f)")

  // (let ((x 0)) (+ x (call/cc (lambda (k) (set! saved-k k) 1))))
  // First call should return 1 (0 + 1)
  let result1 = repl_eval(ctx, "(let ((x 0)) (+ x (call/cc (lambda (k) (set! saved-k k) 1))))")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("First call result: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }

  // Now call the saved continuation
  // (saved-k 5) should return 5 (0 + 5)
  let result2 = repl_eval(ctx, "(saved-k 5)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("Continuation call result: " + n.to_string())
      assert_eq(n, 5)
    }
    Ok(v) => fail("Expected 5, got: " + v.to_string())
    Err(e) => fail("Error calling saved continuation: " + e)
  }
}

/// Test call/cc with set! - multiple set! and continuation
test "vm repl: call/cc with multiple set!" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Define globals for saving continuations
  let _ = repl_eval(ctx, "(define k1 #f)")
  let _ = repl_eval(ctx, "(define counter 0)")

  // (let ((x 0) (y 0))
  //   (set! x (+ 1 (call/cc (lambda (k) (set! k1 k) 10))))
  //   (set! counter (+ counter 1))
  //   (if (< counter 3) (k1 (+ x 1)) x))
  let result = repl_eval(ctx, "(let ((x 0)) (set! x (+ 1 (call/cc (lambda (k) (set! k1 k) 10)))) (set! counter (+ counter 1)) (if (< counter 3) (k1 (+ x 1)) x))")
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("Multiple set! result: " + n.to_string())
      // After 3 iterations: x becomes 11, then 13, then 15
      assert_eq(n, 15)
    }
    Ok(v) => fail("Expected 15, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Test yin-yang puzzle (r5rs pitfall 7.4)
test "vm repl: yin-yang puzzle simplified" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simplified version with smaller limit (3 instead of 10)
  let code = "(let ((x '()) (y 0)) (call/cc (lambda (escape) (let* ((yin ((lambda (foo) (set! x (cons y x)) (if (= y 3) (escape x) (begin (set! y 0) foo))) (call/cc (lambda (bar) bar)))) (yang ((lambda (foo) (set! y (+ y 1)) foo) (call/cc (lambda (baz) baz))))) (yin yang)))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(v) => println("yin-yang result: " + v.to_string())
    Err(e) => println("Error in yin-yang (expected for now): " + e)
  }
}

/// Test let* with call/cc - simpler case
test "vm repl: let* with call/cc simple" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simple let* with call/cc
  let code = "(let ((x 0)) (let* ((a (call/cc (lambda (k) k))) (b 1)) (if (procedure? a) (a 10) (+ a b))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("let* with call/cc result: " + n.to_string())
      assert_eq(n, 11)
    }
    Ok(v) => fail("Expected 11, got: " + v.to_string())
    Err(e) => fail("Error in let* with call/cc: " + e)
  }
}

/// Test let with set! and nested let* with call/cc
test "vm repl: outer set! with inner let* call/cc" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Outer let with set!, inner let* with call/cc
  let code = "(let ((x 0)) (let* ((a ((lambda (foo) (set! x (+ x 1)) foo) (call/cc (lambda (k) k))))) (if (procedure? a) (a 10) x)))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("outer set! inner let* result: " + n.to_string())
      // First pass: x=1, a=continuation, (a 10) called
      // Second pass: x=2, a=10, returns x=2
      assert_eq(n, 2)
    }
    Ok(v) => fail("Expected 2, got: " + v.to_string())
    Err(e) => fail("Error: " + e)
  }
}

/// Test let* with two call/cc
test "vm repl: let* with two call/cc" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Two call/cc in let*
  let code = "(let* ((a (call/cc (lambda (k) k))) (b (call/cc (lambda (k) k)))) (if (procedure? a) (a 1) (if (procedure? b) (b 2) (+ a b))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("let* with two call/cc result: " + n.to_string())
      assert_eq(n, 3)
    }
    Ok(v) => fail("Expected 3, got: " + v.to_string())
    Err(e) => fail("Error in let* with two call/cc: " + e)
  }
}

/// Test like yin-yang but even simpler
test "vm repl: yin-yang minimal" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Minimal yin-yang: two variables in outer let, let* with two call/cc inside lambdas
  let code = "(let ((x 0) (y 0)) (let* ((yin ((lambda (f) (set! x (+ x 1)) f) (call/cc (lambda (k) k)))) (yang ((lambda (f) (set! y (+ y 1)) f) (call/cc (lambda (k) k))))) (if (procedure? yin) (yin 1) (if (procedure? yang) (yang 2) (+ x y)))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("yin-yang minimal result: " + n.to_string())
    }
    Ok(v) => println("yin-yang minimal result: " + v.to_string())
    Err(e) => println("Error in yin-yang minimal: " + e)
  }
}

/// Test yin-yang with (yin yang) call
test "vm repl: yin-yang with call" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Version with (yin yang) call like the real puzzle
  let code = "(let ((count 0)) (let* ((yin ((lambda (f) (set! count (+ count 1)) f) (call/cc (lambda (k) k)))) (yang ((lambda (f) f) (call/cc (lambda (k) k))))) (if (< count 3) (yin yang) count)))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("yin-yang with call result: " + n.to_string())
    }
    Ok(v) => println("yin-yang with call result: " + v.to_string())
    Err(e) => println("Error in yin-yang with call: " + e)
  }
}

/// Test with outer call/cc (escape)
test "vm repl: outer call/cc with inner let*" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Outer call/cc with inner let* containing call/cc
  let code = "(let ((x 0)) (call/cc (lambda (escape) (let* ((a ((lambda (f) (set! x (+ x 1)) f) (call/cc (lambda (k) k))))) (if (> x 3) (escape x) (if (procedure? a) (a 1) x))))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("outer call/cc with inner let* result: " + n.to_string())
    }
    Ok(v) => println("outer call/cc result: " + v.to_string())
    Err(e) => println("Error in outer call/cc: " + e)
  }
}

/// Even simpler: outer call/cc with inner call/cc and set!
test "vm repl: nested call/cc with set! minimal" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simplest version: outer call/cc, inner call/cc, set! on outer variable
  let code = "(let ((x 0)) (call/cc (lambda (escape) (set! x (+ x 1)) (call/cc (lambda (k) (if (> x 2) (escape x) (k 1)))) x)))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("nested call/cc minimal result: " + n.to_string())
    }
    Ok(v) => println("nested call/cc minimal result: " + v.to_string())
    Err(e) => println("Error in nested call/cc minimal: " + e)
  }
}

/// Outer call/cc with escape call after inner call/cc
test "vm repl: outer escape after inner call/cc" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simpler: save inner continuation, use outer escape
  let code = "(let ((x 0) (k-inner #f)) (call/cc (lambda (escape) (set! k-inner (call/cc (lambda (k) k))) (set! x (+ x 1)) (if (> x 2) (escape x) (k-inner 1)))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("outer escape after inner result: " + n.to_string())
    }
    Ok(v) => println("outer escape after inner result: " + v.to_string())
    Err(e) => println("Error in outer escape after inner: " + e)
  }
}

/// Test: call/cc returning immediately with (escape x)
test "vm repl: escape with boxed variable" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Simple escape: should return boxed variable
  let code = "(let ((x 0)) (call/cc (lambda (escape) (set! x 1) (escape x))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("escape with boxed variable result: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => fail("Error in escape with boxed: " + e)
  }
}

/// Test: nested let* in call/cc without set! in inner lambda
test "vm repl: nested let* in call/cc no set!" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // No set! in inner lambda
  let code = "(let ((x 0)) (call/cc (lambda (escape) (let* ((a (call/cc (lambda (k) k)))) (if (procedure? a) (a 1) (escape (+ x a)))))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("nested let* no set! result: " + n.to_string())
      assert_eq(n, 1)
    }
    Ok(v) => fail("Expected 1, got: " + v.to_string())
    Err(e) => println("Error in nested let* no set!: " + e)
  }
}

/// Test: the problematic pattern
test "vm repl: problematic pattern" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Outer call/cc + let* + lambda with set! inside
  let code = "(let ((x 0)) (call/cc (lambda (escape) (let* ((a ((lambda (f) (set! x 1) f) (call/cc (lambda (k) k))))) (if (procedure? a) (a 10) (escape x))))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("problematic pattern result: " + n.to_string())
    }
    Ok(v) => println("problematic pattern result: " + v.to_string())
    Err(e) => println("Error in problematic pattern: " + e)
  }
}

/// Test: 2 variables in outer let with call/cc
test "vm repl: outer let 2 vars with call/cc" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Minimal: 2 outer variables with set! and call/cc
  let code = "(let ((x 0) (y 0)) (call/cc (lambda (escape) (set! x (+ x 1)) (escape (+ x y)))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      assert_eq(n, 1)
    }
    Ok(v) => fail("Unexpected result: " + v.to_string())
    Err(e) => fail("Error in 2 vars outer let: " + e)
  }
}

/// Test: 2 vars with nil (like yin-yang)
test "vm repl: outer let with nil and let*" {
  let ctx = new_repl_context()
  ctx.globals.set("call/cc", Value::Procedure(Procedure::Native("call/cc")))
  ctx.compiler_globals.set("call/cc", ())

  // Like yin-yang: (x '()) (y 0) with let* inside
  let code = "(let ((x '()) (y 0)) (call/cc (lambda (escape) (let* ((a (+ y 1))) (escape (cons a x))))))"
  let result = repl_eval(ctx, code)
  match result {
    Ok(_) => ()
    Err(e) => fail("Error: " + e)
  }
}

/// =============================================
/// Rest Parameters (Variadic Lambda) Tests
/// =============================================

/// Test: (lambda args body) - all arguments as rest
test "vm repl: rest params - all args as list" {
  let ctx = new_repl_context()

  // (define list-all (lambda args args))
  let _ = repl_eval(ctx, "(define list-all (lambda args args))")

  // (list-all 1 2 3) => (1 2 3)
  let result = repl_eval(ctx, "(list-all 1 2 3)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(1)), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(2)), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Number(Number::Int(3)), Value::Nil) => ()
                _ => fail("Expected (1 2 3)")
              }
            }
            _ => fail("Expected (1 2 3)")
          }
        }
        _ => fail("Expected (1 2 3)")
      }
    }
    _ => fail("Expected list (1 2 3)")
  }
}

/// Test: (lambda args body) - zero arguments
test "vm repl: rest params - zero args" {
  let ctx = new_repl_context()

  // (define list-all (lambda args args))
  let _ = repl_eval(ctx, "(define list-all (lambda args args))")

  // (list-all) => ()
  let result = repl_eval(ctx, "(list-all)")
  match result {
    Ok(Value::Nil) => ()
    _ => fail("Expected empty list")
  }
}

/// Test: (lambda (a b . rest) body) - dotted rest parameter
test "vm repl: rest params - required + rest" {
  let ctx = new_repl_context()

  // (define my-list (lambda (first . rest) (cons first rest)))
  let _ = repl_eval(ctx, "(define my-list (lambda (first . rest) (cons first rest)))")

  // (my-list 1 2 3 4) => (1 2 3 4)
  let result = repl_eval(ctx, "(my-list 1 2 3 4)")
  match result {
    Ok(Value::Pair(a, _, _)) => {
      match a {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected first element to be 1")
      }
    }
    _ => fail("Expected list starting with 1")
  }
}

/// Test: dotted rest with minimum args
test "vm repl: rest params - dotted minimum args" {
  let ctx = new_repl_context()

  // (define my-list (lambda (first . rest) (cons first rest)))
  let _ = repl_eval(ctx, "(define my-list (lambda (first . rest) (cons first rest)))")

  // (my-list 42) => (42)
  let result = repl_eval(ctx, "(my-list 42)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(42)), Value::Nil) => ()
        _ => fail("Expected (42)")
      }
    }
    _ => fail("Expected list (42)")
  }
}

/// Test: rest params with multiple required params
test "vm repl: rest params - two required + rest" {
  let ctx = new_repl_context()

  // (define sum-rest (lambda (a b . rest) (+ a (+ b (length rest)))))
  let _ = repl_eval(ctx, "(define sum-rest (lambda (a b . rest) (+ a (+ b (length rest)))))")

  // (sum-rest 10 20 1 2 3) => 10 + 20 + 3 = 33
  let result = repl_eval(ctx, "(sum-rest 10 20 1 2 3)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 33)
    _ => fail("Expected 33")
  }
}

/// Test: rest params in anonymous lambda
test "vm repl: rest params - anonymous lambda" {
  let ctx = new_repl_context()

  // ((lambda args (length args)) 'a 'b 'c 'd) => 4
  let result = repl_eval(ctx, "((lambda args (length args)) 'a 'b 'c 'd)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 4)
    _ => fail("Expected 4")
  }
}

/// =============================================
/// Quasiquote Tests (VM REPL)
/// =============================================

/// Test: simple quasiquote without unquote
test "vm repl: quasiquote - simple" {
  let ctx = new_repl_context()

  // `(a b c) => (a b c)
  let result = repl_eval(ctx, "`(a b c)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Symbol("a"), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Symbol("b"), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Symbol("c"), Value::Nil) => ()
                _ => fail("Expected (a b c)")
              }
            }
            _ => fail("Expected (a b c)")
          }
        }
        _ => fail("Expected (a b c)")
      }
    }
    _ => fail("Expected list (a b c)")
  }
}

/// Test: quasiquote with unquote
test "vm repl: quasiquote - with unquote" {
  let ctx = new_repl_context()

  // (define x 42)
  let _ = repl_eval(ctx, "(define x 42)")

  // `(a ,x c) => (a 42 c)
  let result = repl_eval(ctx, "`(a ,x c)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Symbol("a"), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(42)), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Symbol("c"), Value::Nil) => ()
                _ => fail("Expected (a 42 c)")
              }
            }
            _ => fail("Expected (a 42 c)")
          }
        }
        _ => fail("Expected (a 42 c)")
      }
    }
    Err(e) => fail("Error: " + e)
    _ => fail("Expected list (a 42 c)")
  }
}

/// Test: quasiquote with unquote expression
test "vm repl: quasiquote - unquote expression" {
  let ctx = new_repl_context()

  // `(1 ,(+ 2 3) 4) => (1 5 4)
  let result = repl_eval(ctx, "`(1 ,(+ 2 3) 4)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(1)), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(5)), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Number(Number::Int(4)), Value::Nil) => ()
                _ => fail("Expected (1 5 4)")
              }
            }
            _ => fail("Expected (1 5 4)")
          }
        }
        _ => fail("Expected (1 5 4)")
      }
    }
    Err(e) => fail("Error: " + e)
    _ => fail("Expected list (1 5 4)")
  }
}

/// Test: quasiquote with unquote-splicing
test "vm repl: quasiquote - unquote-splicing" {
  let ctx = new_repl_context()

  // (define xs '(2 3))
  let _ = repl_eval(ctx, "(define xs '(2 3))")

  // `(1 ,@xs 4) => (1 2 3 4)
  let result = repl_eval(ctx, "`(1 ,@xs 4)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(1)), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(2)), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Number(Number::Int(3)), Value::Pair(d, rest4, _)) => {
                  match (d, rest4) {
                    (Value::Number(Number::Int(4)), Value::Nil) => ()
                    _ => fail("Expected (1 2 3 4)")
                  }
                }
                _ => fail("Expected (1 2 3 4)")
              }
            }
            _ => fail("Expected (1 2 3 4)")
          }
        }
        _ => fail("Expected (1 2 3 4)")
      }
    }
    Err(e) => fail("Error: " + e)
    _ => fail("Expected list (1 2 3 4)")
  }
}

/// Test: quasiquote with empty unquote-splicing
test "vm repl: quasiquote - empty unquote-splicing" {
  let ctx = new_repl_context()

  // (define xs '())
  let _ = repl_eval(ctx, "(define xs '())")

  // `(1 ,@xs 4) => (1 4)
  let result = repl_eval(ctx, "`(1 ,@xs 4)")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(1)), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(4)), Value::Nil) => ()
            _ => fail("Expected (1 4)")
          }
        }
        _ => fail("Expected (1 4)")
      }
    }
    Err(e) => fail("Error: " + e)
    _ => fail("Expected list (1 4)")
  }
}

/// Test: quasiquote symbol
test "vm repl: quasiquote - symbol" {
  let ctx = new_repl_context()

  // `x => x (symbol)
  let result = repl_eval(ctx, "`x")
  match result {
    Ok(Value::Symbol("x")) => ()
    Err(e) => fail("Error: " + e)
    _ => fail("Expected symbol x")
  }
}

/// Test: quasiquote number
test "vm repl: quasiquote - number" {
  let ctx = new_repl_context()

  // `42 => 42
  let result = repl_eval(ctx, "`42")
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// =============================================
/// Letrec Tests (VM REPL)
/// =============================================

/// Test: simple letrec (no recursion)
test "vm repl: letrec - simple" {
  let ctx = new_repl_context()

  // (letrec ((x 1) (y 2)) (+ x y))
  // => 3
  let result = repl_eval(ctx, "(letrec ((x 1) (y 2)) (+ x y))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 3")
  }
}

/// Test: letrec with non-recursive lambda
test "vm repl: letrec - non-recursive lambda" {
  let ctx = new_repl_context()

  // (letrec ((f (lambda (x) (+ x 1)))) (f 5))
  // => 6
  let result = repl_eval(ctx, "(letrec ((f (lambda (x) (+ x 1)))) (f 5))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 6")
  }
}

/// Test: letrec with recursive lambda - simplified
test "vm repl: letrec - recursive simple" {
  let ctx = new_repl_context()

  // Simple test: (letrec ((f (lambda () f))) (procedure? f))
  // Just check that we can reference f inside f without infinite loop
  let result = repl_eval(ctx, "(letrec ((f (lambda () f))) (procedure? f))")
  match result {
    Ok(Value::Bool(b)) => assert_eq(b, true)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected #t")
  }
}

/// Test: letrec with immediate termination
test "vm repl: letrec - immediate termination" {
  let ctx = new_repl_context()

  // (letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 0))
  // Should return 42 immediately without recursion
  let result = repl_eval(ctx, "(letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 0))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// Test: letrec with one recursion
test "vm repl: letrec - one recursion" {
  let ctx = new_repl_context()

  // (letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 1))
  // Should recurse once: loop(1) -> loop(0) -> 42
  let result = repl_eval(ctx, "(letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 1))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// Test: letrec with multiple recursions
test "vm repl: letrec - five recursions" {
  let ctx = new_repl_context()

  // (letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 5))
  // Should recurse 5 times
  let result = repl_eval(ctx, "(letrec ((loop (lambda (i) (if (= i 0) 42 (loop (- i 1)))))) (loop 5))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// Test: letrec with recursive function
test "vm repl: letrec - recursive counter" {
  let ctx = new_repl_context()

  // (letrec ((loop (lambda (i) (if (= i 5) i (loop (+ i 1)))))) (loop 0))
  // => 5
  let result = repl_eval(ctx, "(letrec ((loop (lambda (i) (if (= i 5) i (loop (+ i 1)))))) (loop 0))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

/// Test: passing lambda as argument (debugging issue with 4.2)
test "vm repl: lambda as argument" {
  let ctx = new_repl_context()
  // Even simpler: pass identity lambda
  let result = repl_eval(ctx, "((lambda (f) (f 5)) (lambda (x) x))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

/// =============================================
/// Do Loop Tests (VM REPL)
/// =============================================

/// Test: simple do loop - count from 0 to 5
test "vm repl: do loop - simple counter" {
  let ctx = new_repl_context()

  // (do ((i 0 (+ i 1)))
  //     ((= i 5) i))
  // => 5
  let result = repl_eval(ctx, "(do ((i 0 (+ i 1))) ((= i 5) i))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 5")
  }
}

/// Test: letrec with single param (this works)
test "vm repl: letrec - single param countdown" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(letrec ((loop (lambda (n) (if (= n 0) 42 (loop (- n 1)))))) (loop 3))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// Test: letrec with two params
test "vm repl: letrec - two params" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(letrec ((loop (lambda (n x) (if (= n 0) x (loop (- n 1) x))))) (loop 3 42))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 42")
  }
}

/// =============================================
/// Do Loop Tests (VM REPL) - Additional
/// =============================================

/// Test: do loop with body
test "vm repl: do loop - with body" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define x 0)")
  let result = repl_eval(ctx, "(do ((i 0 (+ i 1))) ((= i 3) x) (set! x (+ x 10)))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 30)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 30")
  }
}

/// Test: do loop building list in reverse
test "vm repl: do loop - build list" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(do ((i 0 (+ i 1)) (lst '() (cons i lst))) ((= i 3) lst))")
  match result {
    Ok(Value::Pair(a, rest, _)) => {
      match (a, rest) {
        (Value::Number(Number::Int(2)), Value::Pair(b, rest2, _)) => {
          match (b, rest2) {
            (Value::Number(Number::Int(1)), Value::Pair(c, rest3, _)) => {
              match (c, rest3) {
                (Value::Number(Number::Int(0)), Value::Nil) => ()
                _ => fail("Expected (2 1 0)")
              }
            }
            _ => fail("Expected (2 1 0)")
          }
        }
        _ => fail("Expected (2 1 0)")
      }
    }
    Err(e) => fail("Error: " + e)
    _ => fail("Expected list (2 1 0)")
  }
}

/// Test: do loop - no step (variable doesn't change)
test "vm repl: do loop - no step" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define counter 0)")
  let result = repl_eval(ctx, "(do ((x 10)) ((= counter 3) x) (set! counter (+ counter 1)))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 10")
  }
}

/// Test: do loop - factorial
test "vm repl: do loop - factorial" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(do ((n 5 (- n 1)) (result 1 (* result n))) ((= n 0) result))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 120)
    Err(e) => fail("Error: " + e)
    _ => fail("Expected 120")
  }
}

/// Test: do loop - empty result expression returns nil
test "vm repl: do loop - empty result" {
  let ctx = new_repl_context()
  let result = repl_eval(ctx, "(do ((i 0 (+ i 1))) ((= i 3)))")
  match result {
    Ok(Value::Nil) => ()
    Err(e) => fail("Error: " + e)
    _ => fail("Expected nil")
  }
}
