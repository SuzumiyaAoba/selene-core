/// set! Special form of test.

/// Basic test of set_bang function.
test "set_bang basic" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // Update the value of x to 20
  let (new_env, ok) = set_bang(env, "x", Value::Number(Number::Int(20)))

  // Confirm success
  if not(ok) {
    fail("set_bang should succeed")
  }

  // Verify that the new value is set
  match lookup(new_env, "x") {
    Some(Value::Number(Number::Int(20))) => ()
    _ => fail("expected x to be 20")
  }
}

/// Testing set_bang on unbound variables.
test "set_bang unbound variable" {
  let env = empty_env()

  // set_bang on unbound variables
  let (_new_env, ok) = set_bang(env, "y", Value::Number(Number::Int(30)))

  // make sure it fails
  if ok {
    fail("set_bang should fail for unbound variable")
  }
}

/// Testing set_bang in a nested environment.
test "set_bang nested environment" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // add new frame
  let env2 = extend(env, [("y", Value::Number(Number::Int(20)))])

  // Update variable x in parent environment
  let (new_env, ok) = set_bang(env2, "x", Value::Number(Number::Int(100)))

  // Confirm success
  if not(ok) {
    fail("set_bang should succeed for parent frame variable")
  }

  // Make sure x is updated
  match lookup(new_env, "x") {
    Some(Value::Number(Number::Int(100))) => ()
    _ => fail("expected x to be 100")
  }

  // Confirm that y has not changed
  match lookup(new_env, "y") {
    Some(Value::Number(Number::Int(20))) => ()
    _ => fail("expected y to be 20")
  }
}

/// A test that updates multiple times with set_bang.
test "set_bang multiple updates" {
  let env = empty_env()
  let env = define_var(env, "counter", Value::Number(Number::Int(0)))

  // updated to 1
  let (env, ok1) = set_bang(env, "counter", Value::Number(Number::Int(1)))
  if not(ok1) {
    fail("first update should succeed")
  }

  // updated to 2
  let (env, ok2) = set_bang(env, "counter", Value::Number(Number::Int(2)))
  if not(ok2) {
    fail("second update should succeed")
  }

  // updated to 3
  let (env, ok3) = set_bang(env, "counter", Value::Number(Number::Int(3)))
  if not(ok3) {
    fail("third update should succeed")
  }

  // Check that the final value is 3
  match lookup(env, "counter") {
    Some(Value::Number(Number::Int(3))) => ()
    _ => fail("expected counter to be 3")
  }
}

/// Test updates to values ​​of different types.
test "set_bang different types" {
  let env = empty_env()
  let env = define_var(env, "x", Value::Number(Number::Int(10)))

  // Update from numeric value to boolean value
  let (env, ok1) = set_bang(env, "x", Value::Bool(true))
  if not(ok1) {
    fail("update to boolean should succeed")
  }

  match lookup(env, "x") {
    Some(Value::Bool(true)) => ()
    _ => fail("expected x to be #t")
  }

  // Update from boolean to symbol
  let (env, ok2) = set_bang(env, "x", Value::Symbol("test"))
  if not(ok2) {
    fail("update to symbol should succeed")
  }

  match lookup(env, "x") {
    Some(Value::Symbol("test")) => ()
    _ => fail("expected x to be 'test")
  }
}

/// Confirmed that set! returns an error in REPL context.
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
