/// 文字関数と変換関数のテスト。

// === 文字比較関数 ===

/// char=? は同じ文字に対して #t を返す。
test "char=? same" {
  let env = initial_env()
  let expr = parse_one("(char=? #\\a #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char=? は異なる文字に対して #f を返す。
test "char=? different" {
  let env = initial_env()
  let expr = parse_one("(char=? #\\a #\\b)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char<? は文字コードで比較する。
test "char<?" {
  let env = initial_env()
  let expr = parse_one("(char<? #\\a #\\b)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char>? は文字コードで比較する。
test "char>?" {
  let env = initial_env()
  let expr = parse_one("(char>? #\\b #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char<=? は文字コードで比較する。
test "char<=?" {
  let env = initial_env()
  let expr = parse_one("(char<=? #\\a #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char>=? は文字コードで比較する。
test "char>=?" {
  let env = initial_env()
  let expr = parse_one("(char>=? #\\b #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

// === 文字分類関数 ===

/// char-alphabetic? はアルファベットに対して #t を返す。
test "char-alphabetic? true" {
  let env = initial_env()
  let expr = parse_one("(char-alphabetic? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-alphabetic? は数字に対して #f を返す。
test "char-alphabetic? false" {
  let env = initial_env()
  let expr = parse_one("(char-alphabetic? #\\5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-numeric? は数字に対して #t を返す。
test "char-numeric? true" {
  let env = initial_env()
  let expr = parse_one("(char-numeric? #\\5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-numeric? はアルファベットに対して #f を返す。
test "char-numeric? false" {
  let env = initial_env()
  let expr = parse_one("(char-numeric? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-whitespace? は空白文字に対して #t を返す。
test "char-whitespace? true" {
  let env = initial_env()
  let expr = parse_one("(char-whitespace? #\\space)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-whitespace? は通常の文字に対して #f を返す。
test "char-whitespace? false" {
  let env = initial_env()
  let expr = parse_one("(char-whitespace? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-upper-case? は大文字に対して #t を返す。
test "char-upper-case? true" {
  let env = initial_env()
  let expr = parse_one("(char-upper-case? #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-upper-case? は小文字に対して #f を返す。
test "char-upper-case? false" {
  let env = initial_env()
  let expr = parse_one("(char-upper-case? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-lower-case? は小文字に対して #t を返す。
test "char-lower-case? true" {
  let env = initial_env()
  let expr = parse_one("(char-lower-case? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-lower-case? は大文字に対して #f を返す。
test "char-lower-case? false" {
  let env = initial_env()
  let expr = parse_one("(char-lower-case? #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// === 文字変換関数 ===

/// char-upcase は小文字を大文字に変換する。
test "char-upcase" {
  let env = initial_env()
  let expr = parse_one("(char-upcase #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('A')) => ()
    _ => fail("expected #\\A")
  }
}

/// char-upcase は大文字をそのまま返す。
test "char-upcase already upper" {
  let env = initial_env()
  let expr = parse_one("(char-upcase #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('A')) => ()
    _ => fail("expected #\\A")
  }
}

/// char-downcase は大文字を小文字に変換する。
test "char-downcase" {
  let env = initial_env()
  let expr = parse_one("(char-downcase #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// char-downcase は小文字をそのまま返す。
test "char-downcase already lower" {
  let env = initial_env()
  let expr = parse_one("(char-downcase #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// char->integer は文字を文字コードに変換する。
test "char->integer" {
  let env = initial_env()
  let expr = parse_one("(char->integer #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(97))) => ()
    _ => fail("expected 97")
  }
}

/// integer->char は文字コードを文字に変換する。
test "integer->char" {
  let env = initial_env()
  let expr = parse_one("(integer->char 97)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// 往復変換
test "char integer round trip" {
  let env = initial_env()
  let expr = parse_one("(integer->char (char->integer #\\z))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('z')) => ()
    _ => fail("expected #\\z")
  }
}

// === 文字列/リスト変換関数 ===

/// string->list は文字列を文字のリストに変換する。
test "string->list" {
  let env = initial_env()
  let expr = parse_one("(string->list \"abc\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Char('a'), Value::Pair(Value::Char('b'), Value::Pair(Value::Char('c'), Value::Nil)))) => ()
    _ => fail("expected (#\\a #\\b #\\c)")
  }
}

/// string->list は空文字列に対して空リストを返す。
test "string->list empty" {
  let env = initial_env()
  let expr = parse_one("(string->list \"\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
}

/// list->string は文字のリストを文字列に変換する。
test "list->string" {
  let env = initial_env()
  let expr = parse_one("(list->string (list #\\a #\\b #\\c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("abc")) => ()
    _ => fail("expected \"abc\"")
  }
}

/// list->string は空リストに対して空文字列を返す。
test "list->string empty" {
  let env = initial_env()
  let expr = parse_one("(list->string (list))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("")) => ()
    _ => fail("expected \"\"")
  }
}

/// 往復変換
test "string list round trip" {
  let env = initial_env()
  let expr = parse_one("(list->string (string->list \"hello\"))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("hello")) => ()
    _ => fail("expected \"hello\"")
  }
}

// === 数値関数 ===

/// gcd は最大公約数を返す。
test "gcd two numbers" {
  let env = initial_env()
  let expr = parse_one("(gcd 12 8)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("expected 4")
  }
}

/// gcd は複数の引数を受け取れる。
test "gcd multiple numbers" {
  let env = initial_env()
  let expr = parse_one("(gcd 12 18 24)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => ()
    _ => fail("expected 6")
  }
}

/// gcd は引数なしで 0 を返す。
test "gcd no args" {
  let env = initial_env()
  let expr = parse_one("(gcd)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
}

/// gcd は負の数も扱える。
test "gcd negative" {
  let env = initial_env()
  let expr = parse_one("(gcd (- 0 12) 8)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("expected 4")
  }
}

/// lcm は最小公倍数を返す。
test "lcm two numbers" {
  let env = initial_env()
  let expr = parse_one("(lcm 4 6)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(12))) => ()
    _ => fail("expected 12")
  }
}

/// lcm は複数の引数を受け取れる。
test "lcm multiple numbers" {
  let env = initial_env()
  let expr = parse_one("(lcm 2 3 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(12))) => ()
    _ => fail("expected 12")
  }
}

/// lcm は引数なしで 1 を返す。
test "lcm no args" {
  let env = initial_env()
  let expr = parse_one("(lcm)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// lcm は0を含む場合0を返す。
test "lcm with zero" {
  let env = initial_env()
  let expr = parse_one("(lcm 5 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
}
