/// R5RS Section 6.3.3: Symbols
/// Tests for symbol?, symbol->string, string->symbol

test "R5RS 6.3.3: symbol? foo" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? 'foo)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol? string" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? \"bar\")") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol? number" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? 42)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol? pair" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? '(a b))") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol? boolean" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? #t)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol->string" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol->string 'flying-fish)") {
    Ok(Value::String(s)) => assert_eq(s, "flying-fish")
    Ok(v) => fail("expected \"flying-fish\", got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: string->symbol" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(string->symbol \"hello\")") {
    Ok(Value::Symbol(s)) => assert_eq(s, "hello")
    Ok(v) => fail("expected symbol hello, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol->string->symbol roundtrip" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(eq? 'hello (string->symbol (symbol->string 'hello)))") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.3: symbol? nil" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(symbol? '())") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
