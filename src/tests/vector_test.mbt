/// Testing vector manipulation functions

/// Basic operation of vector?
test "vector? basic" {
  let env = initial_env()
  let expr = parse_one("(vector? (vector 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Bool(true)) => ()
    _ => fail("Expected Bool(true)")
  }
}

/// Determine non-vector with vector?
test "vector? with non-vector" {
  let env = initial_env()
  let expr = parse_one("(vector? (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Bool(false)) => ()
    _ => fail("Expected Bool(false)")
  }
}

/// Basic operation of make-vector
test "make-vector basic" {
  let env = initial_env()
  let expr = parse_one("(make-vector 5 0)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 5)
      for item in items {
        match item {
          Value::Number(Number::Int(0)) => ()
          _ => fail("Expected Int(0)")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// Default value (Nil) in make-vector
test "make-vector default value" {
  let env = initial_env()
  let expr = parse_one("(make-vector 3)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      for item in items {
        match item {
          Value::Nil => ()
          _ => fail("Expected Nil")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// empty vector with make-vector
test "make-vector zero length" {
  let env = initial_env()
  let expr = parse_one("(make-vector 0)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// Basic operation of vector
test "vector basic" {
  let env = initial_env()
  let expr = parse_one("(vector 1 2 3)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1) at index 0")
      }
      match items[1] {
        Value::Number(Number::Int(2)) => ()
        _ => fail("Expected Int(2) at index 1")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3) at index 2")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// vector with no arguments (empty vector)
test "vector empty" {
  let env = initial_env()
  let expr = parse_one("(vector)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// Basic operation of vector-length
test "vector-length basic" {
  let env = initial_env()
  let expr = parse_one("(vector-length (vector 1 2 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(5))) => ()
    _ => fail("Expected Int(5)")
  }
}

/// empty vector with vector-length
test "vector-length empty" {
  let env = initial_env()
  let expr = parse_one("(vector-length (vector))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(0))) => ()
    _ => fail("Expected Int(0)")
  }
}

/// Basic operation of vector-ref
test "vector-ref basic" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 0)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(10))) => ()
    _ => fail("Expected Int(10)")
  }
}

/// intermediate index with vector-ref
test "vector-ref middle" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 1)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(20))) => ()
    _ => fail("Expected Int(20)")
  }
}

/// Last index in vector-ref
test "vector-ref last" {
  let env = initial_env()
  let expr = parse_one("(vector-ref (vector 10 20 30) 2)")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(30))) => ()
    _ => fail("Expected Int(30)")
  }
}

/// Basic operation of vector-set!
/// R5RS: vector-set! mutates in place and returns unspecified
test "vector-set! basic" {
  let env = initial_env()
  // vector-set! mutates the vector in place and returns unspecified (Nil)
  let expr = parse_one("(let ((v (vector 1 2 3))) (vector-set! v 1 99) v)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1) at index 0")
      }
      match items[1] {
        Value::Number(Number::Int(99)) => ()
        _ => fail("Expected Int(99) at index 1")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3) at index 2")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// Basic behavior of vector->list
test "vector->list basic" {
  let env = initial_env()
  let expr = parse_one("(vector->list (vector 1 2 3))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(vector_test_value_to_string(result), vector_test_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// empty vector with vector->list
test "vector->list empty" {
  let env = initial_env()
  let expr = parse_one("(vector->list (vector))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Basic operation of list->vector
test "list->vector basic" {
  let env = initial_env()
  let expr = parse_one("(list->vector (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1)")
      }
      match items[1] {
        Value::Number(Number::Int(2)) => ()
        _ => fail("Expected Int(2)")
      }
      match items[2] {
        Value::Number(Number::Int(3)) => ()
        _ => fail("Expected Int(3)")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// Empty list with list->vector
test "list->vector empty" {
  let env = initial_env()
  let expr = parse_one("(list->vector ())")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    _ => fail("Expected empty Vector")
  }
}

/// Interconversion between vector and list
test "vector list round-trip" {
  let env = initial_env()
  let expr = parse_one("(vector->list (list->vector (list 1 2 3)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(vector_test_value_to_string(result), vector_test_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// Mutual conversion between list and vector
test "list vector round-trip" {
  let env = initial_env()
  let expr = parse_one("(list->vector (vector->list (vector 1 2 3)))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[0] {
        Value::Number(Number::Int(1)) => ()
        _ => fail("Expected Int(1)")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// complex vector elements
test "vector with complex elements" {
  let env = initial_env()
  let expr = parse_one("(vector (list 1 2) (list 3 4) (list 5 6))")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      for item in items {
        match item {
          Value::Pair(_, _, _) => ()
          _ => fail("Expected Pair")
        }
      }
    }
    _ => fail("Expected Vector")
  }
}

/// Combination of make-vector and vector-set!
/// R5RS: vector-set! mutates in place and returns unspecified
test "make-vector with vector-set!" {
  let env = initial_env()
  let expr = parse_one("(let ((v (make-vector 3 0))) (vector-set! v 1 99) v)")
  match eval(expr, env) {
    Ok(Value::Vector(items)) => {
      assert_eq(items.length(), 3)
      match items[1] {
        Value::Number(Number::Int(99)) => ()
        _ => fail("Expected Int(99) at index 1")
      }
    }
    _ => fail("Expected Vector")
  }
}

/// Helper function: Convert Value to string (for vector_test)
fn vector_test_value_to_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Rational(num, den)) => num.to_string() + "/" + den.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Number(Number::Complex(r, i)) =>
      if i >= 0.0 {
        r.to_string() + "+" + i.to_string() + "i"
      } else {
        r.to_string() + i.to_string() + "i"
      }
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""
    Value::Symbol(s) => s
    Value::Pair(car, cdr, _) => {
      let mut result = "("
      result = result + vector_test_value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + vector_test_value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + vector_test_value_to_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(items) => {
      let mut result = "#("
      let len = items.length()
      let mut i = 0
      let _ = while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + vector_test_value_to_string(items[i])
        i = i + 1
      } else { () }
      result + ")"
    }
    Value::Procedure(_) => "#<procedure>"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(_) => "#<values>"
    Value::Syntax(_) => "#<syntax-rules>"
    Value::Port(port) =>
      if port.direction == PortDirection::Input {
        "#<input-port:" + port.name + ">"
      } else {
        "#<output-port:" + port.name + ">"
      }
    Value::Box(_) => "#<box>"
  }
}

// ============================================================
// Extended vector tests (VM-based)
// ============================================================

/// Helper: assert expression evaluates to #t
fn vec_assert_true(ctx : VMReplContext, code : String) -> Unit raise Error {
  match repl_eval(ctx, code) {
    Ok(Value::Bool(true)) => ()
    Ok(v) => fail("expected #t, got " + v.to_string() + " for: " + code)
    Err(e) => fail("error: " + e + " for: " + code)
  }
}

test "vector->list vm basic" {
  let ctx = new_repl_context()
  vec_assert_true(ctx, "(equal? (vector->list (vector 1 2 3)) '(1 2 3))")
}

test "vector->list vm empty" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(vector->list (vector))") {
    Ok(Value::Nil) => ()
    Ok(v) => fail("expected (), got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "list->vector vm basic" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(list->vector '(1 2 3))") {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 3)
    Ok(v) => fail("expected vector, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "list->vector vm empty" {
  let ctx = new_repl_context()
  match repl_eval(ctx, "(list->vector '())") {
    Ok(Value::Vector(items)) => assert_eq(items.length(), 0)
    Ok(v) => fail("expected empty vector, got " + v.to_string())
    Err(e) => fail("error: " + e)
  }
}

test "vector->list->vector vm roundtrip" {
  let ctx = new_repl_context()
  vec_assert_true(ctx, "(equal? (list->vector (vector->list (vector 1 2 3))) (vector 1 2 3))")
}

test "vector-fill! vm" {
  let ctx = new_repl_context()
  let _ = repl_eval(ctx, "(define v (make-vector 3 0))")
  let _ = repl_eval(ctx, "(vector-fill! v 7)")
  vec_assert_true(ctx, "(equal? (vector->list v) '(7 7 7))")
}
