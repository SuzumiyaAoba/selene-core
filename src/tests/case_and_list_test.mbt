/// testing case special formats and associative lists/membership functions.

// = = = case special form = = =

/// the case evaluates the key to match the datum.
test "case basic match" {
  let env = initial_env()
  let expr = parse_one("(case 2 ((1) 'one) ((2) 'two) ((3) 'three))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("two")) => ()
    _ => fail("expected 'two")
  }
}

/// clause with multiple datums in case.
test "case multiple datums" {
  let env = initial_env()
  let expr = parse_one("(case 5 ((1 2 3) 'small) ((4 5 6) 'medium) ((7 8 9) 'large))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("medium")) => ()
    _ => fail("expected 'medium")
  }
}

/// else clause of the case.
test "case else clause" {
  let env = initial_env()
  let expr = parse_one("(case 10 ((1) 'one) ((2) 'two) (else 'other))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("other")) => ()
    _ => fail("expected 'other")
  }
}

/// undefined value (nil) if case does not match.
test "case no match no else" {
  let env = initial_env()
  let expr = parse_one("(case 10 ((1) 'one) ((2) 'two))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail("expected nil")
  }
}

/// match symbols with case.
test "case match symbol" {
  let env = initial_env()
  let expr = parse_one("(case 'apple ((orange) 1) ((apple) 2) ((banana) 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
}

/// the key of the case is evaluated as an expression.
test "case evaluates key" {
  let env = initial_env()
  let expr = parse_one("(case (+ 1 1) ((1) 'one) ((2) 'two) ((3) 'three))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("two")) => ()
    _ => fail("expected 'two")
  }
}

/// the body of a case can have multiple expressions.
test "case multiple body expressions" {
  let env = initial_env()
  let expr = parse_one("(case 1 ((1) (+ 1 2) (+ 3 4)) ((2) 0))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("expected 7")
  }
}

// = = = associative list function = = =

/// search for assq by eq?
test "assq found" {
  let env = initial_env()
  // build list with list (use normal pair instead of dotted pair)
  let expr = parse_one("(assq 'b (list (list 'a 1) (list 'b 2) (list 'c 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("b"), _)) => ()
    _ => fail("expected pair starting with 'b")
  }
}

/// # f if not found in assq.
test "assq not found" {
  let env = initial_env()
  let expr = parse_one("(assq 'd (list (list 'a 1) (list 'b 2) (list 'c 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// search for assv by eqv? (numbers are also searchable).
test "assv with numbers" {
  let env = initial_env()
  let expr = parse_one("(assv 2 (list (list 1 'a) (list 2 'b) (list 3 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected pair starting with 2")
  }
}

/// search for assoc with equal? (list can also be searched).
test "assoc with lists" {
  let env = initial_env()
  let expr = parse_one("(assoc '(1 2) (list (list '(1) 'a) (list '(1 2) 'b) (list '(1 2 3) 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected pair")
  }
}

/// # f if not found in assoc.
test "assoc not found" {
  let env = initial_env()
  let expr = parse_one("(assoc '(1 2 3 4) (list (list '(1) 'a) (list '(1 2) 'b) (list '(1 2 3) 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// = = = Membership function = = =

/// memq searches for eq? and returns a list from the location found.
test "memq found" {
  let env = initial_env()
  let expr = parse_one("(memq 'b '(a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil))) => ()
    _ => fail("expected (b c)")
  }
}

/// # f if not found in memq.
test "memq not found" {
  let env = initial_env()
  let expr = parse_one("(memq 'd '(a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// search memv by eqv? (numeric values are also searchable).
test "memv with numbers" {
  let env = initial_env()
  let expr = parse_one("(memv 2 '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected list starting with 2")
  }
}

/// search for member with equal? (list is also searchable).
test "member with lists" {
  let env = initial_env()
  let expr = parse_one("(member '(2) '((1) (2) (3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected list")
  }
}

/// # f if not found in member.
test "member not found" {
  let env = initial_env()
  let expr = parse_one("(member '(4) '((1) (2) (3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// = = = Symbol conversion function = = =

/// symbol - > string converts a symbol into a string.
test "symbol->string" {
  let env = initial_env()
  let expr = parse_one("(symbol->string 'hello)")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("hello")) => ()
    _ => fail("expected \"hello\"")
  }
}

/// string - > symbol converts a string into a symbol.
test "string->symbol" {
  let env = initial_env()
  let expr = parse_one("(string->symbol \"world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("world")) => ()
    _ => fail("expected 'world")
  }
}

/// Return of the conversion.
test "symbol string round trip" {
  let env = initial_env()
  let expr = parse_one("(string->symbol (symbol->string 'foo))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("foo")) => ()
    _ => fail("expected 'foo")
  }
}

/// error passing non-symbol to symbol- > string.
test "symbol->string with non-symbol" {
  let env = initial_env()
  let expr = parse_one("(symbol->string 42)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}

/// error passing non-string to string- > symbol.
test "string->symbol with non-string" {
  let env = initial_env()
  let expr = parse_one("(string->symbol 'foo)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}
