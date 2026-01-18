/// 文字操作組み込み関数
///
/// Scheme の文字操作を実装する。

/// 組み込み関数: char?
/// (char? obj) - obj が文字かどうかを判定
fn builtin_char_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: char=?
/// (char=? char1 char2) - 文字が等しいかを判定
fn builtin_char_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a == b))
    _ => Err(EvalError::TypeError("char=?: arguments must be characters"))
  }
}

/// 組み込み関数: char<?
/// (char<? char1 char2) - char1 が char2 より小さいかを判定
fn builtin_char_lt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() < b.to_int()))
    _ => Err(EvalError::TypeError("char<?: arguments must be characters"))
  }
}

/// 組み込み関数: char>?
/// (char>? char1 char2) - char1 が char2 より大きいかを判定
fn builtin_char_gt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() > b.to_int()))
    _ => Err(EvalError::TypeError("char>?: arguments must be characters"))
  }
}

/// 組み込み関数: char<=?
/// (char<=? char1 char2) - char1 が char2 以下かを判定
fn builtin_char_le(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() <= b.to_int()))
    _ => Err(EvalError::TypeError("char<=?: arguments must be characters"))
  }
}

/// 組み込み関数: char>=?
/// (char>=? char1 char2) - char1 が char2 以上かを判定
fn builtin_char_ge(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() >= b.to_int()))
    _ => Err(EvalError::TypeError("char>=?: arguments must be characters"))
  }
}

/// 組み込み関数: char-alphabetic?
/// (char-alphabetic? char) - 文字がアルファベットかを判定
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

/// 組み込み関数: char-numeric?
/// (char-numeric? char) - 文字が数字かを判定
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

/// 組み込み関数: char-whitespace?
/// (char-whitespace? char) - 文字が空白文字かを判定
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

/// 組み込み関数: char-upper-case?
/// (char-upper-case? char) - 文字が大文字かを判定
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

/// 組み込み関数: char-lower-case?
/// (char-lower-case? char) - 文字が小文字かを判定
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

/// 組み込み関数: char-upcase
/// (char-upcase char) - 文字を大文字に変換
fn builtin_char_upcase(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-upcase: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      if code >= 97 && code <= 122 {
        // 小文字 -> 大文字
        Ok(Value::Char(Char::from_int(code - 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-upcase: argument must be a character"))
  }
}

/// 組み込み関数: char-downcase
/// (char-downcase char) - 文字を小文字に変換
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
        // 大文字 -> 小文字
        Ok(Value::Char(Char::from_int(code + 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-downcase: argument must be a character"))
  }
}

/// 組み込み関数: char->integer
/// (char->integer char) - 文字を整数（文字コード）に変換
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

/// 組み込み関数: integer->char
/// (integer->char n) - 整数（文字コード）を文字に変換
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
