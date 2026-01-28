/// Testing list manipulation functions.

/// Testing the list function.
test "builtin list" {
  let env = initial_env()
  let expr1 = parse_one("(list)")
  let expr2 = parse_one("(list 1)")
  let expr3 = parse_one("(list 1 2 3)")
  match eval(expr1, env) {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Nil)) => ()
    _ => fail("expected (1)")
  }
  match eval(expr3, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Pair(Value::Number(Number::Int(3)), Value::Nil)))) => ()
    _ => fail("expected (1 2 3)")
  }
}

/// Testing the length function.
test "builtin length" {
  let env = initial_env()
  let expr1 = parse_one("(length ())")
  let expr2 = parse_one("(length (list 1))")
  let expr3 = parse_one("(length (list 1 2 3))")
  let expr4 = parse_one("(length (list 1 2 3 4 5))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("expected 0")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
  match eval(expr4, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// Testing the append function.
test "builtin append" {
  let env = initial_env()
  let expr1 = parse_one("(append)")
  let expr2 = parse_one("(append (list 1 2))")
  let expr3 = parse_one("(append (list 1 2) (list 3 4))")
  let expr4 = parse_one("(append (list 1) (list 2) (list 3))")
  match eval(expr1, env) {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Nil))) => ()
    _ => fail("expected (1 2)")
  }
  match eval(expr3, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), _)) => ()
    _ => fail("expected list starting with 1")
  }
  match eval(expr4, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), _)) => ()
    _ => fail("expected list starting with 1")
  }
}

/// Testing the reverse function.
test "builtin reverse" {
  let env = initial_env()
  let expr1 = parse_one("(reverse ())")
  let expr2 = parse_one("(reverse (list 1))")
  let expr3 = parse_one("(reverse (list 1 2 3))")
  match eval(expr1, env) {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Nil)) => ()
    _ => fail("expected (1)")
  }
  match eval(expr3, env) {
    Ok(Value::Pair(Value::Number(Number::Int(3)), Value::Pair(Value::Number(Number::Int(2)), Value::Pair(Value::Number(Number::Int(1)), Value::Nil)))) => ()
    _ => fail("expected (3 2 1)")
  }
}

/// Testing the list-ref function.
test "builtin list-ref" {
  let env = initial_env()
  let expr1 = parse_one("(list-ref (list 1 2 3) 0)")
  let expr2 = parse_one("(list-ref (list 1 2 3) 1)")
  let expr3 = parse_one("(list-ref (list 1 2 3) 2)")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
  match eval(expr3, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    _ => fail("expected 3")
  }
}

/// Testing the list-tail function.
test "builtin list-tail" {
  let env = initial_env()
  let expr1 = parse_one("(list-tail (list 1 2 3) 0)")
  let expr2 = parse_one("(list-tail (list 1 2 3) 1)")
  let expr3 = parse_one("(list-tail (list 1 2 3) 2)")
  let expr4 = parse_one("(list-tail (list 1 2 3) 3)")
  match eval(expr1, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), _)) => ()
    _ => fail("expected list starting with 1")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected list starting with 2")
  }
  match eval(expr3, env) {
    Ok(Value::Pair(Value::Number(Number::Int(3)), Value::Nil)) => ()
    _ => fail("expected (3)")
  }
  match eval(expr4, env) {
    Ok(Value::Nil) => ()
    _ => fail("expected ()")
  }
}

/// Combination test of append and length.
test "append and length" {
  let env = initial_env()
  let expr = parse_one("(length (append (list 1 2) (list 3 4) (list 5)))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// Combination test of reverse and list-ref.
test "reverse and list-ref" {
  let env = initial_env()
  let expr = parse_one("(list-ref (reverse (list 1 2 3 4 5)) 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("expected 5")
  }
}

/// Testing cons functions.
test "builtin cons" {
  let env = initial_env()
  let expr1 = parse_one("(cons 1 2)")
  let expr2 = parse_one("(cons 1 ())")
  let expr3 = parse_one("(cons 1 (cons 2 ()))")
  match eval(expr1, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Number(Number::Int(2)))) => ()
    _ => fail("expected (1 . 2)")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Nil)) => ()
    _ => fail("expected (1)")
  }
  match eval(expr3, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Nil))) => ()
    _ => fail("expected (1 2)")
  }
}

/// Testing the car function.
test "builtin car" {
  let env = initial_env()
  let expr1 = parse_one("(car (cons 1 2))")
  let expr2 = parse_one("(car (list 1 2 3))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
  match eval(expr2, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    _ => fail("expected 1")
  }
}

/// Testing the cdr function.
test "builtin cdr" {
  let env = initial_env()
  let expr1 = parse_one("(cdr (cons 1 2))")
  let expr2 = parse_one("(cdr (list 1 2 3))")
  match eval(expr1, env) {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
  match eval(expr2, env) {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected list starting with 2")
  }
}

/// Testing the pair? function.
test "builtin pair?" {
  let env = initial_env()
  let expr1 = parse_one("(pair? (cons 1 2))")
  let expr2 = parse_one("(pair? ())")
  let expr3 = parse_one("(pair? 42)")
  let expr4 = parse_one("(pair? (list 1 2 3))")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
  match eval(expr4, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
}

/// Testing the number? function.
test "builtin number?" {
  let env = initial_env()
  // Create and test SExpr directly
  let expr1 = SExpr::Pair(
    SExpr::Symbol("number?"),
    SExpr::Pair(SExpr::Number(42), SExpr::Nil)
  )
  let expr2 = SExpr::Pair(
    SExpr::Symbol("number?"),
    SExpr::Pair(SExpr::Nil, SExpr::Nil)
  )
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for number? of 42")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for number? of nil")
  }
}

/// boolean? function test.
test "builtin boolean?" {
  let env = initial_env()
  // Create and test SExpr directly
  let expr1 = SExpr::Pair(
    SExpr::Symbol("boolean?"),
    SExpr::Pair(SExpr::Quote(SExpr::Symbol("true")), SExpr::Nil)
  )
  let expr2 = SExpr::Pair(
    SExpr::Symbol("boolean?"),
    SExpr::Pair(SExpr::Number(42), SExpr::Nil)
  )
  match eval(expr1, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for boolean? of symbol")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for boolean? of number")
  }
}

/// Testing the symbol? function.
test "builtin symbol?" {
  let env = initial_env()
  // Create SExpr directly and test through eval
  let expr1 = SExpr::Pair(
    SExpr::Symbol("symbol?"),
    SExpr::Pair(SExpr::Quote(SExpr::Symbol("test")), SExpr::Nil)
  )
  let expr2 = SExpr::Pair(
    SExpr::Symbol("symbol?"),
    SExpr::Pair(SExpr::Number(42), SExpr::Nil)
  )
  let expr3 = SExpr::Pair(
    SExpr::Symbol("symbol?"),
    SExpr::Pair(SExpr::Quote(SExpr::Number(99)), SExpr::Nil)
  )
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t for symbol")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for number")
  }
  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f for quoted number")
  }
}

/// Testing the null? function.
test "builtin null?" {
  let env = initial_env()
  let expr1 = parse_one("(null? ())")
  let expr2 = parse_one("(null? (list 1))")
  let expr3 = parse_one("(null? 42)")
  match eval(expr1, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("expected #t")
  }
  match eval(expr2, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
  match eval(expr3, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}
