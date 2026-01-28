/// Character manipulation built-in functions
///
/// Implement Scheme character manipulation.

/// Built-in function: char?
/// (char? obj) - Determine if obj is a character
fn builtin_char_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// Built-in function: char =?
/// (char =? char1 char2) - Determine if the characters are equal
fn builtin_char_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a == b))
    _ => Err(EvalError::TypeError("char=?: arguments must be characters"))
  }
}

/// Built-in function: char <?
/// (char <? char1 char2) - Determine if char1 is less than char2
fn builtin_char_lt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() < b.to_int()))
    _ => Err(EvalError::TypeError("char<?: arguments must be characters"))
  }
}

/// Built-in function: char >?
/// (char >? char1 char2) - Determine if char1 is greater than char2
fn builtin_char_gt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() > b.to_int()))
    _ => Err(EvalError::TypeError("char>?: arguments must be characters"))
  }
}

/// Built-in function: char < =?
/// (char < =? char1 char2) - Determine if char1 is less than or equal to char2
fn builtin_char_le(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() <= b.to_int()))
    _ => Err(EvalError::TypeError("char<=?: arguments must be characters"))
  }
}

/// Built-in function: char > =?
/// (char > =? char1 char2) - Determine if char1 is char2 or higher
fn builtin_char_ge(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() >= b.to_int()))
    _ => Err(EvalError::TypeError("char>=?: arguments must be characters"))
  }
}

/// Built-in function: char-alphabetic?
/// (char-alphabetic? char) - Determines if a character is an alphabet
fn builtin_char_alphabetic_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-alphabetic?: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_alpha = (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
      Ok(Value::Bool(is_alpha))
    }
    _ =>
      Err(
        EvalError::TypeError("char-alphabetic?: argument must be a character"),
      )
  }
}

/// Built-in function: char-numeric?
/// (char-numeric? char) - Determines if a letter is a number
fn builtin_char_numeric_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-numeric?: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_numeric = code >= 48 && code <= 57
      Ok(Value::Bool(is_numeric))
    }
    _ => Err(EvalError::TypeError("char-numeric?: argument must be a character"))
  }
}

/// Built-in function: char-whitespace?
/// (char-whitespace? char) - Determines if a character is a whitespace character
fn builtin_char_whitespace_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-whitespace?: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let is_whitespace = c == ' ' || c == '\t' || c == '\n' || c == '\r'
      Ok(Value::Bool(is_whitespace))
    }
    _ =>
      Err(
        EvalError::TypeError("char-whitespace?: argument must be a character"),
      )
  }
}

/// Built-in function: char-upper-case?
/// (char-upper-case? char) - Determine if characters are uppercase
fn builtin_char_upper_case_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-upper-case?: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_upper = code >= 65 && code <= 90
      Ok(Value::Bool(is_upper))
    }
    _ =>
      Err(
        EvalError::TypeError("char-upper-case?: argument must be a character"),
      )
  }
}

/// Built-in function: char-lower-case?
/// (char-lower-case? char) - Determines if the character is lowercase
fn builtin_char_lower_case_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-lower-case?: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_lower = code >= 97 && code <= 122
      Ok(Value::Bool(is_lower))
    }
    _ =>
      Err(
        EvalError::TypeError("char-lower-case?: argument must be a character"),
      )
  }
}

/// Built-in function: char-upcase
/// (char-upcase char) - convert characters to uppercase
fn builtin_char_upcase(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-upcase: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      if code >= 97 && code <= 122 {
        // Lowercase - > Uppercase
        Ok(Value::Char(Char::from_int(code - 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-upcase: argument must be a character"))
  }
}

/// Built-in function: char-downcase
/// (char-downcase char) - Convert letters to lowercase
fn builtin_char_downcase(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char-downcase: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      if code >= 65 && code <= 90 {
        // Uppercase/Lowercase
        Ok(Value::Char(Char::from_int(code + 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-downcase: argument must be a character"))
  }
}

/// Built-in function: char- > integer
/// (char- > integer char) - Converts a character to an integer (character code)
fn builtin_char_to_integer(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("char->integer: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Char(c) => Ok(Value::Number(Number::Int(c.to_int())))
    _ => Err(EvalError::TypeError("char->integer: argument must be a character"))
  }
}

/// Built-in function: integer- > char
/// (integer- > char n) - Converts an integer (character code) to a character
fn builtin_integer_to_char(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("integer->char: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      if n >= 0 && n <= 1114111 {
        Ok(Value::Char(Char::from_int(n)))
      } else {
        Err(
          EvalError::TypeError(
            "integer->char: integer out of valid Unicode range",
          ),
        )
      }
    }
    _ => Err(EvalError::TypeError("integer->char: argument must be an integer"))
  }
}
