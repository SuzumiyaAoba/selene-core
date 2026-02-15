/// Extended arithmetic tests: edge cases, math functions, exact/inexact.

test "quotient negative dividend" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(quotient -10 3)") {
    Ok(Value::Number(Number::Int(-3))) => ()
    Ok(v) => fail("expected -3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "quotient negative divisor" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(quotient 10 -3)") {
    Ok(Value::Number(Number::Int(-3))) => ()
    Ok(v) => fail("expected -3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "remainder positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(remainder 10 3)") {
    Ok(Value::Number(Number::Int(1))) => ()
    Ok(v) => fail("expected 1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "remainder negative dividend" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(remainder -10 3)") {
    Ok(Value::Number(Number::Int(-1))) => ()
    Ok(v) => fail("expected -1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "modulo positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(modulo 10 3)") {
    Ok(Value::Number(Number::Int(1))) => ()
    Ok(v) => fail("expected 1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "modulo negative dividend" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(modulo -10 3)") {
    Ok(Value::Number(Number::Int(2))) => ()
    Ok(v) => fail("expected 2, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "abs positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(abs 5)") {
    Ok(Value::Number(Number::Int(5))) => ()
    Ok(v) => fail("expected 5, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "abs negative" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(abs -5)") {
    Ok(Value::Number(Number::Int(5))) => ()
    Ok(v) => fail("expected 5, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "max of multiple" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(max 1 5 3 2 4)") {
    Ok(Value::Number(Number::Int(5))) => ()
    Ok(v) => fail("expected 5, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "min of multiple" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(min 3 1 5 2 4)") {
    Ok(Value::Number(Number::Int(1))) => ()
    Ok(v) => fail("expected 1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "gcd basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(gcd 12 8)") {
    Ok(Value::Number(Number::Int(4))) => ()
    Ok(v) => fail("expected 4, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "lcm basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(lcm 4 6)") {
    Ok(Value::Number(Number::Int(12))) => ()
    Ok(v) => fail("expected 12, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "odd? and even?" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(odd? 3)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(even? 4)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
  match repl_eval(ctx, "(odd? 4)") {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "exact? integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(exact? 42)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "inexact? real" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(inexact? 3.14)") {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "floor positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(floor 3.7)") {
    Ok(Value::Number(Number::Int(3))) => ()
    Ok(v) => fail("expected 3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "floor negative" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(floor -3.2)") {
    Ok(Value::Number(Number::Int(-4))) => ()
    Ok(v) => fail("expected -4, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "ceiling positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(ceiling 3.2)") {
    Ok(Value::Number(Number::Int(4))) => ()
    Ok(v) => fail("expected 4, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "ceiling negative" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(ceiling -3.7)") {
    Ok(Value::Number(Number::Int(-3))) => ()
    Ok(v) => fail("expected -3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "truncate positive" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(truncate 3.7)") {
    Ok(Value::Number(Number::Int(3))) => ()
    Ok(v) => fail("expected 3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "truncate negative" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(truncate -3.7)") {
    Ok(Value::Number(Number::Int(-3))) => ()
    Ok(v) => fail("expected -3, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "round to nearest" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(round 3.5)") {
    Ok(Value::Number(Number::Int(4))) => ()
    Ok(v) => fail("expected 4, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "expt integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(expt 2 10)") {
    Ok(Value::Number(Number::Int(1024))) => ()
    Ok(v) => fail("expected 1024, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "expt zero" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(expt 5 0)") {
    Ok(Value::Number(Number::Int(1))) => ()
    Ok(v) => fail("expected 1, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "sqrt of 4" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(sqrt 4)") {
    Ok(Value::Number(Number::Real(r))) => assert_eq(r, 2.0)
    Ok(v) => fail("expected 2.0, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "floor of integer stays integer" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(floor 5)") {
    Ok(Value::Number(Number::Int(5))) => ()
    Ok(v) => fail("expected 5, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}
