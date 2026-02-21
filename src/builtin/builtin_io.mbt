/// I/O built-in functions
///
/// Implement the input/output operation of Scheme.

/// Converts a value to a display string (used in display)
fn value_to_display_string(value : Value) -> String {
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
    Value::Char(c) => c.to_string()
    Value::String(s) => s // display outputs the string without quotes
    Value::Symbol(s) => s
    Value::Pair(car, cdr, _) => {
      let mut result = "("
      result = result + value_to_display_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + value_to_display_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_display_string(current) + ")"
            return result
          }
        }
      } else {
        ()
      }
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
        result = result + value_to_display_string(items[i])
        i = i + 1
      } else {
        ()
      }
      result + ")"
    }
    Value::Procedure(Procedure::Native(name)) => "#<procedure:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<procedure:closure>"
    Value::Procedure(Procedure::Cont(cont)) =>
      "#<continuation:" + cont.id.to_string() + ">"
    Value::Procedure(Procedure::VMClosure(_)) => "#<procedure:vm-closure>"
    Value::Procedure(Procedure::VMCont(cont)) =>
      "#<continuation:vm:" + cont.id.to_string() + ">"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(values) => {
      let mut result = "#<values:"
      let len = values.length()
      let mut i = 0
      while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + value_to_display_string(values[i])
        i = i + 1
      }
      result + ">"
    }
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

/// Converts a value to a string for writing (used in write)
fn value_to_write_string(value : Value) -> String {
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
    Value::String(s) => "\"" + s + "\"" // write outputs a string with quotes
    Value::Symbol(s) => s
    Value::Pair(car, cdr, _) => {
      let mut result = "("
      result = result + value_to_write_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2, _) => {
            result = result + " " + value_to_write_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_write_string(current) + ")"
            return result
          }
        }
      } else {
        ()
      }
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
        result = result + value_to_write_string(items[i])
        i = i + 1
      } else {
        ()
      }
      result + ")"
    }
    Value::Procedure(Procedure::Native(name)) => "#<procedure:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<procedure:closure>"
    Value::Procedure(Procedure::Cont(cont)) =>
      "#<continuation:" + cont.id.to_string() + ">"
    Value::Procedure(Procedure::VMClosure(_)) => "#<procedure:vm-closure>"
    Value::Procedure(Procedure::VMCont(cont)) =>
      "#<continuation:vm:" + cont.id.to_string() + ">"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(values) => {
      let mut result = "#<values:"
      let len = values.length()
      let mut i = 0
      while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + value_to_write_string(values[i])
        i = i + 1
      }
      result + ">"
    }
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

/// Built-in functions: display
/// (display obj [port]) - outputs obj in a human-readable format (strings are unquoted)
/// Note: Only println is available on MoonBit, so it will be output with line breaks
pub fn builtin_display(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("display: requires 1 or 2 arguments"))
  }
  let output = value_to_display_string(args[0])

  if args.length() == 1 {
    // Write to stdout
    println(output)
    return Ok(Value::Nil)
  }

  // Write to port
  match args[1] {
    Value::Port(port) => {
      if port.direction != PortDirection::Output {
        return Err(EvalError::TypeError("display: not an output port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("display: port is closed"))
      }
      // Write each character to the port
      let len = output.length()
      let mut i = 0
      while i < len {
        let char_code = output[i].to_int()
        let success = write_char_to_port(port.id, char_code)
        if not(success) {
          return Err(EvalError::TypeError("display: write failed"))
        }
        i = i + 1
      }
      Ok(Value::Nil)
    }
    _ => Err(EvalError::TypeError("display: expected port as second argument"))
  }
}

/// Built-in function: newline
/// (newline [port]) - Output line breaks
pub fn builtin_newline(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() > 1 {
    return Err(EvalError::ArityError("newline: requires 0 or 1 argument"))
  }

  if args.length() == 0 {
    // Write to stdout
    println("")
    return Ok(Value::Nil)
  }

  // Write to port
  match args[0] {
    Value::Port(port) => {
      if port.direction != PortDirection::Output {
        return Err(EvalError::TypeError("newline: not an output port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("newline: port is closed"))
      }
      let success = write_char_to_port(port.id, '\n'.to_int())
      if success {
        Ok(Value::Nil)
      } else {
        Err(EvalError::TypeError("newline: write failed"))
      }
    }
    _ => Err(EvalError::TypeError("newline: expected port"))
  }
}

/// Built-in function: write
/// (write obj [port]) - outputs obj in a machine-readable format (strings are quoted)
/// Note: Only println is available on MoonBit, so it will be output with line breaks
pub fn builtin_write(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("write: requires 1 or 2 arguments"))
  }
  let output = value_to_write_string(args[0])

  if args.length() == 1 {
    // Write to stdout
    println(output)
    return Ok(Value::Nil)
  }

  // Write to port
  match args[1] {
    Value::Port(port) => {
      if port.direction != PortDirection::Output {
        return Err(EvalError::TypeError("write: not an output port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("write: port is closed"))
      }
      // Write each character to the port
      let len = output.length()
      let mut i = 0
      while i < len {
        let char_code = output[i].to_int()
        let success = write_char_to_port(port.id, char_code)
        if not(success) {
          return Err(EvalError::TypeError("write: write failed"))
        }
        i = i + 1
      }
      Ok(Value::Nil)
    }
    _ => Err(EvalError::TypeError("write: expected port as second argument"))
  }
}

/// Built-in function: read
/// (read) - reads back one S equation from standard input
/// Note: This version is for JS backend only
pub fn builtin_read(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 0 {
    return Err(EvalError::ArityError("read: requires exactly 0 arguments"))
  }
  // Read one line from standard input via JS FFI
  let line = read_line()
  // Parse and Convert to S-Formula
  let sexpr = parse_one(line)
  // Convert S-expression to Value (return as data without evaluation)
  Ok(sexpr_to_value(sexpr))
}
