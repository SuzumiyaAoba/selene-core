/// apply 関数のテスト

/// apply の基本的な動作（リストのみ）
test "apply basic - list only" {
  let env = initial_env()
  let expr = parse_one("(apply + (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}

/// apply で中間引数とリストを結合
test "apply with intermediate arguments" {
  let env = initial_env()
  let expr = parse_one("(apply + 1 2 (list 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    _ => fail("Expected Int(15)")
  }
}

/// apply と list 関数
test "apply with list" {
  let env = initial_env()
  let expr = parse_one("(apply list (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Pair(_, _)) => {
      // リストが作成されたことを確認
      let list_expr = parse_one("(list 1 2 3)")
      let expected = match eval(list_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      // 値を文字列化して比較（簡易的な方法）
      let result_str = value_to_string(eval(expr, env).unwrap())
      let expected_str = value_to_string(expected)
      assert_eq(result_str, expected_str)
    }
    _ => fail("Expected a list")
  }
}

/// apply と max 関数
test "apply with max" {
  let env = initial_env()
  let expr = parse_one("(apply max (list 1 5 3 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    _ => fail("Expected Int(5)")
  }
}

/// apply と cons 関数
test "apply with cons" {
  let env = initial_env()
  let expr = parse_one("(apply cons (list 1 2))")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Number(Number::Int(2)))) => ()
    _ => fail("Expected Pair(1, 2)")
  }
}

/// apply とラムダ式
test "apply with lambda" {
  let env = initial_env()
  let expr = parse_one("(apply (lambda (x y) (+ x y)) (list 3 4))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 7)
    _ => fail("Expected Int(7)")
  }
}

/// apply とラムダ式（中間引数あり）
test "apply with lambda and intermediate args" {
  let env = initial_env()
  let expr = parse_one("(apply (lambda (x y z) (* x (+ y z))) 2 (list 3 4))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 14)
    _ => fail("Expected Int(14)")
  }
}

/// apply で空のリスト
test "apply with empty list" {
  let env = initial_env()
  let expr = parse_one("(apply + ())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 0)
    _ => fail("Expected Int(0)")
  }
}

/// apply で中間引数と空のリスト
test "apply with intermediate args and empty list" {
  let env = initial_env()
  let expr = parse_one("(apply + 1 2 ())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// apply で単一の中間引数
test "apply with single intermediate arg" {
  let env = initial_env()
  let expr = parse_one("(apply + 10 (list 20 30))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 60)
    _ => fail("Expected Int(60)")
  }
}

/// apply でネストされたリスト
test "apply with nested expression" {
  let env = initial_env()
  let expr = parse_one("(apply + (cons 1 (cons 2 (cons 3 ()))))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}

/// apply と変数
test "apply with variable" {
  let env = initial_env()
  let expr = parse_one("(let ((nums (list 1 2 3 4))) (apply + nums))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    _ => fail("Expected Int(10)")
  }
}

/// REPL の value_to_string ヘルパー関数（テスト用）
fn value_to_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(_) => "#(...)"
    Value::Procedure(_) => "#<procedure>"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(_) => "#<values>"
  }
}
