/// map と for-each 関数のテスト

/// map の基本的な動作
test "map basic" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x) (* x 2)) (list 1 2 3))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 4 6)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map で組み込み関数を使用
test "map with builtin function" {
  let env = initial_env()
  // 負の数リテラルは未サポートのため、(- 0 N) を使用
  let expr = parse_one("(map abs (list (- 0 1) 2 (- 0 3) 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3 4)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    Err(e) => {
      let msg = "Expected a list, got error: " + e.to_string()
      fail(msg)
    }
  }
}

/// map で複数のリスト
test "map with multiple lists" {
  let env = initial_env()
  let expr = parse_one("(map + (list 1 2 3) (list 10 20 30))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 11 22 33)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map で3つのリスト
test "map with three lists" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x y z) (+ x (+ y z))) (list 1 2) (list 10 20) (list 100 200))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 111 222)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map で空のリスト
test "map with empty list" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x) (* x 2)) ())")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// map でラムダ式
test "map with lambda" {
  let env = initial_env()
  // 負の数リテラルは未サポートのため、(- 0 N) を使用
  let expr = parse_one("(map (lambda (x) (if (< x 0) 0 x)) (list (- 0 1) 2 (- 0 3) 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 0 2 0 4)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    Err(e) => {
      let msg = "Expected a list, got error: " + e.to_string()
      fail(msg)
    }
  }
}

/// for-each の基本的な動作（副作用はテストできないが、エラーがないことを確認）
test "for-each basic" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x) (* x 2)) (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// for-each で複数のリスト
test "for-each with multiple lists" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x y) (+ x y)) (list 1 2 3) (list 10 20 30))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// for-each で空のリスト
test "for-each with empty list" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x) (* x 2)) ())")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// map でネストされたリスト操作
test "map nested" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (lst) (car lst)) (list (list 1 2) (list 3 4) (list 5 6)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 3 5)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map と変数
test "map with variable" {
  let env = initial_env()
  let expr = parse_one("(let ((double (lambda (x) (* x 2)))) (map double (list 1 2 3)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 4 6)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map でリストの合計を計算
test "map for calculation" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x y) (* x y)) (list 1 2 3) (list 2 3 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 6 12)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// ヘルパー関数: Value を文字列に変換（map_test用）
fn map_value_to_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Rational(num, den)) => num.to_string() + "/" + den.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Number(Number::Complex(r, i)) =>
      if i >= 0.0 {
        r.to_string() + "+" + i.to_string() + "i"
      } else {
        r.to_string() + i.to_string() + "i"
      }
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + map_value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + map_value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + map_value_to_string(current) + ")"
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
    Value::Syntax(_) => "#<syntax-rules>"
  }
}
