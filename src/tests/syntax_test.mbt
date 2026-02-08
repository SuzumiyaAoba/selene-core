/// Testing the syntax-rules macro system

/// Basic macro expansion (let-syntax)
test "let-syntax basic" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((swap (syntax-rules () ((_ a b) (list b a))))) (swap 1 2))",
  )
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 2 1)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(syntax_value_to_string(result), syntax_value_to_string(expected))
    }
    Err(e) => fail("Expected list (2 1), got error: " + e.to_string())
  }
}

/// Constant expansion using macros
test "let-syntax constant" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((answer (syntax-rules () ((_) 42)))) (answer))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(42))) => ()
    _ => fail("Expected 42")
  }
}

/// Macros with multiple arguments
test "let-syntax multiple args" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((add3 (syntax-rules () ((_ a b c) (+ a (+ b c)))))) (add3 1 2 3))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(6))) => ()
    Err(e) => fail("Expected 6, got error: " + e.to_string())
    _ => fail("Expected 6")
  }
}

/// Macros with literal keywords
test "let-syntax with literals" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((my-if (syntax-rules (then else) ((_ test then t else e) (if test t e))))) (my-if #t then 1 else 2))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(1))) => ()
    Err(e) => fail("Expected 1, got error: " + e.to_string())
    _ => fail("Expected 1")
  }
}

/// Macros with multiple rules (pattern matching)
test "let-syntax multiple rules" {
  let env = initial_env()
  // Handles both 2 and 3 arguments
  let expr = parse_one(
    "(let-syntax ((add (syntax-rules () ((_ a b) (+ a b)) ((_ a b c) (+ a (+ b c)))))) (add 10 20))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(30))) => ()
    Err(e) => fail("Expected 30, got error: " + e.to_string())
    _ => fail("Expected 30")
  }
}

/// nested macro expansion
test "let-syntax nested" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((double (syntax-rules () ((_ x) (* x 2))))) (double (double 5)))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(20))) => ()
    Err(e) => fail("Expected 20, got error: " + e.to_string())
    _ => fail("Expected 20")
  }
}

/// Macros using the ellipsis pattern
test "let-syntax with ellipsis" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((my-list (syntax-rules () ((_ x ...) (list x ...))))) (my-list 1 2 3))",
  )
  match eval(expr, env) {
    Ok(result) => {
      let expected_expr = parse_one("(list 1 2 3)")
      let expected = match eval(expected_expr, env) {
        Ok(v) => v
        _ => fail("Failed to create expected list")
      }
      assert_eq(syntax_value_to_string(result), syntax_value_to_string(expected))
    }
    Err(e) => fail("Expected (1 2 3), got error: " + e.to_string())
  }
}

/// Empty list with ellipsis
test "let-syntax with ellipsis empty" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((my-list (syntax-rules () ((_ x ...) (list x ...))))) (my-list))",
  )
  match eval(expr, env) {
    Ok(Value::Nil) => ()
    Err(e) => fail("Expected empty list, got error: " + e.to_string())
    _ => fail("Expected empty list")
  }
}

/// Macro with wildcard (_)
test "let-syntax with wildcard" {
  let env = initial_env()
  let expr = parse_one(
    "(let-syntax ((first (syntax-rules () ((_ a _) a)))) (first 10 20))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(10))) => ()
    Err(e) => fail("Expected 10, got error: " + e.to_string())
    _ => fail("Expected 10")
  }
}

/// Recursive macros with letrec-syntax
test "letrec-syntax recursive" {
  let env = initial_env()
  // count macro: count the number of arguments
  let expr = parse_one(
    "(letrec-syntax ((count (syntax-rules () ((_) 0) ((_ x . rest) (+ 1 (count . rest)))))) (count a b c))",
  )
  match eval(expr, env) {
    Ok(Value::Number(Number::Int(3))) => ()
    Err(e) => fail("Expected 3, got error: " + e.to_string())
    _ => fail("Expected 3")
  }
}

/// For testing: convert Value to string
fn syntax_value_to_string(value : Value) -> String {
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
      result = result + syntax_value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + syntax_value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + syntax_value_to_string(current) + ")"
            return result
          }
        }
      } else {
        ()
      }
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
