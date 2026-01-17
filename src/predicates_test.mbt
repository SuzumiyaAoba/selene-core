/// 述語関数のテスト。

// === 数値述語 ===

/// integer? は整数に対して #t を返す。
test "integer? with integer" {
  let env = initial_env()
  let expr = parse_one("(integer? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// integer? は小数点以下がない実数に対して #t を返す。
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

/// integer? は小数点以下がある実数に対して #f を返す。
test "integer? with fractional real" {
  let env = initial_env()
  // sqrt(2) は小数点以下がある
  let expr = parse_one("(integer? (sqrt 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// integer? は非数値に対して #f を返す。
test "integer? with non-number" {
  let env = initial_env()
  let expr = parse_one("(integer? \"hello\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// real? は整数に対して #t を返す。
test "real? with integer" {
  let env = initial_env()
  let expr = parse_one("(real? 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// real? は実数に対して #t を返す。
test "real? with real" {
  let env = initial_env()
  // sqrt(2) は実数
  let expr = parse_one("(real? (sqrt 2))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// real? は非数値に対して #f を返す。
test "real? with non-number" {
  let env = initial_env()
  let expr = parse_one("(real? #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// zero? はゼロに対して #t を返す。
test "zero? with zero" {
  let env = initial_env()
  let expr = parse_one("(zero? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// zero? は非ゼロに対して #f を返す。
test "zero? with non-zero" {
  let env = initial_env()
  let expr = parse_one("(zero? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// zero? は 0.0 に対して #t を返す。
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

/// positive? は正の数に対して #t を返す。
test "positive? with positive" {
  let env = initial_env()
  let expr = parse_one("(positive? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// positive? はゼロに対して #f を返す。
test "positive? with zero" {
  let env = initial_env()
  let expr = parse_one("(positive? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// positive? は負の数に対して #f を返す。
test "positive? with negative" {
  let env = initial_env()
  let expr = parse_one("(positive? (- 0 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// negative? は負の数に対して #t を返す。
test "negative? with negative" {
  let env = initial_env()
  let expr = parse_one("(negative? (- 0 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// negative? はゼロに対して #f を返す。
test "negative? with zero" {
  let env = initial_env()
  let expr = parse_one("(negative? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// negative? は正の数に対して #f を返す。
test "negative? with positive" {
  let env = initial_env()
  let expr = parse_one("(negative? 5)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// odd? は奇数に対して #t を返す。
test "odd? with odd" {
  let env = initial_env()
  let expr = parse_one("(odd? 3)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// odd? は偶数に対して #f を返す。
test "odd? with even" {
  let env = initial_env()
  let expr = parse_one("(odd? 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// odd? は負の奇数に対しても #t を返す。
test "odd? with negative odd" {
  let env = initial_env()
  let expr = parse_one("(odd? (- 0 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// even? は偶数に対して #t を返す。
test "even? with even" {
  let env = initial_env()
  let expr = parse_one("(even? 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// even? は奇数に対して #f を返す。
test "even? with odd" {
  let env = initial_env()
  let expr = parse_one("(even? 3)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// even? はゼロに対して #t を返す。
test "even? with zero" {
  let env = initial_env()
  let expr = parse_one("(even? 0)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

// === 等価述語 ===

/// eqv? は同じ整数に対して #t を返す。
test "eqv? with same integers" {
  let env = initial_env()
  let expr = parse_one("(eqv? 42 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// eqv? は異なる整数に対して #f を返す。
test "eqv? with different integers" {
  let env = initial_env()
  let expr = parse_one("(eqv? 42 43)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// eqv? は同じシンボルに対して #t を返す。
test "eqv? with same symbols" {
  let env = initial_env()
  let expr = parse_one("(eqv? 'foo 'foo)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// eqv? は同じブール値に対して #t を返す。
test "eqv? with same booleans" {
  let env = initial_env()
  let expr = parse_one("(eqv? #t #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? は同じリストに対して #t を返す。
test "equal? with same lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 2 3) '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? は異なるリストに対して #f を返す。
test "equal? with different lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 2 3) '(1 2 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// equal? はネストしたリストを深く比較する。
test "equal? with nested lists" {
  let env = initial_env()
  let expr = parse_one("(equal? '(1 (2 3) 4) '(1 (2 3) 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? は同じ文字列に対して #t を返す。
test "equal? with same strings" {
  let env = initial_env()
  let expr = parse_one("(equal? \"hello\" \"hello\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? は異なる文字列に対して #f を返す。
test "equal? with different strings" {
  let env = initial_env()
  let expr = parse_one("(equal? \"hello\" \"world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// equal? は同じベクタに対して #t を返す。
test "equal? with same vectors" {
  let env = initial_env()
  let expr = parse_one("(equal? (vector 1 2 3) (vector 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// equal? は異なるベクタに対して #f を返す。
test "equal? with different vectors" {
  let env = initial_env()
  let expr = parse_one("(equal? (vector 1 2 3) (vector 1 2 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// === リストアクセサ ===

/// cadr は2番目の要素を返す。
test "cadr" {
  let env = initial_env()
  let expr = parse_one("(cadr '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
}

/// caddr は3番目の要素を返す。
test "caddr" {
  let env = initial_env()
  let expr = parse_one("(caddr '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
}

/// cddr は3番目以降のリストを返す。
test "cddr" {
  let env = initial_env()
  let expr = parse_one("(cddr '(1 2 3 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(3)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil))) => ()
    _ => fail("expected (3 4)")
  }
}

/// caar はネストしたリストの最初の要素の最初を返す。
test "caar" {
  let env = initial_env()
  let expr = parse_one("(caar '((1 2) 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// cdar はネストしたリストの最初の要素の残りを返す。
test "cdar" {
  let env = initial_env()
  let expr = parse_one("(cdar '((1 2 3) 4))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected (2 3)")
  }
}

/// cdddr は4番目以降のリストを返す。
test "cdddr" {
  let env = initial_env()
  let expr = parse_one("(cdddr '(1 2 3 4 5))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(4)), Value::Pair(Value::Number(Number::Int(5)), Value::Nil))) => ()
    _ => fail("expected (4 5)")
  }
}
