/// Extended string function tests.

test "string-ci=? case insensitive equal" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string-ci=? \"Hello\" \"hello\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string-ci=? case insensitive not equal" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string-ci=? \"Hello\" \"world\")") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string-ci<? case insensitive less" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string-ci<? \"ABC\" \"def\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string-ci>? case insensitive greater" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string-ci>? \"xyz\" \"ABC\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string->list basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(equal? (string->list \"abc\") '(#\\a #\\b #\\c))") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string->list empty" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string->list \"\")") {
    Ok(Value::Nil) => ()
    Ok(v) => fail("expected (), got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "list->string basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(list->string '(#\\a #\\b #\\c))") {
    Ok(Value::String(s)) => assert_eq(s, "abc")
    Ok(v) => fail("expected \"abc\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string->list->string roundtrip" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(list->string (string->list \"hello\"))") {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    Ok(v) => fail("expected \"hello\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "number->string integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(number->string 42)") {
    Ok(Value::String(s)) => assert_eq(s, "42")
    Ok(v) => fail("expected \"42\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "number->string negative" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(number->string -7)") {
    Ok(Value::String(s)) => assert_eq(s, "-7")
    Ok(v) => fail("expected \"-7\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string->number valid integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string->number \"42\")") {
    Ok(Value::Number(Number::Int(42))) => ()
    Ok(v) => fail("expected 42, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string->number invalid returns false" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string->number \"abc\")") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string<? comparison" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string<? \"abc\" \"abd\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string>? comparison" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string>? \"xyz\" \"abc\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string<=? equal strings" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string<=? \"abc\" \"abc\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "string>=? greater or equal" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string>=? \"abd\" \"abc\")") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "substring full" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(substring \"hello\" 0 5)") {
    Ok(Value::String(s)) => assert_eq(s, "hello")
    Ok(v) => fail("expected \"hello\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "substring empty range" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(substring \"hello\" 2 2)") {
    Ok(Value::String(s)) => assert_eq(s, "")
    Ok(v) => fail("expected \"\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
