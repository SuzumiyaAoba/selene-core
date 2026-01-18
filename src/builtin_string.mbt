/// 文字列操作組み込み関数
///
/// Scheme の文字列操作を実装する。

/// 組み込み関数: string?
/// (string? obj) - obj が文字列かどうかを判定
fn builtin_string_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("string?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: string-length
/// (string-length str) - 文字列の長さを返す
fn builtin_string_length(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("string-length: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::String(s) => Ok(Value::Number(Number::Int(s.length())))
    _ => Err(EvalError::TypeError("string-length: argument must be a string"))
  }
}

/// 組み込み関数: string-ref
/// (string-ref str k) - 文字列の k 番目の文字を返す
fn builtin_string_ref(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("string-ref: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::String(s), Value::Number(Number::Int(k))) => {
      let chars : Array[Char] = s.iter().collect()
      if k < 0 || k >= chars.length() {
        return Err(EvalError::InvalidSyntax("string-ref: index out of bounds"))
      }
      Ok(Value::Char(chars[k]))
    }
    (Value::String(_), _) =>
      Err(
        EvalError::TypeError("string-ref: second argument must be an integer"),
      )
    _ => Err(EvalError::TypeError("string-ref: first argument must be a string"))
  }
}

/// 組み込み関数: string-append
/// (string-append str1 str2 ...) - 文字列を連結する
fn builtin_string_append(args : Array[Value]) -> Result[Value, EvalError] {
  let builder = StringBuilder::new()
  for arg in args {
    match arg {
      Value::String(s) => builder.write_string(s)
      _ =>
        return Err(
          EvalError::TypeError("string-append: all arguments must be strings"),
        )
    }
  }
  Ok(Value::String(builder.to_string()))
}

/// 組み込み関数: string=?
/// (string=? str1 str2) - 文字列が等しいかを判定
fn builtin_string_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("string=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::String(s1), Value::String(s2)) => Ok(Value::Bool(s1 == s2))
    _ => Err(EvalError::TypeError("string=?: both arguments must be strings"))
  }
}

/// 組み込み関数: make-string
/// (make-string k [char]) - 長さ k の文字列を作成（オプションで文字を指定）
fn builtin_make_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("make-string: requires 1 or 2 arguments"))
  }
  match args[0] {
    Value::Number(Number::Int(k)) => {
      if k < 0 {
        return Err(
          EvalError::InvalidSyntax("make-string: length must be non-negative"),
        )
      }
      let ch = if args.length() == 2 {
        match args[1] {
          Value::Char(c) => c
          _ =>
            return Err(
              EvalError::TypeError(
                "make-string: second argument must be a character",
              ),
            )
        }
      } else {
        ' ' // デフォルトはスペース
      }
      let builder = StringBuilder::new()
      let mut i = 0
      let _ = while i < k {
        builder.write_char(ch)
        i = i + 1
      } else {
        ()
      }
      Ok(Value::String(builder.to_string()))
    }
    _ =>
      Err(
        EvalError::TypeError("make-string: first argument must be an integer"),
      )
  }
}

/// 組み込み関数: substring
/// (substring str start end) - 文字列の部分文字列を返す
fn builtin_substring(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(EvalError::ArityError("substring: requires exactly 3 arguments"))
  }
  match (args[0], args[1], args[2]) {
    (
      Value::String(s),
      Value::Number(Number::Int(start)),
      Value::Number(Number::Int(end)),
    ) => {
      if start < 0 || end < start || end > s.length() {
        return Err(EvalError::InvalidSyntax("substring: invalid range"))
      }
      let chars : Array[Char] = s.iter().collect()
      let builder = StringBuilder::new()
      let mut i = start
      let _ = while i < end {
        builder.write_char(chars[i])
        i = i + 1
      } else {
        ()
      }
      Ok(Value::String(builder.to_string()))
    }
    (Value::String(_), _, _) =>
      Err(
        EvalError::TypeError(
          "substring: second and third arguments must be integers",
        ),
      )
    _ => Err(EvalError::TypeError("substring: first argument must be a string"))
  }
}

/// 組み込み関数: string->list
/// (string->list str) - 文字列を文字のリストに変換
fn builtin_string_to_list(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("string->list: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::String(s) => {
      let chars = s.to_array()
      let mut result = Value::Nil
      let mut i = chars.length()
      let _ = while i > 0 {
        i = i - 1
        result = Value::Pair(Value::Char(chars[i]), result)
      } else {
        ()
      }
      Ok(result)
    }
    _ => Err(EvalError::TypeError("string->list: argument must be a string"))
  }
}

/// 組み込み関数: list->string
/// (list->string list) - 文字のリストを文字列に変換
fn builtin_list_to_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("list->string: requires exactly 1 argument"),
    )
  }
  let chars : Array[Char] = []
  let mut current = args[0]
  let _ = while true {
    match current {
      Value::Nil => break
      Value::Pair(Value::Char(c), rest) => {
        chars.push(c)
        current = rest
      }
      Value::Pair(_, _) =>
        return Err(
          EvalError::TypeError("list->string: list must contain only characters"),
        )
      _ =>
        return Err(
          EvalError::TypeError("list->string: argument must be a proper list"),
        )
    }
  } else {
    ()
  }

  let mut result = ""
  for c in chars {
    result = result + c.to_string()
  }
  Ok(Value::String(result))
}

/// 組み込み関数: number->string
/// (number->string num) - 数値を文字列に変換
fn builtin_number_to_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("number->string: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::String(n.to_string()))
    Value::Number(Number::Real(r)) => Ok(Value::String(r.to_string()))
    _ => Err(EvalError::TypeError("number->string: argument must be a number"))
  }
}

/// 組み込み関数: string->number
/// (string->number str) - 文字列を数値に変換
fn builtin_string_to_number(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("string->number: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::String(s) => {
      // まず整数としてパースを試みる
      // try?を使ってResult型に変換
      let int_result = try? @strconv.parse_int(s)
      match int_result {
        Ok(n) => return Ok(Value::Number(Number::Int(n)))
        Err(_) => ()
      }
      // 整数でなければ実数としてパースを試みる
      let double_result = try? @strconv.parse_double(s)
      match double_result {
        Ok(d) => return Ok(Value::Number(Number::Real(d)))
        Err(_) => ()
      }
      // どちらも失敗したら#fを返す
      Ok(Value::Bool(false))
    }
    _ => Err(EvalError::TypeError("string->number: argument must be a string"))
  }
}
