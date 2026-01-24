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

/// VM でのクロージャ - 単純なケース
test "vm repl: simple closure" {
  let ctx = new_repl_context()

  // ((lambda (x) x) 5) => 5
  let result1 = repl_eval(ctx, "((lambda (x) x) 5)")
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("identity result = " + n.to_string())
      assert_eq!(n, 5)
    }
    Ok(v) => fail!("Expected 5, got: " + v.to_string())
    Err(e) => fail!("Error: " + e)
  }

  // ((lambda (x) (+ x 1)) 5) => 6
  let result2 = repl_eval(ctx, "((lambda (x) (+ x 1)) 5)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("add1 result = " + n.to_string())
      assert_eq!(n, 6)
    }
    Ok(v) => fail!("Expected 6, got: " + v.to_string())
    Err(e) => fail!("Error: " + e)
  }
}

/// VM でのネストされたクロージャ
test "vm repl: nested closure" {
  let ctx = new_repl_context()

  // まず、返すだけのネストされたクロージャ
  // ((lambda (n) (lambda (x) x)) 5) => #<procedure>
  let result1 = repl_eval(ctx, "((lambda (n) (lambda (x) x)) 5)")
  match result1 {
    Ok(Value::Procedure(_)) => println("inner lambda returned")
    Ok(v) => fail!("Expected procedure, got: " + v.to_string())
    Err(e) => fail!("Error in step 1: " + e)
  }

  // 次に、外側のパラメータを返すだけ
  // ((lambda (n) (lambda (x) n)) 5) => #<procedure>
  let result2a = repl_eval(ctx, "((lambda (n) (lambda (x) n)) 5)")
  match result2a {
    Ok(Value::Procedure(_)) => println("outer param lambda created")
    Ok(v) => fail!("Expected procedure in 2a, got: " + v.to_string())
    Err(e) => fail!("Error in step 2a: " + e)
  }

  // 外側のパラメータを参照 - 段階的にテスト
  // step 2b: 内側の closure を呼び出す（引数を使わない）
  let result2b = repl_eval(ctx, "(((lambda (n) (lambda (x) 42)) 5) 10)")
  match result2b {
    Ok(Value::Number(Number::Int(n))) => {
      println("constant result = " + n.to_string())
      assert_eq!(n, 42)
    }
    Ok(v) => fail!("Expected 42, got: " + v.to_string())
    Err(e) => fail!("Error in step 2b: " + e)
  }

  // step 2c: 内側の closure で引数を使う
  let result2c = repl_eval(ctx, "(((lambda (n) (lambda (x) x)) 5) 10)")
  match result2c {
    Ok(Value::Number(Number::Int(n))) => {
      println("inner param result = " + n.to_string())
      assert_eq!(n, 10)
    }
    Ok(v) => fail!("Expected 10, got: " + v.to_string())
    Err(e) => fail!("Error in step 2c: " + e)
  }

  // step 2: 外側のパラメータを参照
  // (((lambda (n) (lambda (x) n)) 5) 10) => 5
  let result2 = repl_eval(ctx, "(((lambda (n) (lambda (x) n)) 5) 10)")
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("outer param reference = " + n.to_string())
      assert_eq!(n, 5)
    }
    Ok(v) => fail!("Expected 5, got: " + v.to_string())
    Err(e) => fail!("Error in step 2: " + e)
  }

  // 最後に、両方を使う
  // (((lambda (n) (lambda (x) (+ n x))) 5) 10) => 15
  let result3 = repl_eval(ctx, "(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("nested closure result = " + n.to_string())
      assert_eq!(n, 15)
    }
    Ok(v) => fail!("Expected 15, got: " + v.to_string())
    Err(e) => fail!("Error in step 3: " + e)
  }
}

/// シンプルな2引数関数テスト（クロージャなし）
test "vm: simple two arg function" {
  // クロージャを使わない単純な2引数関数
  let expr = parse_one("((lambda (a b) (+ a b)) 5 10)")
  let result = vm_eval(expr)
  match result {
    Ok(Value::Number(Number::Int(n))) => {
      println("simple (+ a b) = " + n.to_string())
      assert_eq!(n, 15)
    }
    Ok(v) => fail!("Expected 15, got: " + v.to_string())
    Err(e) => fail!("Error: " + e)
  }
}

/// list を使ったキャプチャ/パラメータアクセス
test "vm: list capture vs param" {
  // (list n x) で両方の値を確認
  let expr = parse_one("(((lambda (n) (lambda (x) (list n x))) 5) 10)")
  let result = vm_eval(expr)
  match result {
    Ok(Value::Pair(car, cdr)) => {
      match (car, cdr) {
        (Value::Number(Number::Int(n)), Value::Pair(x_val, Value::Nil)) => {
          match x_val {
            Value::Number(Number::Int(x)) => {
              println("list: n = " + n.to_string() + ", x = " + x.to_string())
              assert_eq!(n, 5)
              assert_eq!(x, 10)
            }
            _ => fail!("x is not a number")
          }
        }
        _ => fail!("Unexpected list structure")
      }
    }
    Ok(v) => fail!("Expected list, got: " + v.to_string())
    Err(e) => fail!("Error: " + e)
  }
}

/// PrimOp 内でのキャプチャ/パラメータアクセス
test "vm: primop capture vs param" {
  // キャプチャ + 定数
  let expr1 = parse_one("(((lambda (n) (lambda (x) (+ n 0))) 5) 10)")
  let result1 = vm_eval(expr1)
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ n 0) = " + n.to_string())
      assert_eq!(n, 5)
    }
    Ok(v) => fail!("Expected 5, got: " + v.to_string())
    Err(e) => fail!("Error in (+ n 0): " + e)
  }

  // 定数 + パラメータ
  let expr2 = parse_one("(((lambda (n) (lambda (x) (+ 0 x))) 5) 10)")
  let result2 = vm_eval(expr2)
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ 0 x) = " + n.to_string())
      assert_eq!(n, 10)
    }
    Ok(v) => fail!("Expected 10, got: " + v.to_string())
    Err(e) => fail!("Error in (+ 0 x): " + e)
  }

  // キャプチャ + パラメータ
  let expr3 = parse_one("(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  let result3 = vm_eval(expr3)
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("(+ n x) = " + n.to_string())
      assert_eq!(n, 15)
    }
    Ok(v) => fail!("Expected 15, got: " + v.to_string())
    Err(e) => fail!("Error in (+ n x): " + e)
  }
}

/// キャプチャのデバッグテスト
test "vm: capture debug" {
  // キャプチャした n だけを返す
  let expr1 = parse_one("(((lambda (n) (lambda (x) n)) 5) 10)")
  let result1 = vm_eval(expr1)
  match result1 {
    Ok(Value::Number(Number::Int(n))) => {
      println("captured n = " + n.to_string())
      assert_eq!(n, 5)
    }
    Ok(v) => fail!("Expected 5, got: " + v.to_string())
    Err(e) => fail!("Error getting n: " + e)
  }

  // パラメータ x だけを返す
  let expr2 = parse_one("(((lambda (n) (lambda (x) x)) 5) 10)")
  let result2 = vm_eval(expr2)
  match result2 {
    Ok(Value::Number(Number::Int(n))) => {
      println("param x = " + n.to_string())
      assert_eq!(n, 10)
    }
    Ok(v) => fail!("Expected 10, got: " + v.to_string())
    Err(e) => fail!("Error getting x: " + e)
  }

  // n と x を加算
  let expr3 = parse_one("(((lambda (n) (lambda (x) (+ n x))) 5) 10)")
  let result3 = vm_eval(expr3)
  match result3 {
    Ok(Value::Number(Number::Int(n))) => {
      println("n + x = " + n.to_string())
      assert_eq!(n, 15)
    }
    Ok(v) => fail!("Expected 15, got: " + v.to_string())
    Err(e) => fail!("Error in n+x: " + e)
  }
}

/// REPL でのクロージャキャプチャ（単独テスト）
test "vm repl: isolated capture test" {
  let ctx = new_repl_context()

  // キャプチャのみを使う場合
  let result = repl_eval(ctx, "(((lambda (n) (lambda (x) n)) 5) 10)")
  match result {
    Ok(Value::Number(Number::Int(n))) => assert_eq!(n, 5)
    Ok(v) => fail!("Expected 5, got: " + v.to_string())
    Err(e) => fail!("Error: " + e)
  }
}

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
