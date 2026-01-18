/// ベクトル操作関数のテスト

/// vector? の基本的な動作
test "vector? basic" {
  let env = initial_env()
  let expr = parse_one("(vector? (vector 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// vector? で非ベクトルを判定
test "vector? with non-vector" {
  let env = initial_env()
  let expr = parse_one("(vector? (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// make-vector の基本的な動作
test "make-vector basic" {
  let env = initial_env()
  let expr = parse_one("(make-vector 5 0)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 5)
      for item in items {
        match item {
          Value::Number(Number::Int(0)) => ()
          _ => fail("Expected Int(0)")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// make-vector でデフォルト値（Nil）
test "make-vector default value" {
  let env = initial_env()
  let expr = parse_one("(make-vector 3)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      for item in items {
        match item {
          Value::Nil => ()
          _ => fail("Expected Nil")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// make-vector で空ベクトル
test "make-vector zero length" {
  let env = initial_env()
  let expr = parse_one("(make-vector 0)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// vector の基本的な動作
test "vector basic" {
  let env = initial_env()
  let expr = parse_one("(vector 1 2 3)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1) at index 0")
      }
      match items[1] {
        Value::Number(Number::Int(2)) => ()
        _ => fail("Expected Int(2) at index 1")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3) at index 2")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// vector で引数なし（空ベクトル）
test "vector empty" {
  let env = initial_env()
  let expr = parse_one("(vector)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// vector-length の基本的な動作
test "vector-length basic" {
  let env = initial_env()
  let expr = parse_one("(vector-length (vector 1 2 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// vector-length で空ベクトル
test "vector-length empty" {
  let env = initial_env()
  let expr = parse_one("(vector-length (vector))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// vector-ref の基本的な動作
test "vector-ref basic" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail("Expected Int(10)")
  }
}

/// vector-ref で中間インデックス
test "vector-ref middle" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(20))) => ()
    _ => fail("Expected Int(20)")
  }
}

/// vector-ref で最後のインデックス
test "vector-ref last" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 2)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(30))) => ()
    _ => fail("Expected Int(30)")
  }
}

/// vector-set! の基本的な動作
test "vector-set! basic" {
  let env = initial_env()
  let expr = parse_one("(vector-set! (vector 1 2 3) 1 99)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1) at index 0")
      }
      match items[1] {
        Value::Number(Number::Int(99)) => ()
        _ => fail("Expected Int(99) at index 1")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3) at index 2")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// vector->list の基本的な動作
test "vector->list basic" {
  let env = initial_env()
  let expr = parse_one("(vector->list (vector 1 2 3))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(vector_test_value_to_string(result), vector_test_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// vector->list で空ベクトル
test "vector->list empty" {
  let env = initial_env()
  let expr = parse_one("(vector->list (vector))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// list->vector の基本的な動作
test "list->vector basic" {
  let env = initial_env()
  let expr = parse_one("(list->vector (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1)")
      }
      match items[1] {
        Value::Number(Number::Int(2)) => ()
        _ => fail("Expected Int(2)")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3)")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// list->vector で空リスト
test "list->vector empty" {
  let env = initial_env()
  let expr = parse_one("(list->vector ())")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// ベクトルとリストの相互変換
test "vector list round-trip" {
  let env = initial_env()
  let expr = parse_one("(vector->list (list->vector (list 1 2 3)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(vector_test_value_to_string(result), vector_test_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// リストとベクトルの相互変換
test "list vector round-trip" {
  let env = initial_env()
  let expr = parse_one("(list->vector (vector->list (vector 1 2 3)))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1)")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// 複雑なベクトル要素
test "vector with complex elements" {
  let env = initial_env()
  let expr = parse_one("(vector (list 1 2) (list 3 4) (list 5 6))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      for item in items {
        match item {
          Value::Pair(_, _) => ()
          _ => fail("Expected Pair")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// make-vector と vector-set! の組み合わせ
test "make-vector with vector-set!" {
  let env = initial_env()
  // (vector-set! (make-vector 3 0) 1 99) で中間の要素を変更
  let expr = parse_one("(vector-set! (make-vector 3 0) 1 99)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[1] {
        Value::Number(Number::Int(99)) => ()
        _ => fail("Expected Int(99) at index 1")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// ヘルパー関数: Value を文字列に変換（vector_test用）
fn vector_test_value_to_string(value : Value) -> String {
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
      result = result + vector_test_value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + vector_test_value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + vector_test_value_to_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(items) => {
      let mut result = "#("
      let len = items.length()
      let mut i = 0
      let _ = while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + vector_test_value_to_string(items[i])
        i = i + 1
      } else { () }
      result + ")"
    }
    Value::Procedure(_) => "#<procedure>"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(_) => "#<values>"
  }
}
