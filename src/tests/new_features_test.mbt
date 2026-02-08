/// Testing new features
///
/// Testing string comparisons, variable pair operations, and higher-order functions

// ===== String comparison operators =====

test "string<? compares strings lexicographically" {
  let env = initial_env()
  let expr = parse_one("(string<? \"abc\" \"abd\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for \"abc\" < \"abd\"")
  }
}

test "string<? returns false for equal strings" {
  let env = initial_env()
  let expr = parse_one("(string<? \"abc\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected #f for \"abc\" < \"abc\"")
  }
}

test "string>? compares strings" {
  let env = initial_env()
  let expr = parse_one("(string>? \"abd\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for \"abd\" > \"abc\"")
  }
}

test "string<=? with equal strings" {
  let env = initial_env()
  let expr = parse_one("(string<=? \"abc\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for \"abc\" <= \"abc\"")
  }
}

test "string>=? with greater string" {
  let env = initial_env()
  let expr = parse_one("(string>=? \"abd\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for \"abd\" >= \"abc\"")
  }
}

// ===== Case-insensitive string comparison =====

test "string-ci=? ignores case" {
  let env = initial_env()
  let expr = parse_one("(string-ci=? \"ABC\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for case-insensitive equality")
  }
}

test "string-ci<? ignores case" {
  let env = initial_env()
  let expr = parse_one("(string-ci<? \"ABC\" \"abd\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for case-insensitive less than")
  }
}

test "string-ci>? ignores case" {
  let env = initial_env()
  let expr = parse_one("(string-ci>? \"ABD\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for case-insensitive greater than")
  }
}

test "string-ci<=? ignores case" {
  let env = initial_env()
  let expr = parse_one("(string-ci<=? \"ABC\" \"ABC\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for case-insensitive <=")
  }
}

test "string-ci>=? ignores case" {
  let env = initial_env()
  let expr = parse_one("(string-ci>=? \"ABC\" \"abc\")")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected #t for case-insensitive >=")
  }
}

// ===== Variable pair operation =====

test "set-car! creates new pair with new car" {
  let env = initial_env()
  let expr = parse_one("(set-car! (cons 1 2) 10)")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(10)), Value::Number(Number::Int(2)), _)) =>
      ()
    _ => fail("Expected (10 . 2)")
  }
}

test "set-cdr! creates new pair with new cdr" {
  let env = initial_env()
  let expr = parse_one("(set-cdr! (cons 1 2) 20)")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Number(Number::Int(20)), _)) =>
      ()
    _ => fail("Expected (1 . 20)")
  }
}

test "set-car! type error for non-pair" {
  let env = initial_env()
  let expr = parse_one("(set-car! 5 10)")
  match eval(expr, env) {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("Expected TypeError for set-car! on non-pair")
  }
}

test "set-cdr! type error for non-pair" {
  let env = initial_env()
  let expr = parse_one("(set-cdr! 5 10)")
  match eval(expr, env) {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("Expected TypeError for set-cdr! on non-pair")
  }
}

// ===== filter =====

test "filter selects elements" {
  let env = initial_env()
  let expr = parse_one("(filter (lambda (x) (> x 2)) '(1 2 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(3)), Value::Pair(Value::Number(Number::Int(4)), Value::Pair(Value::Number(Number::Int(5)), Value::Nil, _), _), _)) =>
      ()
    _ => fail("Expected (3 4 5)")
  }
}

test "filter with empty result" {
  let env = initial_env()
  let expr = parse_one("(filter (lambda (x) (> x 10)) '(1 2 3))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected empty list")
  }
}

test "filter with empty list" {
  let env = initial_env()
  let expr = parse_one("(filter (lambda (x) #t) '())")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected empty list")
  }
}

// ===== fold-left =====

test "fold-left sums list" {
  let env = initial_env()
  let expr = parse_one("(fold-left + 0 '(1 2 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(15))) => ()
    _ => fail("Expected 15")
  }
}

test "fold-left with subtraction shows left-to-right" {
  let env = initial_env()
  // (((0 - 1) - 2) - 3) = -6
  let expr = parse_one("(fold-left - 0 '(1 2 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(-6))) => ()
    _ => fail("Expected -6")
  }
}

test "fold-left with empty list returns init" {
  let env = initial_env()
  let expr = parse_one("(fold-left + 42 '())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected 42")
  }
}

// ===== fold-right =====

test "fold-right sums list" {
  let env = initial_env()
  let expr = parse_one("(fold-right + 0 '(1 2 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(15))) => ()
    _ => fail("Expected 15")
  }
}

test "fold-right with cons builds list" {
  let env = initial_env()
  let expr = parse_one("(fold-right cons '() '(1 2 3))")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Pair(Value::Number(Number::Int(3)), Value::Nil, _), _), _)) =>
      ()
    _ => fail("Expected (1 2 3)")
  }
}

test "fold-right with empty list returns init" {
  let env = initial_env()
  let expr = parse_one("(fold-right + 42 '())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected 42")
  }
}
