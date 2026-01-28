/// Testing the string->number function

/// Parse a string of integers
test "string->number with integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"42\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}

/// Parse a string of negative integers
test "string->number with negative integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-123\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(-123))) => ()
    _ => fail("Expected Int(-123)")
  }
}

/// Parse string of zeros
test "string->number with zero" {
  let env = initial_env()
  let expr = parse_one("(string->number \"0\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// Parse a string of real numbers
test "string->number with double" {
  let env = initial_env()
  let expr = parse_one("(string->number \"3.14\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // Make sure the value is close to 3.14
      let diff = if r > 3.14 { r - 3.14 } else { 3.14 - r }
      if diff > 0.0001 {
        fail("Expected approximately 3.14")
      }
    }
    _ => fail("Expected Real")
  }
}

/// Parse a string of negative real numbers
test "string->number with negative double" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-2.5\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      let diff = if r > -2.5 { r - (-2.5) } else { (-2.5) - r }
      if diff > 0.0001 {
        fail("Expected approximately -2.5")
      }
    }
    _ => fail("Expected Real")
  }
}

/// Parse string in scientific notation
test "string->number with exponential notation" {
  let env = initial_env()
  let expr = parse_one("(string->number \"1.5e2\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Real(r))) => {
      // 1.5e2 = 150.0
      let diff = if r > 150.0 { r - 150.0 } else { 150.0 - r }
      if diff > 0.0001 {
        fail("Expected approximately 150.0")
      }
    }
    _ => fail("Expected Real")
  }
}

/// Invalid string (not a number)
test "string->number with invalid string" {
  let env = initial_env()
  let expr = parse_one("(string->number \"not a number\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// empty string
test "string->number with empty string" {
  let env = initial_env()
  let expr = parse_one("(string->number \"\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// string containing spaces
test "string->number with whitespace" {
  let env = initial_env()
  let expr = parse_one("(string->number \" 42 \")")
  match eval(expr, env) {
    // Whether whitespace is trimmed is implementation dependent
    // Will it be successful or #f?
    Ok(_) => ()
    _ => fail("Expected some value")
  }
}

/// large integer
test "string->number with large integer" {
  let env = initial_env()
  let expr = parse_one("(string->number \"999999\")")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(999999))) => ()
    _ => fail("Expected Int(999999)")
  }
}

/// string with only decimal point
test "string->number with just decimal point" {
  let env = initial_env()
  let expr = parse_one("(string->number \".\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// string of signs only
test "string->number with just sign" {
  let env = initial_env()
  let expr = parse_one("(string->number \"-\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Use the result of string->number in calculations
test "string->number in calculation" {
  let env = initial_env()
  let expr = parse_one("(+ (string->number \"10\") (string->number \"32\"))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}

/// Round trip conversion of string->number and number->string
test "string->number and number->string round trip" {
  let env = initial_env()
  let expr = parse_one("(string->number (number->string 42))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected Int(42)")
  }
}
