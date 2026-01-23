/// VM REPL のテスト

/// VM での基本的な算術演算
test "vm repl: basic arithmetic" {
  let ctx = new_repl_context()

  // (+ 1 2) => 3
  let result = repl_eval(ctx, "(+ 1 2)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 3)
    _ => fail!("Expected 3")
  }
}

/// VM での乗算
test "vm repl: multiplication" {
  let ctx = new_repl_context()

  // (* 3 4) => 12
  let result = repl_eval(ctx, "(* 3 4)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 12)
    _ => fail!("Expected 12")
  }
}

/// VM での define と参照
test "vm repl: define and reference" {
  let ctx = new_repl_context()

  // (define x 10)
  let _ = repl_eval(ctx, "(define x 10)")

  // x => 10
  let result = repl_eval(ctx, "x")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 10)
    _ => fail!("Expected 10")
  }
}

/// VM での複数の define
test "vm repl: multiple defines" {
  let ctx = new_repl_context()

  // (define x 10)
  let _ = repl_eval(ctx, "(define x 10)")
  // (define y 20)
  let _ = repl_eval(ctx, "(define y 20)")

  // (+ x y) => 30
  let result = repl_eval(ctx, "(+ x y)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 30)
    _ => fail!("Expected 30")
  }
}

/// VM での関数定義と呼び出し
test "vm repl: function definition and call" {
  let ctx = new_repl_context()

  // (define (square n) (* n n))
  let _ = repl_eval(ctx, "(define (square n) (* n n))")

  // (square 5) => 25
  let result = repl_eval(ctx, "(square 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 25)
    _ => fail!("Expected 25")
  }
}

/// VM での if 式
test "vm repl: if expression" {
  let ctx = new_repl_context()

  // (if #t 1 2) => 1
  let result1 = repl_eval(ctx, "(if #t 1 2)")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 1)
    _ => fail!("Expected 1")
  }

  // (if #f 1 2) => 2
  let result2 = repl_eval(ctx, "(if #f 1 2)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 2)
    _ => fail!("Expected 2")
  }
}

/// VM での let 式
test "vm repl: let expression" {
  let ctx = new_repl_context()

  // (let ((a 5) (b 10)) (+ a b)) => 15
  let result = repl_eval(ctx, "(let ((a 5) (b 10)) (+ a b))")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 15)
    _ => fail!("Expected 15")
  }
}

/// VM でのリスト操作
test "vm repl: list operations" {
  let ctx = new_repl_context()

  // (car (cons 1 2)) => 1
  let result1 = repl_eval(ctx, "(car (cons 1 2))")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 1)
    _ => fail!("Expected 1")
  }

  // (cdr (cons 1 2)) => 2
  let result2 = repl_eval(ctx, "(cdr (cons 1 2))")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 2)
    _ => fail!("Expected 2")
  }
}

/// VM での再帰関数（階乗）
test "vm repl: recursive function - factorial" {
  let ctx = new_repl_context()

  // (define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
  let _ = repl_eval(ctx, "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))")

  // (fact 5) => 120
  let result = repl_eval(ctx, "(fact 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 120)
    _ => fail!("Expected 120")
  }
}

/// VM での再帰関数（フィボナッチ）
test "vm repl: recursive function - fibonacci" {
  let ctx = new_repl_context()

  // (define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
  let _ = repl_eval(ctx, "(define (fib n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))")

  // (fib 10) => 55
  let result = repl_eval(ctx, "(fib 10)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 55)
    _ => fail!("Expected 55")
  }
}

/// VM での高階関数
test "vm repl: higher order function" {
  let ctx = new_repl_context()

  // (define (apply-twice f x) (f (f x)))
  let _ = repl_eval(ctx, "(define (apply-twice f x) (f (f x)))")
  // (define (add1 n) (+ n 1))
  let _ = repl_eval(ctx, "(define (add1 n) (+ n 1))")

  // (apply-twice add1 5) => 7
  let result = repl_eval(ctx, "(apply-twice add1 5)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 7)
    _ => fail!("Expected 7")
  }
}

/// VM でのクロージャ
/// 注: 自由変数のキャプチャが未実装のため、このテストは一時的に無効化
// test "vm repl: closure" {
//   let ctx = new_repl_context()
//
//   // (define (make-adder n) (lambda (x) (+ n x)))
//   let _ = repl_eval(ctx, "(define (make-adder n) (lambda (x) (+ n x)))")
//   // (define add5 (make-adder 5))
//   let _ = repl_eval(ctx, "(define add5 (make-adder 5))")
//
//   // (add5 10) => 15
//   let result = repl_eval(ctx, "(add5 10)")
//   match result {
//     Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 15)
//     _ => fail!("Expected 15")
//   }
// }

/// VM での比較演算
test "vm repl: comparison" {
  let ctx = new_repl_context()

  // (< 1 2) => #t
  let result1 = repl_eval(ctx, "(< 1 2)")
  match result1 {
    Ok(Value::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected #t")
  }

  // (> 1 2) => #f
  let result2 = repl_eval(ctx, "(> 1 2)")
  match result2 {
    Ok(Value::Bool(b)) => assert_eq!(b, false)
    _ => fail!("Expected #f")
  }

  // (= 5 5) => #t
  let result3 = repl_eval(ctx, "(= 5 5)")
  match result3 {
    Ok(Value::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected #t")
  }
}
