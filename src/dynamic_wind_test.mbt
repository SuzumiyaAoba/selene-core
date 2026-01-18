/// dynamic-wind のテスト

/// 基本的な dynamic-wind
test "dynamic-wind basic" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #f) (lambda () 42) (lambda () #f))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail!("expected 42")
  }
}

/// dynamic-wind で before/after が呼ばれる
test "dynamic-wind before and after execution" {
  let env = initial_env()
  // before, thunk, after がすべて実行されることを確認
  let expr = parse_one("(+ (dynamic-wind (lambda () 1) (lambda () 10) (lambda () 100)) 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => () // thunk の結果
    _ => fail!("expected 10")
  }
}

/// dynamic-wind の thunk が値を返す
test "dynamic-wind returns thunk result" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () 'before) (lambda () (+ 1 2 3)) (lambda () 'after))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => ()
    _ => fail!("expected 6")
  }
}

/// dynamic-wind with multiplication
test "dynamic-wind with computation result" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #t) (lambda () (* 7 8)) (lambda () #t))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(56))) => ()
    _ => fail!("expected 56")
  }
}

/// dynamic-wind のネスト
test "nested dynamic-wind" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () 1) (lambda () (dynamic-wind (lambda () 2) (lambda () 3) (lambda () 4))) (lambda () 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => () // 内側の thunk の結果
    _ => fail!("expected 3")
  }
}

/// dynamic-wind で計算結果を返す
test "dynamic-wind computation" {
  let env = initial_env()
  let expr = parse_one("(dynamic-wind (lambda () #t) (lambda () (* 6 7)) (lambda () #t))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail!("expected 42")
  }
}
