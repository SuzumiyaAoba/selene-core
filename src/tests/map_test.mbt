/// Testing map and for-each functions

/// Basic operation of map
test "map basic" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x) (* x 2)) (list 1 2 3))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 4 6)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// Use built-in functions with map
test "map with builtin function" {
  let env = initial_env()
  // Negative number literals are not supported, so use (- 0 N)
  let expr = parse_one("(map abs (list (- 0 1) 2 (- 0 3) 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3 4)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    Err(e) => {
      let msg = "Expected a list, got error: " + e.to_string()
      fail(msg)
    }
  }
}

/// Multiple lists with map
test "map with multiple lists" {
  let env = initial_env()
  let expr = parse_one("(map + (list 1 2 3) (list 10 20 30))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 11 22 33)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// 3 lists with map
test "map with three lists" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x y z) (+ x (+ y z))) (list 1 2) (list 10 20) (list 100 200))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 111 222)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// empty list with map
test "map with empty list" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x) (* x 2)) ())")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Lambda expression in map
test "map with lambda" {
  let env = initial_env()
  // Negative number literals are not supported, so use (- 0 N)
  let expr = parse_one("(map (lambda (x) (if (< x 0) 0 x)) (list (- 0 1) 2 (- 0 3) 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 0 2 0 4)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    Err(e) => {
      let msg = "Expected a list, got error: " + e.to_string()
      fail(msg)
    }
  }
}

/// Basic behavior of for-each (you can't test for side effects, but make sure there are no errors)
test "for-each basic" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x) (* x 2)) (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Multiple lists with for-each
test "for-each with multiple lists" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x y) (+ x y)) (list 1 2 3) (list 10 20 30))")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Empty list with for-each
test "for-each with empty list" {
  let env = initial_env()
  let expr = parse_one("(for-each (lambda (x) (* x 2)) ())")
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    _ => fail("Expected Nil")
  }
}

/// Nested list operations with map
test "map nested" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (lst) (car lst)) (list (list 1 2) (list 3 4) (list 5 6)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 3 5)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// map and variables
test "map with variable" {
  let env = initial_env()
  let expr = parse_one("(let ((double (lambda (x) (* x 2)))) (map double (list 1 2 3)))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 4 6)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// Compute list sum with map
test "map for calculation" {
  let env = initial_env()
  let expr = parse_one("(map (lambda (x y) (* x y)) (list 1 2 3) (list 2 3 4))")
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 6 12)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(map_value_to_string(result), map_value_to_string(expected))
    }
    _ => fail("Expected a list")
  }
}

/// Helper function: Convert Value to string (for map_test)
fn map_value_to_string(value : Value) -> String {
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
      result = result + map_value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + map_value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + map_value_to_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(_) => "#(...)"
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
