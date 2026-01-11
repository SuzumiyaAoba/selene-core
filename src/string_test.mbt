/// 文字列操作関数のテスト

/// string? の基本的な動作
test "string? basic" {
  let env = initial_env()
  let expr = parse_one("(string? \"hello\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// string? で非文字列を判定
test "string? with non-string" {
  let env = initial_env()
  let expr = parse_one("(string? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// char? の基本的な動作
test "char? basic" {
  let env = initial_env()
  let expr = parse_one("(char? #\\a)")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// char? で非文字を判定
test "char? with non-char" {
  let env = initial_env()
  let expr = parse_one("(char? \"a\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// string-length の基本的な動作
test "string-length basic" {
  let env = initial_env()
  let expr = parse_one("(string-length \"hello\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// string-length で空文字列
test "string-length empty" {
  let env = initial_env()
  let expr = parse_one("(string-length \"\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// string-ref の基本的な動作
test "string-ref basic" {
  let env = initial_env()
  let expr = parse_one("(string-ref \"hello\" 0)")
  match eval(expr, env) {
    Ok(Value::Char('h')) => ()
    _ => fail("Expected Char('h')")
  }
}

/// string-ref で中間インデックス
test "string-ref middle" {
  let env = initial_env()
  let expr = parse_one("(string-ref \"hello\" 2)")
  match eval(expr, env) {
    Ok(Value::Char('l')) => ()
    _ => fail("Expected Char('l')")
  }
}

/// string-append の基本的な動作
test "string-append basic" {
  let env = initial_env()
  let expr = parse_one("(string-append \"hello\" \" \" \"world\")")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello world")
    _ => fail("Expected String(\"hello world\")")
  }
}

/// string-append で空文字列
test "string-append empty" {
  let env = initial_env()
  let expr = parse_one("(string-append \"\" \"hello\" \"\")")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// string-append で引数なし
test "string-append no args" {
  let env = initial_env()
  let expr = parse_one("(string-append)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// string=? の基本的な動作
test "string=? basic true" {
  let env = initial_env()
  let expr = parse_one("(string=? \"hello\" \"hello\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// string=? で異なる文字列
test "string=? basic false" {
  let env = initial_env()
  let expr = parse_one("(string=? \"hello\" \"world\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// make-string の基本的な動作
test "make-string basic" {
  let env = initial_env()
  let expr = parse_one("(make-string 5 #\\a)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "aaaaa")
    _ => fail("Expected String(\"aaaaa\")")
  }
}

/// make-string でデフォルト文字（スペース）
test "make-string default char" {
  let env = initial_env()
  let expr = parse_one("(make-string 3)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "   ")
    _ => fail("Expected 3 spaces")
  }
}

/// make-string で空文字列
test "make-string zero length" {
  let env = initial_env()
  let expr = parse_one("(make-string 0)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// substring の基本的な動作
test "substring basic" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello world\" 0 5)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// substring で中間部分
test "substring middle" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello world\" 6 11)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "world")
    _ => fail("Expected String(\"world\")")
  }
}

/// substring で空文字列
test "substring empty" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello\" 2 2)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// 文字リテラルの基本的なパース
test "char literal basic" {
  let env = initial_env()
  let expr = parse_one("#\\a")
  match eval(expr, env) {
    Ok(Value::Char('a')) => ()
    _ => fail("Expected Char('a')")
  }
}

/// 文字リテラル - space
test "char literal space" {
  let env = initial_env()
  let expr = parse_one("#\\space")
  match eval(expr, env) {
    Ok(Value::Char(' ')) => ()
    _ => fail("Expected Char(' ')")
  }
}

/// 文字リテラル - newline
test "char literal newline" {
  let env = initial_env()
  let expr = parse_one("#\\newline")
  match eval(expr, env) {
    Ok(Value::Char('\n')) => ()
    _ => fail("Expected Char('\\n')")
  }
}

/// 文字列リテラルの基本的なパース
test "string literal basic" {
  let env = initial_env()
  let expr = parse_one("\"hello\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// 文字列リテラル - エスケープシーケンス
test "string literal with escape" {
  let env = initial_env()
  let expr = parse_one("\"hello\\nworld\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello\nworld")
    _ => fail("Expected String(\"hello\\nworld\")")
  }
}

/// 文字列リテラル - クォートのエスケープ
test "string literal with escaped quote" {
  let env = initial_env()
  let expr = parse_one("\"say \\\"hello\\\"\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "say \"hello\"")
    _ => fail("Expected String with escaped quotes")
  }
}
