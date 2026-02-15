/// Tests for proper tail calls in various special forms.
/// These tests use deep recursion to verify tail call optimization.

test "tail call: named let deep recursion" {
  let ctx = new_repl_context()
  // 100000 iterations - would stack overflow without TCO
  match repl_eval(ctx, "(let loop ((n 100000)) (if (= n 0) 'done (loop (- n 1))))") {
    Ok(Value::Symbol("done")) => ()
    Ok(v) => fail("expected done, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: if in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (count n) (if (= n 0) 0 (count (- n 1))))")
  match repl_eval(ctx, "(count 100000)") {
    Ok(Value::Number(Number::Int(0))) => ()
    Ok(v) => fail("expected 0, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: cond in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (cond-count n) (cond ((= n 0) 'done) (else (cond-count (- n 1)))))")
  match repl_eval(ctx, "(cond-count 100000)") {
    Ok(Value::Symbol("done")) => ()
    Ok(v) => fail("expected done, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: and in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (and-count n) (and (> n 0) (and-count (- n 1))))")
  match repl_eval(ctx, "(and-count 100000)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: or in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (or-count n) (or (= n 0) (or-count (- n 1))))")
  match repl_eval(ctx, "(or-count 100000)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: begin in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (begin-count n) (begin (if (= n 0) 'done (begin-count (- n 1)))))")
  match repl_eval(ctx, "(begin-count 100000)") {
    Ok(Value::Symbol("done")) => ()
    Ok(v) => fail("expected done, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: mutual recursion" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (even? n) (if (= n 0) #t (odd? (- n 1))))")
  let _ = repl_eval(ctx, "(define (odd? n) (if (= n 0) #f (even? (- n 1))))")
  match repl_eval(ctx, "(even? 100000)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "tail call: let in tail position" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define (let-count n) (if (= n 0) 'done (let ((m (- n 1))) (let-count m))))")
  match repl_eval(ctx, "(let-count 100000)") {
    Ok(Value::Symbol("done")) => ()
    Ok(v) => fail("expected done, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
