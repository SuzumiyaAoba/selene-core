/// Vector Operation Built-in Functions
///
/// Implement the vector operation of Scheme.

/// Built-in function: vector?
/// (vector? obj) - Determine if obj is a vector
pub fn builtin_vector_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("vector?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Vector(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// Built-in function: make-vector
/// (make-vector k [fill]) - creates a vector of length k (optional initial value)
pub fn builtin_make_vector(args : Array[Value]) -> Result[Value, EvalError] {
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
        Value::Nil // Default is
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

/// Built-in function: vector
/// (vector obj...) - create vector from arguments
pub fn builtin_vector(args : Array[Value]) -> Result[Value, EvalError] {
  let items : Array[Value] = []
  for arg in args {
    items.push(arg)
  }
  Ok(Value::Vector(items))
}

/// Built-in function: vector-length
/// (vector-length vector) - Returns the length of a vector
pub fn builtin_vector_length(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: vector-ref
/// (vector-ref vector k) - returns the kth element of the vector
pub fn builtin_vector_ref(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: vector-set!
/// (vector-set! vector k obj) - sets the kth element of the vector to obj
/// Note: Because of the immutable environment model, a new vector is returned
pub fn builtin_vector_set(args : Array[Value]) -> Result[Value, EvalError] {
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
      // Note: Originally only side effects, the return value is undefined, but the invariant model returns a new vector
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

/// Built-in function: vector- > list
/// (vector- > list vector) - Convert vector to list
pub fn builtin_vector_to_list(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: list- > vector
/// (list- > vector list) - Convert list to vector
pub fn builtin_list_to_vector(args : Array[Value]) -> Result[Value, EvalError] {
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
