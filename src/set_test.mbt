/// set! 特殊形式のテスト。

/// set_bang関数の基本テスト。
test "set_bang basic" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // xの値を20に更新
  let (new_env, ok) = set_bang(env, "x", Value::Number(Number::Int(20)))

  // 成功することを確認
  if not(ok) {
    fail("set_bang should succeed")
  }

  // 新しい値が設定されていることを確認
  match lookup(new_env, "x") {
    Some(Value::Number(Number::Int(20))) => ()
    _ => fail("expected x to be 20")
  }
}

/// 未束縛変数に対するset_bangのテスト。
test "set_bang unbound variable" {
  let env = empty_env()

  // 未束縛変数に対するset_bang
  let (_new_env, ok) = set_bang(env, "y", Value::Number(Number::Int(30)))

  // 失敗することを確認
  if ok {
    fail("set_bang should fail for unbound variable")
  }
}

/// ネストした環境でのset_bangのテスト。
test "set_bang nested environment" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // 新しいフレームを追加
  let env2 = extend(env, [("y", Value::Number(Number::Int(20)))])

  // 親環境の変数xを更新
  let (new_env, ok) = set_bang(env2, "x", Value::Number(Number::Int(100)))

  // 成功することを確認
  if not(ok) {
    fail("set_bang should succeed for parent frame variable")
  }

  // xが更新されていることを確認
  match lookup(new_env, "x") {
    Some(Value::Number(Number::Int(100))) => ()
    _ => fail("expected x to be 100")
  }

  // yは変わっていないことを確認
  match lookup(new_env, "y") {
    Some(Value::Number(Number::Int(20))) => ()
    _ => fail("expected y to be 20")
  }
}

/// set_bangで複数回更新するテスト。
test "set_bang multiple updates" {
  let env = empty_env()
  let env = define_var(env, "counter", Value::Number(Number::Int(0)))

  // 1に更新
  let (env, ok1) = set_bang(env, "counter", Value::Number(Number::Int(1)))
  if not(ok1) {
    fail("first update should succeed")
  }

  // 2に更新
  let (env, ok2) = set_bang(env, "counter", Value::Number(Number::Int(2)))
  if not(ok2) {
    fail("second update should succeed")
  }

  // 3に更新
  let (env, ok3) = set_bang(env, "counter", Value::Number(Number::Int(3)))
  if not(ok3) {
    fail("third update should succeed")
  }

  // 最終的な値が3であることを確認
  match lookup(env, "counter") {
    Some(Value::Number(Number::Int(3))) => ()
    _ => fail("expected counter to be 3")
  }
}

/// 異なる型の値への更新をテスト。
test "set_bang different types" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // 数値から真偽値に更新
  let (env, ok1) = set_bang(env, "x", Value::Bool(true))
  if not(ok1) {
    fail("update to boolean should succeed")
  }

  match lookup(env, "x") {
    Some(Value::Bool(true)) => ()
    _ => fail("expected x to be #t")
  }

  // 真偽値からシンボルに更新
  let (env, ok2) = set_bang(env, "x", Value::Symbol("test"))
  if not(ok2) {
    fail("update to symbol should succeed")
  }

  match lookup(env, "x") {
    Some(Value::Symbol("test")) => ()
    _ => fail("expected x to be 'test")
  }
}

/// set!がREPLコンテキストでエラーを返すことを確認。
test "set! in expression context" {
  let env = initial_env()
  let expr = SExpr::Pair(
    SExpr::Symbol("set!"),
    SExpr::Pair(
      SExpr::Symbol("x"),
      SExpr::Pair(SExpr::Number(10), SExpr::Nil)
    )
  )

  match eval(expr, env) {
    Err(EvalError::InvalidSyntax(_)) => ()
    _ => fail("set! should return error in expression context")
  }
}
