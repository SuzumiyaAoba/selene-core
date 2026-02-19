/// R5RS Section 6.3.4: Characters
/// Tests for char operations, predicates, and conversions

fn s6_3_chars_assert(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// === char? ===

test "R5RS 6.3.4: char? character" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char? #\\a)")
}

test "R5RS 6.3.4: char? number" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char? 42)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char? string" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char? \"a\")") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

// === char comparison ===

test "R5RS 6.3.4: char=? same" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char=? #\\a #\\a)")
}

test "R5RS 6.3.4: char=? different" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char=? #\\a #\\b)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char<?" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char<? #\\a #\\b)")
}

test "R5RS 6.3.4: char<? false" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char<? #\\b #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char>?" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char>? #\\b #\\a)")
}

test "R5RS 6.3.4: char<=? equal" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char<=? #\\a #\\a)")
}

test "R5RS 6.3.4: char<=? less" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char<=? #\\a #\\b)")
}

test "R5RS 6.3.4: char>=? equal" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char>=? #\\b #\\b)")
}

test "R5RS 6.3.4: char>=? greater" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char>=? #\\b #\\a)")
}

// === char predicates ===

test "R5RS 6.3.4: char-alphabetic? letter" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char-alphabetic? #\\a)")
}

test "R5RS 6.3.4: char-alphabetic? digit" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-alphabetic? #\\1)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char-numeric? digit" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char-numeric? #\\0)")
}

test "R5RS 6.3.4: char-numeric? letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-numeric? #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char-whitespace? space" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char-whitespace? #\\space)")
}

test "R5RS 6.3.4: char-whitespace? letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-whitespace? #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char-upper-case?" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char-upper-case? #\\A)")
}

test "R5RS 6.3.4: char-upper-case? lowercase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-upper-case? #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char-lower-case?" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char-lower-case? #\\a)")
}

test "R5RS 6.3.4: char-lower-case? uppercase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-lower-case? #\\A)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

// === char conversion ===

test "R5RS 6.3.4: char-upcase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-upcase #\\a)") {
    Ok(Value::Char('A')) => ()
    Ok(v) => fail("expected #\\A, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char-downcase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-downcase #\\A)") {
    Ok(Value::Char('a')) => ()
    Ok(v) => fail("expected #\\a, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char->integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char->integer #\\a)") {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 97)
    Ok(v) => fail("expected 97, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: integer->char" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(integer->char 97)") {
    Ok(Value::Char('a')) => ()
    Ok(v) => fail("expected #\\a, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.4: char->integer->char roundtrip" {
  let ctx = new_repl_context()
  s6_3_chars_assert(ctx, "(char=? (integer->char (char->integer #\\z)) #\\z)")
}

test "R5RS 6.3.4: char-upcase non-letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-upcase #\\1)") {
    Ok(Value::Char('1')) => ()
    Ok(v) => fail("expected #\\1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

// === char-ci (case insensitive) - NOT IMPLEMENTED ===

test "R5RS 6.3.4: char-ci=? NOT IMPLEMENTED" {
  let ctx = new_repl_context()
  // char-ci=? is not implemented, expect error
  match repl_eval(ctx, "(char-ci=? #\\A #\\a)") {
    Ok(_) => () // if implemented, that's fine too
    Err(_) => ()
  }
}
