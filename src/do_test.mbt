/// do ループのテスト

/// 基本的な do ループ（カウントアップ）
test "do loop basic counting" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((= i 5) i))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail!("expected 5")
  }
}

/// do ループでリストを構築
test "do loop building list" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1)) (lst () (cons i lst))) ((= i 3) lst))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail!("expected a list")
  }
}

/// do ループの終了条件式なし（Nil を返す）
test "do loop no result expression" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((= i 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail!("expected Nil")
  }
}

/// do ループでコマンドを実行
test "do loop with commands" {
  let env = initial_env()
  // コマンドを実行するが、結果には影響しない
  let expr = parse_one("(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 4) sum) (+ 1 1))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => () // 0+1+2+3=6
    _ => fail!("expected 6")
  }
}

/// do ループの初期化のみ（ステップ式なし）
test "do loop without step" {
  let env = initial_env()
  let expr = parse_one("(do ((x 10)) (#t x))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail!("expected 10")
  }
}

/// do ループで複数変数を使用
test "do loop multiple variables" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(10))) => () // 0+1+2+3+4=10
    _ => fail!("expected 10")
  }
}

/// do ループで早期終了
test "do loop early exit" {
  let env = initial_env()
  let expr = parse_one("(do ((i 0 (+ i 1))) ((> i 3) i))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail!("expected 4")
  }
}
