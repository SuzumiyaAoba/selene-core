/// ポート操作の組み込み関数
///
/// R5RS のポート関連関数を実装する。

// =============================================================================
// ポート述語
// =============================================================================

/// input-port? - 入力ポートかどうか
fn builtin_input_port_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("input-port?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Port(port) => Ok(Value::Bool(port.direction == PortDirection::Input))
    _ => Ok(Value::Bool(false))
  }
}

/// output-port? - 出力ポートかどうか
fn builtin_output_port_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("output-port?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Port(port) => Ok(Value::Bool(port.direction == PortDirection::Output))
    _ => Ok(Value::Bool(false))
  }
}

/// port? - ポートかどうか
fn builtin_port_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("port?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Port(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

// =============================================================================
// ファイルポート操作
// =============================================================================

/// open-input-file - 入力ファイルを開く
fn builtin_open_input_file(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("open-input-file: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(filename) => {
      let port_id = new_port_id()
      let result = open_input_file(filename, port_id)
      if result < 0 {
        Err(EvalError::TypeError("open-input-file: cannot open file: " + filename))
      } else {
        Ok(
          Value::Port(
            {
              id: port_id,
              direction: PortDirection::Input,
              open: { val: true },
              name: filename,
            },
          ),
        )
      }
    }
    _ => Err(EvalError::TypeError("open-input-file: expected string"))
  }
}

/// open-output-file - 出力ファイルを開く
fn builtin_open_output_file(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("open-output-file: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(filename) => {
      let port_id = new_port_id()
      let result = open_output_file(filename, port_id)
      if result < 0 {
        Err(EvalError::TypeError("open-output-file: cannot open file: " + filename))
      } else {
        Ok(
          Value::Port(
            {
              id: port_id,
              direction: PortDirection::Output,
              open: { val: true },
              name: filename,
            },
          ),
        )
      }
    }
    _ => Err(EvalError::TypeError("open-output-file: expected string"))
  }
}

/// close-input-port - 入力ポートを閉じる
fn builtin_close_input_port(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("close-input-port: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Port(port) => {
      if port.direction != PortDirection::Input {
        return Err(EvalError::TypeError("close-input-port: not an input port"))
      }
      if not(port.open.val) {
        return Ok(Value::Nil) // すでに閉じている
      }
      let _ = close_port(port.id)
      port.open.val = false
      Ok(Value::Nil)
    }
    _ => Err(EvalError::TypeError("close-input-port: expected port"))
  }
}

/// close-output-port - 出力ポートを閉じる
fn builtin_close_output_port(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("close-output-port: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Port(port) => {
      if port.direction != PortDirection::Output {
        return Err(EvalError::TypeError("close-output-port: not an output port"))
      }
      if not(port.open.val) {
        return Ok(Value::Nil) // すでに閉じている
      }
      let _ = close_port(port.id)
      port.open.val = false
      Ok(Value::Nil)
    }
    _ => Err(EvalError::TypeError("close-output-port: expected port"))
  }
}

// =============================================================================
// 入力操作
// =============================================================================

/// read-char - ポートから1文字読み取る
fn builtin_read_char(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() > 1 {
    return Err(EvalError::ArityError("read-char: requires 0 or 1 argument"))
  }
  if args.length() == 0 {
    // 標準入力から読み取る（未実装）
    return Err(EvalError::TypeError("read-char: standard input not supported"))
  }
  match args[0] {
    Value::Port(port) => {
      if port.direction != PortDirection::Input {
        return Err(EvalError::TypeError("read-char: not an input port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("read-char: port is closed"))
      }
      let char_code = read_char_from_port(port.id)
      if char_code < 0 {
        // EOF - eof-objectを返す（ここではNilで代用）
        Ok(Value::Symbol("#<eof>"))
      } else {
        Ok(Value::Char(char_code.unsafe_to_char()))
      }
    }
    _ => Err(EvalError::TypeError("read-char: expected port"))
  }
}

/// peek-char - ポートから1文字先読み（消費しない）
fn builtin_peek_char(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() > 1 {
    return Err(EvalError::ArityError("peek-char: requires 0 or 1 argument"))
  }
  if args.length() == 0 {
    // 標準入力から読み取る（未実装）
    return Err(EvalError::TypeError("peek-char: standard input not supported"))
  }
  match args[0] {
    Value::Port(port) => {
      if port.direction != PortDirection::Input {
        return Err(EvalError::TypeError("peek-char: not an input port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("peek-char: port is closed"))
      }
      let char_code = peek_char_from_port(port.id)
      if char_code < 0 {
        // EOF
        Ok(Value::Symbol("#<eof>"))
      } else {
        Ok(Value::Char(char_code.unsafe_to_char()))
      }
    }
    _ => Err(EvalError::TypeError("peek-char: expected port"))
  }
}

/// eof-object? - EOFオブジェクトかどうか
fn builtin_eof_object_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("eof-object?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Symbol("#<eof>") => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

// =============================================================================
// 出力操作
// =============================================================================

/// write-char - ポートに1文字書き込む
fn builtin_write_char_port(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("write-char: requires 1 or 2 arguments"))
  }
  let char_val = match args[0] {
    Value::Char(c) => c
    _ => return Err(EvalError::TypeError("write-char: expected char"))
  }
  if args.length() == 1 {
    // 標準出力に書き込む
    println(char_val.to_string())
    return Ok(Value::Nil)
  }
  match args[1] {
    Value::Port(port) => {
      if port.direction != PortDirection::Output {
        return Err(EvalError::TypeError("write-char: not an output port"))
      }
      if not(port.open.val) {
        return Err(EvalError::TypeError("write-char: port is closed"))
      }
      let success = write_char_to_port(port.id, char_val.to_int())
      if success {
        Ok(Value::Nil)
      } else {
        Err(EvalError::TypeError("write-char: write failed"))
      }
    }
    _ => Err(EvalError::TypeError("write-char: expected port"))
  }
}
