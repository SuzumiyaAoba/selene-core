/// R5RS Section 6.5: Eval
/// Tests for eval

fn s6_5_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_5_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "R5RS 6.5: eval basic arithmetic" {
  let ctx = new_repl_context()
  s6_5_assert_int(ctx, "(eval '(+ 1 2))", 3)
}

test "R5RS 6.5: eval list expression" {
  let ctx = new_repl_context()
  s6_5_assert_true(ctx, "(equal? (eval '(list 1 2 3)) '(1 2 3))")
}

test "R5RS 6.5: eval lambda" {
  let ctx = new_repl_context()
  s6_5_assert_int(ctx, "(eval '((lambda (x) (* x x)) 5))", 25)
}

test "R5RS 6.5: eval nested" {
  let ctx = new_repl_context()
  s6_5_assert_int(ctx, "(eval '(+ (eval '(* 2 3)) 4))", 10)
}

test "R5RS 6.5: eval with quote" {
  let ctx = new_repl_context()
  s6_5_assert_true(ctx, "(equal? (eval '(quote a)) 'a)")
}

test "R5RS 6.5: eval returns quoted list" {
  let ctx = new_repl_context()
  s6_5_assert_true(ctx, "(pair? (eval '(list 1 2)))")
}

test "R5RS 6.5: eval if" {
  let ctx = new_repl_context()
  s6_5_assert_int(ctx, "(eval '(if #t 1 2))", 1)
  s6_5_assert_int(ctx, "(eval '(if #f 1 2))", 2)
}

test "R5RS 6.5: eval with let" {
  let ctx = new_repl_context()
  s6_5_assert_int(ctx, "(eval '(let ((x 10) (y 20)) (+ x y)))", 30)
}
