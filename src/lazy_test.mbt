/// 遅延評価 (delay/force) のテスト

/// 基本的な delay と force
test "delay and force basic" {
  let env = initial_env()
  let expr = parse_one("(force (delay (+ 1 2)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail!("expected 3")
  }
}

/// promise? 述語
test "promise? predicate" {
  let env = initial_env()
  let expr = parse_one("(promise? (delay 42))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t")
  }
}

/// 非プロミスに対する promise?
test "promise? with non-promise" {
  let env = initial_env()
  let expr = parse_one("(promise? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail!("expected #f")
  }
}

/// delay されたプロミスは force するまで評価されない
test "delay is lazy" {
  let env = initial_env()
  // プロミスを作成するが、force しない
  let expr = parse_one("(let ((p (delay (/ 1 0)))) #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail!("expected #t (no error because delay is lazy)")
  }
}

/// force を2回呼んでも同じ結果（メモ化）
test "force memoization" {
  let env = initial_env()
  let expr = parse_one("(let ((p (delay (+ 10 20)))) (+ (force p) (force p)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(60))) => () // 30 + 30
    _ => fail!("expected 60")
  }
}

/// プロミス以外の値を force すると、そのまま返す
test "force non-promise" {
  let env = initial_env()
  let expr = parse_one("(force 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail!("expected 42")
  }
}

/// ネストした delay
test "nested delay" {
  let env = initial_env()
  let expr = parse_one("(force (force (delay (delay 100))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail!("expected 100")
  }
}

/// delay で変数を参照
test "delay with variable reference" {
  let env = initial_env()
  let expr = parse_one("(let ((x 10)) (force (delay x)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail!("expected 10")
  }
}
