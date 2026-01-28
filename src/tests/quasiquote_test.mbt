/// Testing the quasiquote deployment.

/// A simple quasiquote (without unquote) returns a literal.
test "quasiquote without unquote" {
  let env = initial_env()
  let expr = parse_one("`(a b c)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// Expand variables with unquote.
test "quasiquote with unquote variable" {
  let env = initial_env()
  let env = define_var(env, "x", Value::Number(Number::Int(42)))
  let expr = parse_one("`(a ,x c)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Number(Number::Int(42)), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a 42 c)")
  }
}

/// Evaluate the expression with unquote.
test "quasiquote with unquote expression" {
  let env = initial_env()
  let expr = parse_one("`(1 ,(+ 2 3) 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(5)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil)))) => ()
    _ => fail("expected (1 5 4)")
  }
}

/// Splice a list with unquote-splicing.
test "quasiquote with unquote-splicing" {
  let env = initial_env()
  let env = define_var(env, "xs", Value::Pair(
    Value::Number(Number::Int(2)),
    Value::Pair(Value::Number(Number::Int(3)), Value::Nil)
  ))
  let expr = parse_one("`(1 ,@xs 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Pair(Value::Number(Number::Int(3)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil))))) => ()
    _ => fail("expected (1 2 3 4)")
  }
}

/// Splice an empty list with unquote-splicing.
test "quasiquote with unquote-splicing empty list" {
  let env = initial_env()
  let env = define_var(env, "xs", Value::Nil)
  let expr = parse_one("`(1 ,@xs 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil))) => ()
    _ => fail("expected (1 4)")
  }
}

/// quasiquote special form (parenthesis form).
test "quasiquote special form" {
  let env = initial_env()
  let expr = parse_one("(quasiquote (a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// ' quote in notation.
test "quote with apostrophe" {
  let env = initial_env()
  let expr = parse_one("'(a b c)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// Symbol quasiquote.
test "quasiquote symbol" {
  let env = initial_env()
  let expr = parse_one("`x")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("x")) => ()
    _ => fail("expected symbol x")
  }
}

/// quasiquote of numbers.
test "quasiquote number" {
  let env = initial_env()
  let expr = parse_one("`42")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// Error if unquote is used outside of quasiquote.
test "unquote outside quasiquote is error" {
  let env = initial_env()
  let expr = parse_one(",x")
  let result = eval(expr, env)
  match result {
    Err(EvalError::InvalidSyntax(_)) => ()
    _ => fail("expected InvalidSyntax error")
  }
}

/// Error if unquote-splicing is used outside of quasiquote.
test "unquote-splicing outside quasiquote is error" {
  let env = initial_env()
  let expr = parse_one(",@xs")
  let result = eval(expr, env)
  match result {
    Err(EvalError::InvalidSyntax(_)) => ()
    _ => fail("expected InvalidSyntax error")
  }
}

/// Multiple unquotes.
test "quasiquote with multiple unquotes" {
  let env = initial_env()
  let env = define_var(env, "x", Value::Number(Number::Int(1)))
  let env = define_var(env, "y", Value::Number(Number::Int(2)))
  let expr = parse_one("`(,x ,y)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(2)), Value::Nil))) => ()
    _ => fail("expected (1 2)")
  }
}

/// Nested quasiquotes (only the outer quasiquote is expanded).
test "nested quasiquote" {
  let env = initial_env()
  let env = define_var(env, "x", Value::Number(Number::Int(42)))
  let expr = parse_one("``(a ,x)")
  let result = eval(expr, env)
  // Nested quasiquote does not expand inner unquote
  match result {
    Ok(Value::Pair(Value::Symbol("quasiquote"), _)) => ()
    _ => fail("expected nested quasiquote structure")
  }
}
