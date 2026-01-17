/// I/O関数のテスト

test "display - displays string without quotes" {
  let env = initial_env()
  let expr = parse_one("(display \"hello world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil")
  }
}

test "display - displays number" {
  let env = initial_env()
  let expr = parse_one("(display 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil")
  }
}

test "display - displays boolean" {
  let env = initial_env()
  let expr = parse_one("(display #t)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil")
  }
}

test "display - displays list" {
  let env = initial_env()
  let expr = parse_one("(display (list 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil")
  }
}

test "display - requires exactly 1 argument" {
  let env = initial_env()
  let expr = parse_one("(display)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => @test.fail!("display should fail with arity error when given no arguments")
  }
}

test "display - fails with too many arguments" {
  let env = initial_env()
  let expr = parse_one("(display 1 2)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => @test.fail!("display should fail with arity error when given too many arguments")
  }
}

test "newline - outputs newline" {
  let env = initial_env()
  let expr = parse_one("(newline)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("newline should return Nil")
  }
}

test "newline - requires exactly 0 arguments" {
  let env = initial_env()
  let expr = parse_one("(newline 1)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => @test.fail!("newline should fail with arity error when given arguments")
  }
}

test "write - writes string with quotes" {
  let env = initial_env()
  let expr = parse_one("(write \"hello world\")")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil")
  }
}

test "write - writes number" {
  let env = initial_env()
  let expr = parse_one("(write 42)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil")
  }
}

test "write - writes boolean" {
  let env = initial_env()
  let expr = parse_one("(write #f)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil")
  }
}

test "write - writes list" {
  let env = initial_env()
  let expr = parse_one("(write (list 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil")
  }
}

test "write - requires exactly 1 argument" {
  let env = initial_env()
  let expr = parse_one("(write)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => @test.fail!("write should fail with arity error when given no arguments")
  }
}

test "write - fails with too many arguments" {
  let env = initial_env()
  let expr = parse_one("(write 1 2)")
  let result = eval(expr, env)
  match result {
    Err(EvalError::ArityError(_)) => ()
    _ => @test.fail!("write should fail with arity error when given too many arguments")
  }
}

test "display and write - difference in string output" {
  let env = initial_env()
  // Both should succeed, but display outputs without quotes, write outputs with quotes
  let display_expr = parse_one("(display \"test\")")
  let write_expr = parse_one("(write \"test\")")

  match eval(display_expr, env) {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should succeed")
  }

  match eval(write_expr, env) {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should succeed")
  }
}

test "display - with character" {
  let env = initial_env()
  let expr = parse_one("(display #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil for character")
  }
}

test "write - with character" {
  let env = initial_env()
  let expr = parse_one("(write #\\a)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil for character")
  }
}

test "display - with vector" {
  let env = initial_env()
  let expr = parse_one("(display (vector 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil for vector")
  }
}

test "write - with vector" {
  let env = initial_env()
  let expr = parse_one("(write (vector 1 2 3))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil for vector")
  }
}

test "display - with procedure" {
  let env = initial_env()
  let expr = parse_one("(display +)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil for procedure")
  }
}

test "write - with procedure" {
  let env = initial_env()
  let expr = parse_one("(write +)")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil for procedure")
  }
}

test "display - with nil" {
  let env = initial_env()
  let expr = parse_one("(display ())")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("display should return Nil for nil")
  }
}

test "write - with nil" {
  let env = initial_env()
  let expr = parse_one("(write ())")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("write should return Nil for nil")
  }
}

test "newline - multiple calls" {
  let env = initial_env()
  let expr1 = parse_one("(newline)")
  let expr2 = parse_one("(newline)")

  match eval(expr1, env) {
    Ok(Value::Nil) => ()
    _ => @test.fail!("first newline should succeed")
  }

  match eval(expr2, env) {
    Ok(Value::Nil) => ()
    _ => @test.fail!("second newline should succeed")
  }
}

test "display and newline - sequence" {
  let env = initial_env()
  let expr = parse_one("(begin (display \"hello\") (newline) (display \"world\"))")
  let result = eval(expr, env)
  match result {
    Ok(Value::Nil) => ()
    _ => @test.fail!("sequence should succeed")
  }
}
