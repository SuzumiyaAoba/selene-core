/// cond 特殊形式のテスト

/// cond の基本的な動作（最初の節が真）
test "cond basic - first clause true" {
  let env = initial_env()
  let expr = parse_one("(cond (#t 1) (#f 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 1)
    _ => fail("Expected Int(1)")
  }
}

/// cond で2番目の節が真
test "cond second clause true" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#t 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// cond の else 節
test "cond else clause" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#f 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// cond で条件式を評価
test "cond with evaluated test" {
  let env = initial_env()
  let expr = parse_one("(cond ((= 1 1) 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// cond で複数の式を評価
test "cond with multiple expressions in body" {
  let env = initial_env()
  let expr = parse_one("(cond (#t (+ 1 2) (* 3 4)) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 12)
    _ => fail("Expected Int(12)")
  }
}

/// cond で body が空の場合、test の値を返す
test "cond returns test value when body is empty" {
  let env = initial_env()
  let expr = parse_one("(cond ((+ 1 2)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// cond ですべての節が偽（else なし）
test "cond all clauses false without else" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (#f 2))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// cond で数値の大小を判定
test "cond with numeric comparison" {
  let env = initial_env()
  let expr = parse_one("(cond ((< 5 3) 1) ((> 5 3) 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// ネストされた cond
test "cond nested" {
  let env = initial_env()
  let expr = parse_one("(cond (#t (cond (#f 1) (else 2))) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// cond で変数を使用
test "cond with variables" {
  let env = initial_env()
  let expr = parse_one("(let ((x 5)) (cond ((< x 3) 1) ((< x 7) 2) (else 3)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// cond で複雑な条件
test "cond with complex conditions" {
  let env = initial_env()
  let expr = parse_one("(cond ((and #f #t) 1) ((or #f #t) 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}

/// cond で0も真として扱う
test "cond treats zero as true" {
  let env = initial_env()
  let expr = parse_one("(cond (0 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// cond で空リストも真として扱う
test "cond treats empty list as true" {
  let env = initial_env()
  let expr = parse_one("(cond (() 42) (else 0))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 42)
    _ => fail("Expected Int(42)")
  }
}

/// cond で #f のみが偽
test "cond only false is false" {
  let env = initial_env()
  let expr = parse_one("(cond (#f 1) (1 2) (else 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 2)
    _ => fail("Expected Int(2)")
  }
}
