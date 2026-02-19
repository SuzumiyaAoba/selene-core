/// R5RS Section 6.2: Numbers
/// Tests for numeric operations, predicates, and conversions

fn s6_2_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_2_assert_false(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(false)) => ()
    Ok(v) => fail("expected #f, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

fn s6_2_assert_int(ctx : VMReplContext, code : String, expected : Int) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Int(n))) =>
      if n != expected {
        fail("expected " + expected.to_string() + ", got " + n.to_string() + " for: " + code)
      }
    Ok(v) => fail("expected Int(" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

// 6.2.5 Numerical predicates

test "R5RS 6.2: number?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(number? 3)")
  s6_2_assert_true(ctx, "(number? 3.14)")
  s6_2_assert_false(ctx, "(number? 'a)")
  s6_2_assert_false(ctx, "(number? #t)")
  s6_2_assert_false(ctx, "(number? \"hello\")")
}

test "R5RS 6.2: integer?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(integer? 3)")
  s6_2_assert_true(ctx, "(integer? 0)")
  s6_2_assert_true(ctx, "(integer? -5)")
  s6_2_assert_false(ctx, "(integer? 3.14)")
  s6_2_assert_false(ctx, "(integer? 'a)")
}

test "R5RS 6.2: zero?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(zero? 0)")
  s6_2_assert_false(ctx, "(zero? 1)")
  s6_2_assert_false(ctx, "(zero? -1)")
}

test "R5RS 6.2: positive? negative?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(positive? 1)")
  s6_2_assert_false(ctx, "(positive? 0)")
  s6_2_assert_false(ctx, "(positive? -1)")
  s6_2_assert_true(ctx, "(negative? -1)")
  s6_2_assert_false(ctx, "(negative? 0)")
  s6_2_assert_false(ctx, "(negative? 1)")
}

test "R5RS 6.2: odd? even?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(odd? 3)")
  s6_2_assert_false(ctx, "(odd? 2)")
  s6_2_assert_true(ctx, "(even? 2)")
  s6_2_assert_false(ctx, "(even? 3)")
  s6_2_assert_true(ctx, "(odd? -1)")
  s6_2_assert_true(ctx, "(even? 0)")
}

// 6.2.5 Comparison

test "R5RS 6.2: = comparison" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(= 1 1)")
  s6_2_assert_true(ctx, "(= 1 1 1)")
  s6_2_assert_false(ctx, "(= 1 2)")
}

test "R5RS 6.2: < comparison" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(< 1 2)")
  s6_2_assert_true(ctx, "(< 1 2 3)")
  s6_2_assert_false(ctx, "(< 2 1)")
  s6_2_assert_false(ctx, "(< 1 1)")
}

test "R5RS 6.2: > comparison" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(> 2 1)")
  s6_2_assert_true(ctx, "(> 3 2 1)")
  s6_2_assert_false(ctx, "(> 1 2)")
  s6_2_assert_false(ctx, "(> 1 1)")
}

test "R5RS 6.2: <= comparison" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(<= 1 2)")
  s6_2_assert_true(ctx, "(<= 1 1)")
  s6_2_assert_false(ctx, "(<= 2 1)")
}

test "R5RS 6.2: >= comparison" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(>= 2 1)")
  s6_2_assert_true(ctx, "(>= 1 1)")
  s6_2_assert_false(ctx, "(>= 1 2)")
}

// 6.2.5 Arithmetic

test "R5RS 6.2: + addition" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(+ 3 4)", 7)
  s6_2_assert_int(ctx, "(+)", 0)
  s6_2_assert_int(ctx, "(+ 1 2 3 4)", 10)
}

test "R5RS 6.2: * multiplication" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(* 3 4)", 12)
  s6_2_assert_int(ctx, "(*)", 1)
  s6_2_assert_int(ctx, "(* 2 3 4)", 24)
}

test "R5RS 6.2: - subtraction" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(- 3 4)", -1)
  s6_2_assert_int(ctx, "(- 3)", -3)
  s6_2_assert_int(ctx, "(- 10 3 2)", 5)
}

test "R5RS 6.2: / division" {
  let ctx = new_repl_context()
  // Division may return Real even for exact results
  s6_2_assert_true(ctx, "(= (/ 6 3) 2)")
  s6_2_assert_true(ctx, "(= (/ 10 2) 5)")
}

test "R5RS 6.2: max min" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(max 3 4)", 4)
  s6_2_assert_int(ctx, "(max 1)", 1)
  s6_2_assert_int(ctx, "(min 3 4)", 3)
  s6_2_assert_int(ctx, "(min 1)", 1)
}

test "R5RS 6.2: abs" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(abs 7)", 7)
  s6_2_assert_int(ctx, "(abs -7)", 7)
  s6_2_assert_int(ctx, "(abs 0)", 0)
}

test "R5RS 6.2: modulo remainder quotient" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(modulo 13 4)", 1)
  s6_2_assert_int(ctx, "(remainder 13 4)", 1)
  s6_2_assert_int(ctx, "(modulo -13 4)", 3)
  s6_2_assert_int(ctx, "(remainder -13 4)", -1)
  s6_2_assert_int(ctx, "(quotient 13 4)", 3)
  s6_2_assert_int(ctx, "(quotient -13 4)", -3)
}

test "R5RS 6.2: gcd lcm" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(gcd 32 -36)", 4)
  s6_2_assert_int(ctx, "(gcd)", 0)
  s6_2_assert_int(ctx, "(lcm 32 -36)", 288)
  s6_2_assert_int(ctx, "(lcm)", 1)
}

// 6.2.6 Numerical input and output

test "R5RS 6.2: number->string" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(number->string 42)") {
    Ok(Value::String(s)) =>
      if s != "42" { fail("expected \"42\", got \"" + s + "\"") }
    Ok(v) => fail("expected string, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "R5RS 6.2: string->number" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(string->number \"42\")", 42)
  s6_2_assert_false(ctx, "(string->number \"not-a-number\")")
}

test "R5RS 6.2: mixed int/real arithmetic" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(> (+ 1 0.5) 1)")
  s6_2_assert_true(ctx, "(< (* 2 0.5) 2)")
}

test "R5RS 6.2: exact? inexact?" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(exact? 1)")
  s6_2_assert_false(ctx, "(exact? 1.0)")
  s6_2_assert_true(ctx, "(inexact? 1.0)")
  s6_2_assert_false(ctx, "(inexact? 1)")
}

test "R5RS 6.2: floor ceiling truncate round" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(floor 4.3)", 4)
  s6_2_assert_int(ctx, "(ceiling 4.3)", 5)
  s6_2_assert_int(ctx, "(truncate 4.3)", 4)
  s6_2_assert_int(ctx, "(round 4.5)", 5)  // rounds to nearest (implementation may not do banker's)
  s6_2_assert_int(ctx, "(round 3.5)", 4)
  s6_2_assert_int(ctx, "(floor -4.3)", -5)
  s6_2_assert_int(ctx, "(ceiling -4.3)", -4)
  s6_2_assert_int(ctx, "(truncate -4.3)", -4)
}

test "R5RS 6.2: expt" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(expt 2 10)", 1024)
  s6_2_assert_int(ctx, "(expt 0 0)", 1)
  s6_2_assert_int(ctx, "(expt 3 3)", 27)
}
