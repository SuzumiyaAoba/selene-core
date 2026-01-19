/// I/O 組み込み関数
///
/// Scheme の入出力操作を実装する。

/// 値を表示用文字列に変換する（displayで使用）
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
    Value::String(s) => s // displayは文字列を引用符なしで出力
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_display_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
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
  }
}

/// 値を書き込み用文字列に変換する（writeで使用）
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
    Value::String(s) => "\"" + s + "\"" // writeは文字列を引用符付きで出力
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_write_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
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
  }
}

/// 組み込み関数: display
/// (display obj) - objを人間が読みやすい形式で出力する（文字列は引用符なし）
/// 注: MoonBitではprintlnのみが利用可能なため、改行付きで出力されます
fn builtin_display(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("display: requires exactly 1 argument"))
  }
  let output = value_to_display_string(args[0])
  println(output)
  Ok(Value::Nil) // displayは未定義値を返す（Nilで代用）
}

/// 組み込み関数: newline
/// (newline) - 改行を出力する
fn builtin_newline(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 0 {
    return Err(EvalError::ArityError("newline: requires exactly 0 arguments"))
  }
  println("")
  Ok(Value::Nil) // newlineは未定義値を返す（Nilで代用）
}

/// 組み込み関数: write
/// (write obj) - objを機械が読める形式で出力する（文字列は引用符付き）
/// 注: MoonBitではprintlnのみが利用可能なため、改行付きで出力されます
fn builtin_write(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("write: requires exactly 1 argument"))
  }
  let output = value_to_write_string(args[0])
  println(output)
  Ok(Value::Nil) // writeは未定義値を返す（Nilで代用）
}

/// 組み込み関数: read
/// (read) - 標準入力から1つのS式を読み取って返す
/// 注: このバージョンはJS バックエンド専用です
fn builtin_read(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 0 {
    return Err(EvalError::ArityError("read: requires exactly 0 arguments"))
  }
  // JS FFI経由で標準入力から一行読み取る
  let line = read_line()
  // パースしてS式に変換
  let sexpr = parse_one(line)
  // S式をValueに変換（評価せずにデータとして返す）
  Ok(sexpr_to_value(sexpr))
}
