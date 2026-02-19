/// R5RS Section 6.3.1: Booleans
/// Tests for not and boolean?

test "R5RS 6.3.1: not #t" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(not #t)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: not 3" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(not 3)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: not list" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(not (list 3))") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: not #f" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(not #f)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: not nil" {
  let ctx = new_repl_context()
  // R5RS: only #f is false, () is truthy
  match repl_eval(ctx, "(not '())") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: not symbol" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(not 'nil)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: boolean? #f" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(boolean? #f)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: boolean? #t" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(boolean? #t)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: boolean? 0" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(boolean? 0)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.3.1: boolean? nil" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(boolean? '())") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
