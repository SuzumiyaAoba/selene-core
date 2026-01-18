/// ベクタ操作組み込み関数
///
/// Scheme のベクタ操作を実装する。

/// 組み込み関数: vector?
/// (vector? obj) - obj がベクトルかどうかを判定
fn builtin_vector_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("vector?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Vector(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: make-vector
/// (make-vector k [fill]) - 長さ k のベクトルを作成（オプションで初期値を指定）
fn builtin_make_vector(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("make-vector: requires 1 or 2 arguments"))
  }
  match args[0] {
    Value::Number(Number::Int(k)) => {
      if k < 0 {
        return Err(
          EvalError::InvalidSyntax("make-vector: length must be non-negative"),
        )
      }
      let fill = if args.length() == 2 {
        args[1]
      } else {
        Value::Nil // デフォルトは ()
      }
      let items : Array[Value] = []
      let mut i = 0
      let _ = while i < k {
        items.push(fill)
        i = i + 1
      } else {
        ()
      }
      Ok(Value::Vector(items))
    }
    _ =>
      Err(
        EvalError::TypeError("make-vector: first argument must be an integer"),
      )
  }
}

/// 組み込み関数: vector
/// (vector obj ...) - 引数からベクトルを作成
fn builtin_vector(args : Array[Value]) -> Result[Value, EvalError] {
  let items : Array[Value] = []
  for arg in args {
    items.push(arg)
  }
  Ok(Value::Vector(items))
}

/// 組み込み関数: vector-length
/// (vector-length vector) - ベクトルの長さを返す
fn builtin_vector_length(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("vector-length: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Vector(items) => Ok(Value::Number(Number::Int(items.length())))
    _ => Err(EvalError::TypeError("vector-length: argument must be a vector"))
  }
}

/// 組み込み関数: vector-ref
/// (vector-ref vector k) - ベクトルの k 番目の要素を返す
fn builtin_vector_ref(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(
      EvalError::ArityError("vector-ref: requires exactly 2 arguments"),
    )
  }
  match (args[0], args[1]) {
    (Value::Vector(items), Value::Number(Number::Int(k))) => {
      if k < 0 || k >= items.length() {
        return Err(EvalError::InvalidSyntax("vector-ref: index out of bounds"))
      }
      Ok(items[k])
    }
    (Value::Vector(_), _) =>
      Err(
        EvalError::TypeError("vector-ref: second argument must be an integer"),
      )
    _ => Err(EvalError::TypeError("vector-ref: first argument must be a vector"))
  }
}

/// 組み込み関数: vector-set!
/// (vector-set! vector k obj) - ベクトルの k 番目の要素を obj に設定
/// 注: 不変環境モデルのため、新しいベクトルを返す
fn builtin_vector_set(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(
      EvalError::ArityError("vector-set!: requires exactly 3 arguments"),
    )
  }
  match (args[0], args[1]) {
    (Value::Vector(items), Value::Number(Number::Int(k))) => {
      if k < 0 || k >= items.length() {
        return Err(EvalError::InvalidSyntax("vector-set!: index out of bounds"))
      }
      let new_items : Array[Value] = []
      let mut i = 0
      let len = items.length()
      let _ = while i < len {
        if i == k {
          new_items.push(args[2])
        } else {
          new_items.push(items[i])
        }
        i = i + 1
      } else {
        ()
      }
      // 注: 本来は副作用のみで戻り値は未定義だが、不変モデルでは新しいベクトルを返す
      Ok(Value::Vector(new_items))
    }
    (Value::Vector(_), _) =>
      Err(
        EvalError::TypeError("vector-set!: second argument must be an integer"),
      )
    _ =>
      Err(EvalError::TypeError("vector-set!: first argument must be a vector"))
  }
}

/// 組み込み関数: vector->list
/// (vector->list vector) - ベクトルをリストに変換
fn builtin_vector_to_list(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("vector->list: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Vector(items) => {
      let mut result = Value::Nil
      let mut i = items.length()
      let _ = while i > 0 {
        i = i - 1
        result = Value::Pair(items[i], result)
      } else {
        ()
      }
      Ok(result)
    }
    _ => Err(EvalError::TypeError("vector->list: argument must be a vector"))
  }
}

/// 組み込み関数: list->vector
/// (list->vector list) - リストをベクトルに変換
fn builtin_list_to_vector(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("list->vector: requires exactly 1 argument"),
    )
  }
  let list_items = match list_to_array(args[0]) {
    Ok(items) => items
    Err(e) => return Err(e)
  }
  Ok(Value::Vector(list_items))
}
