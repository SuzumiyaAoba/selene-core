/// Testing string manipulation functions

/// Basic operation of string?
test "string? basic" {
  let env = initial_env()
  let expr = parse_one("(string? \"hello\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// Determine non-string with string?
test "string? with non-string" {
  let env = initial_env()
  let expr = parse_one("(string? 42)")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Basic operation of char?
test "char? basic" {
  let env = initial_env()
  let expr = parse_one("(char? #\\a)")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// Determine non-characters with char?
test "char? with non-char" {
  let env = initial_env()
  let expr = parse_one("(char? \"a\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Basic behavior of string-length
test "string-length basic" {
  let env = initial_env()
  let expr = parse_one("(string-length \"hello\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// Empty string with string-length
test "string-length empty" {
  let env = initial_env()
  let expr = parse_one("(string-length \"\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// Basic behavior of string-ref
test "string-ref basic" {
  let env = initial_env()
  let expr = parse_one("(string-ref \"hello\" 0)")
  match eval(expr, env) {
    Ok(Value::Char('h')) => ()
    _ => fail("Expected Char('h')")
  }
}

/// Intermediate index with string-ref
test "string-ref middle" {
  let env = initial_env()
  let expr = parse_one("(string-ref \"hello\" 2)")
  match eval(expr, env) {
    Ok(Value::Char('l')) => ()
    _ => fail("Expected Char('l')")
  }
}

/// Basic operation of string-append
test "string-append basic" {
  let env = initial_env()
  let expr = parse_one("(string-append \"hello\" \" \" \"world\")")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello world")
    _ => fail("Expected String(\"hello world\")")
  }
}

/// Empty string with string-append
test "string-append empty" {
  let env = initial_env()
  let expr = parse_one("(string-append \"\" \"hello\" \"\")")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// string-append without arguments
test "string-append no args" {
  let env = initial_env()
  let expr = parse_one("(string-append)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// Basic behavior of string=?
test "string=? basic true" {
  let env = initial_env()
  let expr = parse_one("(string=? \"hello\" \"hello\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// Different strings with string=?
test "string=? basic false" {
  let env = initial_env()
  let expr = parse_one("(string=? \"hello\" \"world\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Basic operation of make-string
test "make-string basic" {
  let env = initial_env()
  let expr = parse_one("(make-string 5 #\\a)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "aaaaa")
    _ => fail("Expected String(\"aaaaa\")")
  }
}

/// Default character (space) in make-string
test "make-string default char" {
  let env = initial_env()
  let expr = parse_one("(make-string 3)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "   ")
    _ => fail("Expected 3 spaces")
  }
}

/// empty string with make-string
test "make-string zero length" {
  let env = initial_env()
  let expr = parse_one("(make-string 0)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// Basic behavior of substring
test "substring basic" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello world\" 0 5)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// middle part with substring
test "substring middle" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello world\" 6 11)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "world")
    _ => fail("Expected String(\"world\")")
  }
}

/// empty string in substring
test "substring empty" {
  let env = initial_env()
  let expr = parse_one("(substring \"hello\" 2 2)")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "")
    _ => fail("Expected empty string")
  }
}

/// Basic parsing of character literals
test "char literal basic" {
  let env = initial_env()
  let expr = parse_one("#\\a")
  match eval(expr, env) {
    Ok(Value::Char('a')) => ()
    _ => fail("Expected Char('a')")
  }
}

/// Character literal - space
test "char literal space" {
  let env = initial_env()
  let expr = parse_one("#\\space")
  match eval(expr, env) {
    Ok(Value::Char(' ')) => ()
    _ => fail("Expected Char(' ')")
  }
}

/// Character literals - newline
test "char literal newline" {
  let env = initial_env()
  let expr = parse_one("#\\newline")
  match eval(expr, env) {
    Ok(Value::Char('\n')) => ()
    _ => fail("Expected Char('\\n')")
  }
}

/// Basic parsing of string literals
test "string literal basic" {
  let env = initial_env()
  let expr = parse_one("\"hello\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    _ => fail("Expected String(\"hello\")")
  }
}

/// String literals - escape sequences
test "string literal with escape" {
  let env = initial_env()
  let expr = parse_one("\"hello\\nworld\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "hello\nworld")
    _ => fail("Expected String(\"hello\\nworld\")")
  }
}

/// String literals - escaping quotes
test "string literal with escaped quote" {
  let env = initial_env()
  let expr = parse_one("\"say \\\"hello\\\"\"")
  match eval(expr, env) {
    Ok(Value::String(s)) => assert_eq(s, "say \"hello\"")
    _ => fail("Expected String with escaped quotes")
  }
}
