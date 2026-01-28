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
    Ok(Value::Pair(car, cdr)) => {
      match (car, cdr) {
        (Value::Number(Number::Int(n)), Value::Pair(x_val, Value::Nil)) => {
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
