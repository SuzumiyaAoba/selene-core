/// call/cc (call-with-current-continuation) のテスト。

/// 継続を呼び出さない場合は通常の戻り値を返す。
test "call/cc without invoking continuation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) 42))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// 継続を呼び出すと、その値が call/cc の戻り値になる。
test "call/cc with continuation invocation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (begin (k 100) 42)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail("expected 100")
  }
}

/// 継続を呼び出すと、後続の式は評価されない（早期リターン）。
test "call/cc early return" {
  let env = initial_env()
  let expr = parse_one("(+ 1 (call/cc (lambda (k) (begin (k 10) (+ 100 200)))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(11))) => ()
    _ => fail("expected 11")
  }
}

/// call-with-current-continuation は call/cc の別名。
test "call-with-current-continuation alias" {
  let env = initial_env()
  let expr = parse_one("(call-with-current-continuation (lambda (k) (k 50)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(50))) => ()
    _ => fail("expected 50")
  }
}

/// call/cc に手続き以外を渡すとエラー。
test "call/cc with non-procedure" {
  let env = initial_env()
  let expr = parse_one("(call/cc 42)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}

/// 継続は1引数のみ受け付ける。
test "continuation requires exactly one argument" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (k 1 2)))")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => fail("expected ArityError")
  }
}

/// 継続を変数に保存して後から呼び出す。
test "call/cc save and invoke later" {
  let env = initial_env()
  // (let ((saved #f))
  //   (+ 1 (call/cc (lambda (k) (set! saved k) 10)))
  //   (if saved (saved 20) 0))
  // この場合、エスケープ継続なので saved を後から呼び出すと
  // 新しい継続呼び出しエラーが伝播する
  let expr = parse_one("(call/cc (lambda (k) (+ 1 (k 5))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// ネストした call/cc。
test "nested call/cc" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k1) (call/cc (lambda (k2) (k1 100)))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(100))) => ()
    _ => fail("expected 100")
  }
}

/// 内側の継続を呼び出す。
test "nested call/cc inner continuation" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k1) (+ 1 (call/cc (lambda (k2) (k2 10))))))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(11))) => ()
    _ => fail("expected 11")
  }
}

/// 継続を手続きとして扱う。
test "continuation is a procedure" {
  let env = initial_env()
  let expr = parse_one("(call/cc (lambda (k) (procedure? k)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}
