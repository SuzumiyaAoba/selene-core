/// case 特殊形式と連想リスト/メンバーシップ関数のテスト。

// === case 特殊形式 ===

/// case は key を評価して datum とマッチさせる。
test "case basic match" {
  let env = initial_env()
  let expr = parse_one("(case 2 ((1) 'one) ((2) 'two) ((3) 'three))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("two")) => ()
    _ => fail("expected 'two")
  }
}

/// case で複数の datum を持つ節。
test "case multiple datums" {
  let env = initial_env()
  let expr = parse_one("(case 5 ((1 2 3) 'small) ((4 5 6) 'medium) ((7 8 9) 'large))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("medium")) => ()
    _ => fail("expected 'medium")
  }
}

/// case の else 節。
test "case else clause" {
  let env = initial_env()
  let expr = parse_one("(case 10 ((1) 'one) ((2) 'two) (else 'other))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("other")) => ()
    _ => fail("expected 'other")
  }
}

/// case でマッチしない場合は未定義値（nil）。
test "case no match no else" {
  let env = initial_env()
  let expr = parse_one("(case 10 ((1) 'one) ((2) 'two))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => fail("expected nil")
  }
}

/// case でシンボルをマッチ。
test "case match symbol" {
  let env = initial_env()
  let expr = parse_one("(case 'apple ((orange) 1) ((apple) 2) ((banana) 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(2))) => ()
    _ => fail("expected 2")
  }
}

/// case の key は式として評価される。
test "case evaluates key" {
  let env = initial_env()
  let expr = parse_one("(case (+ 1 1) ((1) 'one) ((2) 'two) ((3) 'three))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("two")) => ()
    _ => fail("expected 'two")
  }
}

/// case の body は複数の式を持てる。
test "case multiple body expressions" {
  let env = initial_env()
  let expr = parse_one("(case 1 ((1) (+ 1 2) (+ 3 4)) ((2) 0))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Number(Number::Int(7))) => ()
    _ => fail("expected 7")
  }
}

// === 連想リスト関数 ===

/// assq は eq? で検索する。
test "assq found" {
  let env = initial_env()
  // list でリストを構築（dotted pair ではなく通常のペアを使用）
  let expr = parse_one("(assq 'b (list (list 'a 1) (list 'b 2) (list 'c 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("b"), _)) => ()
    _ => fail("expected pair starting with 'b")
  }
}

/// assq で見つからない場合は #f。
test "assq not found" {
  let env = initial_env()
  let expr = parse_one("(assq 'd (list (list 'a 1) (list 'b 2) (list 'c 3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// assv は eqv? で検索する（数値も検索可能）。
test "assv with numbers" {
  let env = initial_env()
  let expr = parse_one("(assv 2 (list (list 1 'a) (list 2 'b) (list 3 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected pair starting with 2")
  }
}

/// assoc は equal? で検索する（リストも検索可能）。
test "assoc with lists" {
  let env = initial_env()
  let expr = parse_one("(assoc '(1 2) (list (list '(1) 'a) (list '(1 2) 'b) (list '(1 2 3) 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected pair")
  }
}

/// assoc で見つからない場合は #f。
test "assoc not found" {
  let env = initial_env()
  let expr = parse_one("(assoc '(1 2 3 4) (list (list '(1) 'a) (list '(1 2) 'b) (list '(1 2 3) 'c)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// === メンバーシップ関数 ===

/// memq は eq? で検索し、見つかった位置からのリストを返す。
test "memq found" {
  let env = initial_env()
  let expr = parse_one("(memq 'b '(a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Symbol("b"), Value::Pair(Value::Symbol("c"), Value::Nil))) => ()
    _ => fail("expected (b c)")
  }
}

/// memq で見つからない場合は #f。
test "memq not found" {
  let env = initial_env()
  let expr = parse_one("(memq 'd '(a b c))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

/// memv は eqv? で検索する（数値も検索可能）。
test "memv with numbers" {
  let env = initial_env()
  let expr = parse_one("(memv 2 '(1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(Value::Number(Number::Int(2)), _)) => ()
    _ => fail("expected list starting with 2")
  }
}

/// member は equal? で検索する（リストも検索可能）。
test "member with lists" {
  let env = initial_env()
  let expr = parse_one("(member '(2) '((1) (2) (3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Pair(_, _)) => ()
    _ => fail("expected list")
  }
}

/// member で見つからない場合は #f。
test "member not found" {
  let env = initial_env()
  let expr = parse_one("(member '(4) '((1) (2) (3)))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Bool(false)) => ()
    _ => fail("expected #f")
  }
}

// === シンボル変換関数 ===

/// symbol->string はシンボルを文字列に変換する。
test "symbol->string" {
  let env = initial_env()
  let expr = parse_one("(symbol->string 'hello)")
  let result = eval(expr, env)
  match result {
    Ok(Value::String("hello")) => ()
    _ => fail("expected \"hello\"")
  }
}

/// string->symbol は文字列をシンボルに変換する。
test "string->symbol" {
  let env = initial_env()
  let expr = parse_one("(string->symbol \"world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("world")) => ()
    _ => fail("expected 'world")
  }
}

/// 変換の往復。
test "symbol string round trip" {
  let env = initial_env()
  let expr = parse_one("(string->symbol (symbol->string 'foo))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Symbol("foo")) => ()
    _ => fail("expected 'foo")
  }
}

/// symbol->string に非シンボルを渡すとエラー。
test "symbol->string with non-symbol" {
  let env = initial_env()
  let expr = parse_one("(symbol->string 42)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}

/// string->symbol に非文字列を渡すとエラー。
test "string->symbol with non-string" {
  let env = initial_env()
  let expr = parse_one("(string->symbol 'foo)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::TypeError(_)) => ()
    _ => fail("expected TypeError")
  }
}
