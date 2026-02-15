/// Tests for error handling: type errors, arity errors, and runtime errors.

/// Helper to assert that evaluation returns an error
fn assert_eval_error(code : String) -> Unit raise Error {
  let ctx = new_repl_context()
  match repl_eval(ctx, code) {
    Ok(v) => fail("expected error but got: " + v.to_string() + " for: " + code)
    Err(_) => ()
  }
}

/// Helper to assert that evaluation succeeds
fn assert_eval_ok(code : String) -> Unit raise Error {
  let ctx = new_repl_context()
  match repl_eval(ctx, code) {
    Ok(_) => ()
    Err(e) => fail("expected ok but got error: " + e + " for: " + code)
  }
}

// ============================================================
// Type errors
// ============================================================

test "error: car on non-pair" {
  assert_eval_error("(car 1)")
}

test "error: cdr on non-pair" {
  assert_eval_error("(cdr 1)")
}

test "error: string-length on non-string" {
  assert_eval_error("(string-length 42)")
}

test "error: string-ref on non-string" {
  assert_eval_error("(string-ref 42 0)")
}

test "error: vector-ref on non-vector" {
  assert_eval_error("(vector-ref 42 0)")
}

test "error: char->integer on non-char" {
  assert_eval_error("(char->integer 42)")
}

test "error: not a procedure" {
  assert_eval_error("(1 2 3)")
}

// ============================================================
// Arity errors
// ============================================================

test "error: cons needs 2 args" {
  assert_eval_error("(cons 1)")
}

test "error: car needs 1 arg" {
  assert_eval_error("(car 1 2)")
}

test "error: cdr needs 1 arg" {
  assert_eval_error("(cdr)")
}

test "error: + with no args is zero" {
  assert_eval_ok("(+)")
}

test "error: * with no args is one" {
  assert_eval_ok("(*)")
}

test "error: - needs at least 1 arg" {
  assert_eval_error("(-)")
}

test "error: null? needs 1 arg" {
  assert_eval_error("(null?)")
}

test "error: not needs 1 arg" {
  assert_eval_error("(not)")
}

// ============================================================
// Division by zero
// ============================================================

test "error: integer division by zero" {
  assert_eval_error("(/ 1 0)")
}

test "error: quotient division by zero" {
  assert_eval_error("(quotient 10 0)")
}

test "error: remainder division by zero" {
  assert_eval_error("(remainder 10 0)")
}

test "error: modulo division by zero" {
  assert_eval_error("(modulo 10 0)")
}

// ============================================================
// Unbound variables
// ============================================================

test "error: unbound variable" {
  assert_eval_error("undefined-var")
}

test "error: unbound in expression" {
  assert_eval_error("(+ 1 undefined-var)")
}

// ============================================================
// Syntax errors (runtime)
// ============================================================

test "error: define with no value" {
  assert_eval_error("(define)")
}

test "error: if with no args" {
  assert_eval_error("(if)")
}

test "error: lambda with no body" {
  assert_eval_error("(lambda ())")
}

// ============================================================
// Parse error recovery via repl_eval
// ============================================================

test "error: empty input returns error" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "") {
    Ok(_) => fail("expected error for empty input")
    Err(_) => ()
  }
}
