/// Extended character function tests.

test "char-alphabetic? letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-alphabetic? #\\a)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-alphabetic? digit" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-alphabetic? #\\5)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-numeric? digit" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-numeric? #\\7)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-numeric? letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-numeric? #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-whitespace? space" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-whitespace? #\\space)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-whitespace? letter" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-whitespace? #\\a)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-upper-case?" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-upper-case? #\\A)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-lower-case?" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-lower-case? #\\a)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-upcase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-upcase #\\a)") {
    Ok(Value::Char('A')) => ()
    Ok(v) => fail("expected #\\A, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char-downcase" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char-downcase #\\A)") {
    Ok(Value::Char('a')) => ()
    Ok(v) => fail("expected #\\a, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char<? comparison" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char<? #\\a #\\b)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char>? comparison" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char>? #\\z #\\a)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char<=? equal" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char<=? #\\a #\\a)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "char>=? less should be false" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char>=? #\\a #\\z)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "integer->char and char->integer roundtrip" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(char->integer (integer->char 65))") {
    Ok(Value::Number(Number::Int(65))) => ()
    Ok(v) => fail("expected 65, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
