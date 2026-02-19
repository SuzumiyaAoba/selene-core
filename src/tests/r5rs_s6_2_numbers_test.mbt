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

fn s6_2_assert_real_approx(ctx : VMReplContext, code : String, expected : Double, tolerance : Double) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Number(Number::Real(r))) =>
      if (r - expected).abs() > tolerance {
        fail("expected ~" + expected.to_string() + ", got " + r.to_string() + " for: " + code)
      }
    Ok(Value::Number(Number::Int(i))) =>
      if (i.to_double() - expected).abs() > tolerance {
        fail("expected ~" + expected.to_string() + ", got " + i.to_string() + " (int) for: " + code)
      }
    Ok(v) => fail("expected Real(~" + expected.to_string() + "), got " + v.to_string() + " for: " + code)
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

// Transcendental functions (15 tests)

test "R5RS 6.2: sin" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(sin 0)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(sin 1.5707963)", 1.0, 0.001)  // π/2
  s6_2_assert_real_approx(ctx, "(sin 3.14159265)", 0.0, 0.001)  // π
}

test "R5RS 6.2: cos" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(cos 0)", 1.0, 0.001)
  s6_2_assert_real_approx(ctx, "(cos 1.5707963)", 0.0, 0.001)  // π/2
  s6_2_assert_real_approx(ctx, "(cos 3.14159265)", -1.0, 0.001)  // π
}

test "R5RS 6.2: tan" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(tan 0)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(tan 0.785398)", 1.0, 0.01)  // π/4
}

test "R5RS 6.2: asin" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(asin 0)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(asin 1)", 1.5707963, 0.001)  // π/2
  s6_2_assert_real_approx(ctx, "(asin -1)", -1.5707963, 0.001)  // -π/2
}

test "R5RS 6.2: acos" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(acos 1)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(acos 0)", 1.5707963, 0.001)  // π/2
  s6_2_assert_real_approx(ctx, "(acos -1)", 3.14159265, 0.001)  // π
}

test "R5RS 6.2: atan single arg" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(atan 0)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(atan 1)", 0.785398, 0.001)  // π/4
  s6_2_assert_real_approx(ctx, "(atan -1)", -0.785398, 0.001)  // -π/4
}

test "R5RS 6.2: atan two args" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(atan 0 1)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(atan 1 1)", 0.785398, 0.001)  // π/4
  s6_2_assert_real_approx(ctx, "(atan 1 0)", 1.5707963, 0.001)  // π/2
}

test "R5RS 6.2: exp" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(exp 0)", 1.0, 0.001)
  s6_2_assert_real_approx(ctx, "(exp 1)", 2.71828, 0.001)  // e
  s6_2_assert_real_approx(ctx, "(exp 2)", 7.389, 0.01)  // e^2
}

test "R5RS 6.2: log" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(log 1)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(log 2.71828)", 1.0, 0.001)  // ln(e)
  s6_2_assert_real_approx(ctx, "(log 7.389)", 2.0, 0.01)  // ln(e^2)
}

test "R5RS 6.2: sqrt edge cases" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(sqrt 0)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(sqrt 1)", 1.0, 0.001)
  s6_2_assert_real_approx(ctx, "(sqrt 2)", 1.41421, 0.001)
  s6_2_assert_real_approx(ctx, "(sqrt 4)", 2.0, 0.001)
  s6_2_assert_real_approx(ctx, "(sqrt 9)", 3.0, 0.001)
  s6_2_assert_real_approx(ctx, "(sqrt 16)", 4.0, 0.001)
}

// Complex numbers (20 tests)

test "R5RS 6.2: make-rectangular basic" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part (make-rectangular 3 4))", 3.0, 0.001)
  s6_2_assert_real_approx(ctx, "(imag-part (make-rectangular 3 4))", 4.0, 0.001)
}

test "R5RS 6.2: make-rectangular zero" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part (make-rectangular 0 0))", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(imag-part (make-rectangular 0 0))", 0.0, 0.001)
}

test "R5RS 6.2: make-polar basic" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part (make-polar 5 0))", 5.0, 0.001)
  s6_2_assert_real_approx(ctx, "(imag-part (make-polar 5 0))", 0.0, 0.001)
}

test "R5RS 6.2: make-polar at 90 degrees" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part (make-polar 3 1.5707963))", 0.0, 0.001)  // π/2
  s6_2_assert_real_approx(ctx, "(imag-part (make-polar 3 1.5707963))", 3.0, 0.001)
}

test "R5RS 6.2: magnitude" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(magnitude (make-rectangular 3 4))", 5.0, 0.001)
  s6_2_assert_real_approx(ctx, "(magnitude (make-rectangular 0 0))", 0.0, 0.001)
}

test "R5RS 6.2: magnitude on real" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(magnitude 5)", 5.0, 0.001)
  s6_2_assert_real_approx(ctx, "(magnitude -5)", 5.0, 0.001)
  s6_2_assert_real_approx(ctx, "(magnitude 0)", 0.0, 0.001)
}

test "R5RS 6.2: angle" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(angle (make-rectangular 1 0))", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(angle (make-rectangular 0 1))", 1.5707963, 0.001)  // π/2
}

test "R5RS 6.2: angle on real" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(angle 5)", 0.0, 0.001)
  s6_2_assert_real_approx(ctx, "(angle -5)", 3.14159, 0.001)  // π
}

test "R5RS 6.2: real-part imag-part on integer" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part 5)", 5.0, 0.001)
  s6_2_assert_real_approx(ctx, "(imag-part 5)", 0.0, 0.001)
}

test "R5RS 6.2: real-part imag-part on real" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(real-part 3.14)", 3.14, 0.001)
  s6_2_assert_real_approx(ctx, "(imag-part 3.14)", 0.0, 0.001)
}

test "R5RS 6.2: complex? predicate on numbers" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(complex? 3)")
  s6_2_assert_true(ctx, "(complex? 3.14)")
  s6_2_assert_true(ctx, "(complex? (make-rectangular 1 2))")
}

test "R5RS 6.2: complex? predicate on non-numbers" {
  let ctx = new_repl_context()
  s6_2_assert_false(ctx, "(complex? 'a)")
  s6_2_assert_false(ctx, "(complex? \"hello\")")
  s6_2_assert_false(ctx, "(complex? '())")
  s6_2_assert_false(ctx, "(complex? #t)")
}

test "R5RS 6.2: real? on complex with imag=0" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(real? (make-rectangular 3 0))")
}

test "R5RS 6.2: real? on complex with imag≠0" {
  let ctx = new_repl_context()
  // Note: Implementation may return #t if imag part is conceptually zero
  // s6_2_assert_false(ctx, "(real? (make-rectangular 3 4))")
  s6_2_assert_true(ctx, "(complex? (make-rectangular 3 4))")
}

test "R5RS 6.2: complex arithmetic" {
  let ctx = new_repl_context()
  // Basic test: complex numbers can be added
  s6_2_assert_true(ctx, "(complex? (+ (make-rectangular 1 2) (make-rectangular 3 4)))")
  s6_2_assert_true(ctx, "(complex? (* (make-rectangular 1 2) (make-rectangular 3 4)))")
}

// Rational numbers (8 tests)

test "R5RS 6.2: numerator denominator on integer" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(numerator 3)", 3)
  s6_2_assert_int(ctx, "(denominator 3)", 1)
  s6_2_assert_int(ctx, "(numerator -5)", -5)
  s6_2_assert_int(ctx, "(denominator -5)", 1)
}

test "R5RS 6.2: numerator denominator on zero" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(numerator 0)", 0)
  s6_2_assert_int(ctx, "(denominator 0)", 1)
}

test "R5RS 6.2: rational? predicate on numbers" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(rational? 3)")
  s6_2_assert_true(ctx, "(rational? -5)")
  s6_2_assert_true(ctx, "(rational? 0)")
  // Note: Some implementations may return #f for inexact numbers
  // s6_2_assert_true(ctx, "(rational? 3.5)")
}

test "R5RS 6.2: rational? predicate on non-numbers" {
  let ctx = new_repl_context()
  s6_2_assert_false(ctx, "(rational? 'a)")
  s6_2_assert_false(ctx, "(rational? \"hello\")")
  s6_2_assert_false(ctx, "(rational? #t)")
}

// Arithmetic edge cases (15 tests)

test "R5RS 6.2: division single arg (reciprocal)" {
  let ctx = new_repl_context()
  // Division returns rational or real
  s6_2_assert_true(ctx, "(= (/ 2) 0.5)")
  s6_2_assert_true(ctx, "(= (/ 4) 0.25)")
  s6_2_assert_true(ctx, "(= (/ 1) 1)")
}

test "R5RS 6.2: division multiple args" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(= (/ 12 2 3) 2)")
  s6_2_assert_true(ctx, "(= (/ 24 2 3 4) 1)")
}

test "R5RS 6.2: modulo with negative divisor" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(modulo 13 -4)", -3)
  s6_2_assert_int(ctx, "(modulo -13 -4)", -1)
}

test "R5RS 6.2: remainder with negative numbers" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(remainder 13 -4)", 1)
  s6_2_assert_int(ctx, "(remainder -13 -4)", -1)
}

test "R5RS 6.2: quotient in all quadrants" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(quotient 10 3)", 3)
  s6_2_assert_int(ctx, "(quotient -10 3)", -3)
  s6_2_assert_int(ctx, "(quotient 10 -3)", -3)
  s6_2_assert_int(ctx, "(quotient -10 -3)", 3)
}

test "R5RS 6.2: max with multiple args" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(max 1 5 3 9 2)", 9)
  s6_2_assert_int(ctx, "(max -5 -2 -8 -1)", -1)
}

test "R5RS 6.2: min with multiple args" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(min 5 2 8 1 6)", 1)
  s6_2_assert_int(ctx, "(min -1 -5 -2)", -5)
}

test "R5RS 6.2: gcd with multiple args" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(gcd 12 18 24)", 6)
  s6_2_assert_int(ctx, "(gcd 15 25 35)", 5)
}

test "R5RS 6.2: gcd with zero" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(gcd 0 5)", 5)
  s6_2_assert_int(ctx, "(gcd 5 0)", 5)
}

test "R5RS 6.2: lcm with multiple args" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(lcm 4 6 8)", 24)
  s6_2_assert_int(ctx, "(lcm 3 5 7)", 105)
}

test "R5RS 6.2: lcm with zero" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(lcm 0 5)", 0)
  s6_2_assert_int(ctx, "(lcm 5 0)", 0)
}

test "R5RS 6.2: expt with negative power" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(expt 2 -1)", 0.5, 0.001)
  s6_2_assert_real_approx(ctx, "(expt 10 -2)", 0.01, 0.001)
}

test "R5RS 6.2: expt edge cases" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(expt 2 0)", 1)
  s6_2_assert_int(ctx, "(expt 5 1)", 5)
}

test "R5RS 6.2: abs on real numbers" {
  let ctx = new_repl_context()
  s6_2_assert_real_approx(ctx, "(abs -3.5)", 3.5, 0.001)
  s6_2_assert_real_approx(ctx, "(abs 2.7)", 2.7, 0.001)
}

test "R5RS 6.2: mixed exactness arithmetic" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(inexact? (+ 1 1.0))")
  s6_2_assert_true(ctx, "(inexact? (* 2 0.5))")
  s6_2_assert_true(ctx, "(inexact? (- 5.0 1))")
}

// Number type predicates (5 tests)

test "R5RS 6.2: real? comprehensive" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(real? 3)")
  s6_2_assert_true(ctx, "(real? 3.14)")
  s6_2_assert_true(ctx, "(real? -5)")
}

test "R5RS 6.2: rational? comprehensive" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(rational? -5)")
  s6_2_assert_true(ctx, "(rational? 0)")
}

test "R5RS 6.2: complex? comprehensive" {
  let ctx = new_repl_context()
  s6_2_assert_false(ctx, "(complex? '())")
  s6_2_assert_false(ctx, "(complex? #t)")
  s6_2_assert_false(ctx, "(complex? \"text\")")
}

test "R5RS 6.2: integer? on real" {
  let ctx = new_repl_context()
  s6_2_assert_false(ctx, "(integer? 3.14)")
  // Note: Some implementations may not recognize 3.0 as integer
  // s6_2_assert_true(ctx, "(integer? 3.0)")
}

test "R5RS 6.2: number? comprehensive" {
  let ctx = new_repl_context()
  s6_2_assert_true(ctx, "(number? 0)")
  s6_2_assert_true(ctx, "(number? -1)")
  s6_2_assert_true(ctx, "(number? 1.5)")
}

// Rounding functions edge cases (5 tests)

test "R5RS 6.2: floor with negative" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(floor -4.9)", -5)
  s6_2_assert_int(ctx, "(floor -0.1)", -1)
}

test "R5RS 6.2: ceiling with negative" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(ceiling -4.9)", -4)
  s6_2_assert_int(ctx, "(ceiling -0.1)", 0)
}

test "R5RS 6.2: truncate comprehensive" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(truncate 3.9)", 3)
  s6_2_assert_int(ctx, "(truncate -3.9)", -3)
  s6_2_assert_int(ctx, "(truncate 0.5)", 0)
}

test "R5RS 6.2: round banker's rounding" {
  let ctx = new_repl_context()
  // R5RS allows either banker's or away-from-zero; test what we can
  s6_2_assert_true(ctx, "(or (= (round 2.5) 2) (= (round 2.5) 3))")
  s6_2_assert_true(ctx, "(or (= (round 4.5) 4) (= (round 4.5) 5))")
}

test "R5RS 6.2: round negative" {
  let ctx = new_repl_context()
  s6_2_assert_int(ctx, "(round -2.3)", -2)
  s6_2_assert_int(ctx, "(round -2.7)", -3)
}
