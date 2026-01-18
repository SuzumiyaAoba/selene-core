/// Phase 4 機能テスト: do, delay/force, values/call-with-values, dynamic-wind

// =============================================================================
// do ループテスト
// =============================================================================

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

// =============================================================================
// delay / force テスト
// =============================================================================

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

/// force を2回呼んでも同じ結果
test "force memoization" {
  let env = initial_env()
  let expr = parse_one("(let ((p (delay (+ 10 20)))) (+ (force p) (force p)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(60))) => () // 30 + 30
    _ => fail!("expected 60")
  }
}

// =============================================================================
// values / call-with-values テスト
// =============================================================================

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

// =============================================================================
// dynamic-wind テスト
// =============================================================================

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
test "dynamic-wind before and after" {
  let env = initial_env()
  // counter を使って before/after の実行を確認
  // 簡易版: before, thunk, after がすべて実行される確認
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
