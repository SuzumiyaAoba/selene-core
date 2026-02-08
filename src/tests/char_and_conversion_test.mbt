/// Testing of character and conversion functions.

// = = = character comparison function = = =

/// char =? returns # t for the same character.
test "char=? same" {
  let env = initial_env()
  let expr = parse_one("(char=? #\\a #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char =? returns # f for different characters.
test "char=? different" {
  let env = initial_env()
  let expr = parse_one("(char=? #\\a #\\b)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char <? is compared by character code.
test "char<?" {
  let env = initial_env()
  let expr = parse_one("(char<? #\\a #\\b)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char >? is compared with the character code.
test "char>?" {
  let env = initial_env()
  let expr = parse_one("(char>? #\\b #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char < =? is compared by character code.
test "char<=?" {
  let env = initial_env()
  let expr = parse_one("(char<=? #\\a #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char > =? compares by character code.
test "char>=?" {
  let env = initial_env()
  let expr = parse_one("(char>=? #\\b #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

// = = = Character classification function = = =

/// char-alphabetic? returns # t for the alphabet.
test "char-alphabetic? true" {
  let env = initial_env()
  let expr = parse_one("(char-alphabetic? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-alphabetic? returns # f for a number.
test "char-alphabetic? false" {
  let env = initial_env()
  let expr = parse_one("(char-alphabetic? #\\5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-numeric? returns # t for a number.
test "char-numeric? true" {
  let env = initial_env()
  let expr = parse_one("(char-numeric? #\\5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-numeric? returns # f for the alphabet.
test "char-numeric? false" {
  let env = initial_env()
  let expr = parse_one("(char-numeric? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-whitespace? returns # t for whitespace characters.
test "char-whitespace? true" {
  let env = initial_env()
  let expr = parse_one("(char-whitespace? #\\space)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-whitespace? returns # f for normal characters.
test "char-whitespace? false" {
  let env = initial_env()
  let expr = parse_one("(char-whitespace? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-upper-case? returns # t for a capital letter.
test "char-upper-case? true" {
  let env = initial_env()
  let expr = parse_one("(char-upper-case? #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-upper-case? returns # f for lowercase.
test "char-upper-case? false" {
  let env = initial_env()
  let expr = parse_one("(char-upper-case? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// char-lower-case? returns # t for lowercase.
test "char-lower-case? true" {
  let env = initial_env()
  let expr = parse_one("(char-lower-case? #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// char-lower-case? returns # f for a capital letter.
test "char-lower-case? false" {
  let env = initial_env()
  let expr = parse_one("(char-lower-case? #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// = = = Transcription function = = =

/// char-upcase converts lowercase to uppercase.
test "char-upcase" {
  let env = initial_env()
  let expr = parse_one("(char-upcase #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('A')) => ()
    _ => fail("expected #\\A")
  }
}

/// char-upcase returns the capital letter as it is.
test "char-upcase already upper" {
  let env = initial_env()
  let expr = parse_one("(char-upcase #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('A')) => ()
    _ => fail("expected #\\A")
  }
}

/// char-downcase converts uppercase to lowercase.
test "char-downcase" {
  let env = initial_env()
  let expr = parse_one("(char-downcase #\\A)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// char-downcase returns the lowercase letter exactly as it is.
test "char-downcase already lower" {
  let env = initial_env()
  let expr = parse_one("(char-downcase #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// char- > integer converts a character into a character encoding.
test "char->integer" {
  let env = initial_env()
  let expr = parse_one("(char->integer #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(97))) => ()
    _ => fail("expected 97")
  }
}

/// integer- > char converts a character code into a character.
test "integer->char" {
  let env = initial_env()
  let expr = parse_one("(integer->char 97)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('a')) => ()
    _ => fail("expected #\\a")
  }
}

/// Round Trip Conversion
test "char integer round trip" {
  let env = initial_env()
  let expr = parse_one("(integer->char (char->integer #\\z))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Char('z')) => ()
    _ => fail("expected #\\z")
  }
}

// = = = String/list conversion function = = =

/// string - > list converts a string into a list of characters.
test "string->list" {
  let env = initial_env()
  let expr = parse_one("(string->list \"abc\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Char('a'), Value::Pair(Value::Char('b'), Value::Pair(Value::Char('c'), Value::Nil, _), _), _)) => ()
    _ => fail("expected (#\\a #\\b #\\c)")
  }
}

/// string - > list returns an empty list for an empty string.
test "string->list empty" {
  let env = initial_env()
  let expr = parse_one("(string->list \"\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
}

/// list- > string converts a list of characters into a string.
test "list->string" {
  let env = initial_env()
  let expr = parse_one("(list->string (list #\\a #\\b #\\c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("abc")) => ()
    _ => fail("expected \"abc\"")
  }
}

/// list- > string returns an empty string for an empty list.
test "list->string empty" {
  let env = initial_env()
  let expr = parse_one("(list->string (list))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("")) => ()
    _ => fail("expected \"\"")
  }
}

/// Round Trip Conversion
test "string list round trip" {
  let env = initial_env()
  let expr = parse_one("(list->string (string->list \"hello\"))")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("hello")) => ()
    _ => fail("expected \"hello\"")
  }
}

// Numeric Functions

/// gcd returns the greatest common divisor.
test "gcd two numbers" {
  let env = initial_env()
  let expr = parse_one("(gcd 12 8)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("expected 4")
  }
}

/// gcd can receive multiple arguments.
test "gcd multiple numbers" {
  let env = initial_env()
  let expr = parse_one("(gcd 12 18 24)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(6))) => ()
    _ => fail("expected 6")
  }
}

/// gcd returns 0 without arguments.
test "gcd no args" {
  let env = initial_env()
  let expr = parse_one("(gcd)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
}

/// gcd can also handle negative numbers.
test "gcd negative" {
  let env = initial_env()
  let expr = parse_one("(gcd (- 0 12) 8)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(4))) => ()
    _ => fail("expected 4")
  }
}

/// lcm returns the least common multiple.
test "lcm two numbers" {
  let env = initial_env()
  let expr = parse_one("(lcm 4 6)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(12))) => ()
    _ => fail("expected 12")
  }
}

/// lcm accepts multiple arguments.
test "lcm multiple numbers" {
  let env = initial_env()
  let expr = parse_one("(lcm 2 3 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(12))) => ()
    _ => fail("expected 12")
  }
}

/// lcm returns 1 with no arguments.
test "lcm no args" {
  let env = initial_env()
  let expr = parse_one("(lcm)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// lcm returns 0 if it contains 0.
test "lcm with zero" {
  let env = initial_env()
  let expr = parse_one("(lcm 5 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
}
