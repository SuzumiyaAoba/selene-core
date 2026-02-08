/// test apply function

/// basic behavior of apply (list only)
test "apply basic - list only" {
  let env = initial_env()
  let expr = parse_one("(apply + (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}

/// combine list with intermediate arguments in apply
test "apply with intermediate arguments" {
  let env = initial_env()
  let expr = parse_one("(apply + 1 2 (list 3 4 5))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 15)
    _ => fail("Expected Int(15)")
  }
}

/// apply and list functions
test "apply with list" {
  let env = initial_env()
  let expr = parse_one("(apply list (list 1 2 3))")
  match eval(expr, env) {
    Ok(Value::Pair(_, _, _)) => {
      // Verify that the list has been created
      let list_expr = parse_one("(list 1 2 3)")
      let expected = match eval(list_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      // Compare values as strings (easy way)
      let result_str = value_to_string(eval(expr, env).unwrap())
      let expected_str = value_to_string(expected)
      assert_eq(result_str, expected_str)
    }
    _ => fail("Expected a list")
  }
}

/// apply and max functions
test "apply with max" {
  let env = initial_env()
  let expr = parse_one("(apply max (list 1 5 3 2))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 5)
    _ => fail("Expected Int(5)")
  }
}

/// apply and cons functions
test "apply with cons" {
  let env = initial_env()
  let expr = parse_one("(apply cons (list 1 2))")
  match eval(expr, env) {
    Ok(Value::Pair(Value::Number(Number::Int(1)), Value::Number(Number::Int(2)), _)) => ()
    _ => fail("Expected Pair(1, 2)")
  }
}

/// apply and Lambda Expression
test "apply with lambda" {
  let env = initial_env()
  let expr = parse_one("(apply (lambda (x y) (+ x y)) (list 3 4))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 7)
    _ => fail("Expected Int(7)")
  }
}

/// apply and lambda expressions (with intermediate arguments)
test "apply with lambda and intermediate args" {
  let env = initial_env()
  let expr = parse_one("(apply (lambda (x y z) (* x (+ y z))) 2 (list 3 4))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 14)
    _ => fail("Expected Int(14)")
  }
}

/// empty list with apply
test "apply with empty list" {
  let env = initial_env()
  let expr = parse_one("(apply + ())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 0)
    _ => fail("Expected Int(0)")
  }
}

/// intermediate arguments and empty list in apply
test "apply with intermediate args and empty list" {
  let env = initial_env()
  let expr = parse_one("(apply + 1 2 ())")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 3)
    _ => fail("Expected Int(3)")
  }
}

/// single intermediate argument in apply
test "apply with single intermediate arg" {
  let env = initial_env()
  let expr = parse_one("(apply + 10 (list 20 30))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 60)
    _ => fail("Expected Int(60)")
  }
}

/// list nested with apply
test "apply with nested expression" {
  let env = initial_env()
  let expr = parse_one("(apply + (cons 1 (cons 2 (cons 3 ()))))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 6)
    _ => fail("Expected Int(6)")
  }
}

/// apply and variables
test "apply with variable" {
  let env = initial_env()
  let expr = parse_one("(let ((nums (list 1 2 3 4))) (apply + nums))")
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(n))) => assert_eq(n, 10)
    _ => fail("Expected Int(10)")
  }
}

/// Value_to_string helper function for repl (for testing)
fn value_to_string(value : Value) -> String {
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
      result = result + value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_string(current) + ")"
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
