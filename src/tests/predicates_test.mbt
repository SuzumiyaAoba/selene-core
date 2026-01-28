/// Testing predicate functions.

// === Numeric predicate ===

/// integer? returns #t for an integer.
test "integer? with integer" {
  let env = initial_env()
  let expr = parse_one("(integer? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// integer? returns #t for a real number with no decimal point.
test "integer? with whole real" {
  let env = initial_env()
  // sqrt(9) = 3.0
  let expr = parse_one("(integer? (sqrt 9))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// integer? returns #f for real numbers with decimal places.
test "integer? with fractional real" {
  let env = initial_env()
  // sqrt(2) has a decimal point
  let expr = parse_one("(integer? (sqrt 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// integer? returns #f for non-numeric values.
test "integer? with non-number" {
  let env = initial_env()
  let expr = parse_one("(integer? \"hello\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// real? returns #t for integers.
test "real? with integer" {
  let env = initial_env()
  let expr = parse_one("(real? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// real? returns #t for real numbers.
test "real? with real" {
  let env = initial_env()
  // sqrt(2) is a real number
  let expr = parse_one("(real? (sqrt 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// real? returns #f for non-numeric values.
test "real? with non-number" {
  let env = initial_env()
  let expr = parse_one("(real? #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// zero? returns #t for zero.
test "zero? with zero" {
  let env = initial_env()
  let expr = parse_one("(zero? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// zero? returns #f for non-zero.
test "zero? with non-zero" {
  let env = initial_env()
  let expr = parse_one("(zero? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// zero? returns #t for 0.0.
test "zero? with real zero" {
  let env = initial_env()
  // sin(0) = 0.0
  let expr = parse_one("(zero? (sin 0))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// positive? returns #t for positive numbers.
test "positive? with positive" {
  let env = initial_env()
  let expr = parse_one("(positive? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// positive? returns #f for zero.
test "positive? with zero" {
  let env = initial_env()
  let expr = parse_one("(positive? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// positive? returns #f for negative numbers.
test "positive? with negative" {
  let env = initial_env()
  let expr = parse_one("(positive? (- 0 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// negative? returns #t for negative numbers.
test "negative? with negative" {
  let env = initial_env()
  let expr = parse_one("(negative? (- 0 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// negative? returns #f for zero.
test "negative? with zero" {
  let env = initial_env()
  let expr = parse_one("(negative? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// negative? returns #f for positive numbers.
test "negative? with positive" {
  let env = initial_env()
  let expr = parse_one("(negative? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// odd? returns #t for odd numbers.
test "odd? with odd" {
  let env = initial_env()
  let expr = parse_one("(odd? 3)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// odd? returns #f for even numbers.
test "odd? with even" {
  let env = initial_env()
  let expr = parse_one("(odd? 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// odd? returns #t even for negative odd numbers.
test "odd? with negative odd" {
  let env = initial_env()
  let expr = parse_one("(odd? (- 0 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// even? returns #t for even numbers.
test "even? with even" {
  let env = initial_env()
  let expr = parse_one("(even? 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// even? returns #f for odd numbers.
test "even? with odd" {
  let env = initial_env()
  let expr = parse_one("(even? 3)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// even? returns #t for zero.
test "even? with zero" {
  let env = initial_env()
  let expr = parse_one("(even? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

// === equality predicate ===

/// eqv? returns #t for the same integer.
test "eqv? with same integers" {
  let env = initial_env()
  let expr = parse_one("(eqv? 42 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// eqv? returns #f for different integers.
test "eqv? with different integers" {
  let env = initial_env()
  let expr = parse_one("(eqv? 42 43)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// eqv? returns #t for the same symbol.
test "eqv? with same symbols" {
  let env = initial_env()
  let expr = parse_one("(eqv? 'foo 'foo)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// eqv? returns #t for the same boolean value.
test "eqv? with same booleans" {
  let env = initial_env()
  let expr = parse_one("(eqv? #t #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? ​​returns #t for the same list.
test "equal? with same lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 2 3) '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? ​​returns #f for different lists.
test "equal? with different lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 2 3) '(1 2 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// equal? ​​deeply compares nested lists.
test "equal? with nested lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 (2 3) 4) '(1 (2 3) 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? ​​returns #t for the same string.
test "equal? with same strings" {
  let env = initial_env()
  let expr = parse_one("(equal? \"hello\" \"hello\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? ​​returns #f for different strings.
test "equal? with different strings" {
  let env = initial_env()
  let expr = parse_one("(equal? \"hello\" \"world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// equal? ​​returns #t for the same vector.
test "equal? with same vectors" {
  let env = initial_env()
  let expr = parse_one("(equal? (vector 1 2 3) (vector 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? ​​returns #f for different vectors.
test "equal? with different vectors" {
  let env = initial_env()
  let expr = parse_one("(equal? (vector 1 2 3) (vector 1 2 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// === List accessor ===

/// cadr returns the second element.
test "cadr" {
  let env = initial_env()
  let expr = parse_one("(cadr '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
}

/// caddr returns the third element.
test "caddr" {
  let env = initial_env()
  let expr = parse_one("(caddr '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
}

/// cddr returns the third and subsequent lists.
test "cddr" {
  let env = initial_env()
  let expr = parse_one("(cddr '(1 2 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(3)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil))) => ()
    _ => fail("expected (3 4)")
  }
}

/// caar returns the beginning of the first element of a nested list.
test "caar" {
  let env = initial_env()
  let expr = parse_one("(caar '((1 2) 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// cdar returns the remainder of the first element of a nested list.
test "cdar" {
  let env = initial_env()
  let expr = parse_one("(cdar '((1 2 3) 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected (2 3)")
  }
}

/// cdddr returns the list starting from the fourth.
test "cdddr" {
  let env = initial_env()
  let expr = parse_one("(cdddr '(1 2 3 4 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(4)), Value::Pair(Value::Number(Number::Int(5)), Value::Nil))) => ()
    _ => fail("expected (4 5)")
  }
}
