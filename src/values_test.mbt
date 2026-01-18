/// 多値 (values/call-with-values) のテスト

/// 単一値を返す values
test "values single value" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 42)) (lambda (x) x))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail!("expected 42")
  }
}

/// 複数値を返す values
test "values multiple values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2 3)) (lambda (a b c) (+ a (+ b c))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => () // 1 + 2 + 3
    _ => fail!("expected 6")
  }
}

/// 値なしの values（ゼロ個の値）
test "values no values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values)) (lambda () 99))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(99))) => ()
    _ => fail!("expected 99")
  }
}

/// プロデューサが通常の値を返す場合
test "call-with-values with normal value producer" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () 42) (lambda (x) (* x 2)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(84))) => ()
    _ => fail!("expected 84")
  }
}

/// 複数値を使った計算
test "multiple values computation" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 10 20)) (lambda (a b) (- a b)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(-10))) => ()
    _ => fail!("expected -10")
  }
}

/// 2つの値をスワップ
test "swap two values" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2)) (lambda (a b) (values b a)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::MultipleValues(vals)) => {
      if vals.length() == 2 {
        match (vals[0], vals[1]) {
          (Value::Number(Number::Int(2)), Value::Number(Number::Int(1))) => ()
          _ => fail!("expected (2 1)")
        }
      } else {
        fail!("expected 2 values")
      }
    }
    _ => fail!("expected multiple values")
  }
}

/// values を consumer で処理
test "values with list construction" {
  let env = initial_env()
  let expr = parse_one("(call-with-values (lambda () (values 1 2 3)) list)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail!("expected a list")
  }
}
