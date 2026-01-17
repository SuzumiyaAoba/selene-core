/// quasiquote 展開のテスト。

/// 単純な quasiquote（unquote なし）はリテラルを返す。
test "quasiquote without unquote" {
  let env = initial_env()
  let expr = parse_one("`(a b c)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// unquote で変数を展開する。
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

/// unquote で式を評価する。
test "quasiquote with unquote expression" {
  let env = initial_env()
  let expr = parse_one("`(1 ,(+ 2 3) 4)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Pair(Value::Number(Number::Int(5)), Value::Pair(Value::Number(Number::Int(4)), Value::Nil)))) => ()
    _ => fail("expected (1 5 4)")
  }
}

/// unquote-splicing でリストをスプライスする。
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

/// unquote-splicing で空リストをスプライスする。
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

/// quasiquote 特殊形式（括弧形式）。
test "quasiquote special form" {
  let env = initial_env()
  let expr = parse_one("(quasiquote (a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// ' 記法で quote。
test "quote with apostrophe" {
  let env = initial_env()
  let expr = parse_one("'(a b c)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("a"), Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil)))) => ()
    _ => fail("expected (a b c)")
  }
}

/// シンボルの quasiquote。
test "quasiquote symbol" {
  let env = initial_env()
  let expr = parse_one("`x")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("x")) => ()
    _ => fail("expected symbol x")
  }
}

/// 数値の quasiquote。
test "quasiquote number" {
  let env = initial_env()
  let expr = parse_one("`42")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("expected 42")
  }
}

/// unquote が quasiquote 外で使用された場合はエラー。
test "unquote outside quasiquote is error" {
  let env = initial_env()
  let expr = parse_one(",x")
  let result = eval(expr, env)
  match result {
    Err(EvalError::InvalidSyntax(_)) => ()
    _ => fail("expected InvalidSyntax error")
  }
}

/// unquote-splicing が quasiquote 外で使用された場合はエラー。
test "unquote-splicing outside quasiquote is error" {
  let env = initial_env()
  let expr = parse_one(",@xs")
  let result = eval(expr, env)
  match result {
    Err(EvalError::InvalidSyntax(_)) => ()
    _ => fail("expected InvalidSyntax error")
  }
}

/// 複数の unquote。
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

/// ネストした quasiquote（外側の quasiquote のみ展開）。
test "nested quasiquote" {
  let env = initial_env()
  let env = define_var(env, "x", Value::Number(Number::Int(42)))
  let expr = parse_one("``(a ,x)")
  let result = eval(expr, env)
  // ネストした quasiquote は内側の unquote を展開しない
  match result {
    Ok(Value::Pair(Value::Symbol("quasiquote"), _)) => ()
    _ => fail("expected nested quasiquote structure")
  }
}
