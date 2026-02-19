/// R5RS Section 6.6: Input and Output
/// Tests for port operations, read, write, display
/// NOTE: Many I/O operations may not be fully implemented

fn s6_6_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// 6.6.1 Ports

test "R5RS 6.6: port predicates" {
  let ctx = new_repl_context()
  // Test that port? works on non-port values
  s6_6_assert_false(ctx, "(input-port? 42)")
  s6_6_assert_false(ctx, "(output-port? 42)")
  s6_6_assert_false(ctx, "(input-port? \"hello\")")
  s6_6_assert_false(ctx, "(output-port? '(a b))")
}

// 6.6.3 Output

test "R5RS 6.6: display returns unspecified" {
  let ctx = new_repl_context()
  // display should return without error
  match repl_eval(ctx, "(display \"hello\")") {
    Ok(_) => ()
    Err(e) => fail("display error: " + e)
  }
}

test "R5RS 6.6: write returns unspecified" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(write 42)") {
    Ok(_) => ()
    Err(e) => fail("write error: " + e)
  }
}

test "R5RS 6.6: newline returns unspecified" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(newline)") {
    Ok(_) => ()
    Err(e) => fail("newline error: " + e)
  }
}

test "R5RS 6.6: write-char" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(write-char #\\a)") {
    Ok(_) => ()
    Err(e) => fail("write-char error: " + e)
  }
}

// 6.6.4 System interface

test "R5RS 6.6: string output via display" {
  let ctx = new_repl_context()
  // Test that display handles various value types without error
  match repl_eval(ctx, "(begin (display 42) (display #t) (display '(1 2)) (display \"abc\"))") {
    Ok(_) => ()
    Err(e) => fail("display various error: " + e)
  }
}
