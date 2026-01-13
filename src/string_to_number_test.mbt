/// string->number 関数のテスト

/// 整数の文字列をパース
test "string->number with integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"42\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}

/// 負の整数の文字列をパース
test "string->number with negative integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-123\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(-123))) => ()
    _ => fail("Expected Int(-123)")
  }
}

/// ゼロの文字列をパース
test "string->number with zero" {
  let env = initial_env()
  let expr = parse_one("(string->number \"0\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// 実数の文字列をパース
test "string->number with double" {
  let env = initial_env()
  let expr = parse_one("(string->number \"3.14\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 3.14に近い値であることを確認
      let diff = if r > 3.14 { r - 3.14 } else { 3.14 - r }
      if diff > 0.0001 {
        fail("Expected approximately 3.14")
      }
    }
    _ => fail("Expected Real")
  }
}

/// 負の実数の文字列をパース
test "string->number with negative double" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-2.5\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      let diff = if r > -2.5 { r - (-2.5) } else { (-2.5) - r }
      if diff > 0.0001 {
        fail("Expected approximately -2.5")
      }
    }
    _ => fail("Expected Real")
  }
}

/// 指数表記の文字列をパース
test "string->number with exponential notation" {
  let env = initial_env()
  let expr = parse_one("(string->number \"1.5e2\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 1.5e2 = 150.0
      let diff = if r > 150.0 { r - 150.0 } else { 150.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 150.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// 不正な文字列（数値でない）
test "string->number with invalid string" {
  let env = initial_env()
  let expr = parse_one("(string->number \"not a number\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// 空文字列
test "string->number with empty string" {
  let env = initial_env()
  let expr = parse_one("(string->number \"\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// 空白を含む文字列
test "string->number with whitespace" {
  let env = initial_env()
  let expr = parse_one("(string->number \" 42 \")")
  match eval(expr, env) {
    // 空白がトリムされるかどうかは実装依存
    // 成功するか#fになるか
    Ok(_) => ()
    _ => fail("Expected some value")
  }
}

/// 大きな整数
test "string->number with large integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"999999\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(999999))) => ()
    _ => fail("Expected Int(999999)")
  }
}

/// 小数点だけの文字列
test "string->number with just decimal point" {
  let env = initial_env()
  let expr = parse_one("(string->number \".\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// 符号だけの文字列
test "string->number with just sign" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// string->numberの結果を計算で使用
test "string->number in calculation" {
  let env = initial_env()
  let expr = parse_one("(+ (string->number \"10\") (string->number \"32\"))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}

/// string->numberとnumber->stringの往復変換
test "string->number and number->string round trip" {
  let env = initial_env()
  let expr = parse_one("(string->number (number->string 42))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}
