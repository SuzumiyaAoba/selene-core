/// List operation built-in functions
///
/// Implement Scheme list operations.

/// Built-in function: cons
pub fn builtin_cons(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("cons: requires exactly 2 arguments"))
  }
  Ok(Value::Pair(args[0], args[1]))
}

/// Built-in function: car
pub fn builtin_car(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("car: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(car, _) => Ok(car)
    _ => Err(EvalError::TypeError("car: expected pair"))
  }
}

/// Built-in function: cdr
pub fn builtin_cdr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, cdr) => Ok(cdr)
    _ => Err(EvalError::TypeError("cdr: expected pair"))
  }
}

/// Built-in function: set-car!
/// (set-car! pair obj) - Set the pair car to obj
/// Note: Because of the immutable environment model, a new pair is returned
pub fn builtin_set_car(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("set-car!: requires exactly 2 arguments"))
  }
  match args[0] {
    Value::Pair(_, cdr) => Ok(Value::Pair(args[1], cdr))
    _ => Err(EvalError::TypeError("set-car!: first argument must be a pair"))
  }
}

/// Built-in function: set-cdr!
/// (set-cdr! pair obj) - Set the cdr of the pair to obj
/// Note: Because of the immutable environment model, a new pair is returned
pub fn builtin_set_cdr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("set-cdr!: requires exactly 2 arguments"))
  }
  match args[0] {
    Value::Pair(car, _) => Ok(Value::Pair(car, args[1]))
    _ => Err(EvalError::TypeError("set-cdr!: first argument must be a pair"))
  }
}

/// Built-in function: caar
pub fn builtin_caar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(x, _), _) => Ok(x)
    _ => Err(EvalError::TypeError("caar: expected nested pair"))
  }
}

/// Built-in function: cadr
pub fn builtin_cadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(x, _)) => Ok(x)
    _ => Err(EvalError::TypeError("cadr: expected pair with cdr being pair"))
  }
}

/// Built-in function: cdar
pub fn builtin_cdar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, x), _) => Ok(x)
    _ => Err(EvalError::TypeError("cdar: expected pair with car being pair"))
  }
}

/// Built-in function: cddr
pub fn builtin_cddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, x)) => Ok(x)
    _ => Err(EvalError::TypeError("cddr: expected pair with cdr being pair"))
  }
}

/// Built-in function: caaar
pub fn builtin_caaar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caaar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(x, _), _), _) => Ok(x)
    _ => Err(EvalError::TypeError("caaar: expected deeply nested pair"))
  }
}

/// Built-in function: caadr
pub fn builtin_caadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(x, _), _)) => Ok(x)
    _ => Err(EvalError::TypeError("caadr: expected appropriate nested pair"))
  }
}

/// Built-in function: cadar
pub fn builtin_cadar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cadar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(x, _)), _) => Ok(x)
    _ => Err(EvalError::TypeError("cadar: expected appropriate nested pair"))
  }
}

/// Built-in function: caddr
pub fn builtin_caddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(x, _))) => Ok(x)
    _ => Err(EvalError::TypeError("caddr: expected list with at least 3 elements"))
  }
}

/// Built-in function: cdaar
pub fn builtin_cdaar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdaar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(_, x), _), _) => Ok(x)
    _ => Err(EvalError::TypeError("cdaar: expected deeply nested pair"))
  }
}

/// Built-in function: cdadr
pub fn builtin_cdadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(_, x), _)) => Ok(x)
    _ => Err(EvalError::TypeError("cdadr: expected appropriate nested pair"))
  }
}

/// Built-in function: cddar
pub fn builtin_cddar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cddar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(_, x)), _) => Ok(x)
    _ => Err(EvalError::TypeError("cddar: expected appropriate nested pair"))
  }
}

/// Built-in function: cdddr
pub fn builtin_cdddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(_, x))) => Ok(x)
    _ => Err(EvalError::TypeError("cdddr: expected list with at least 3 elements"))
  }
}

/// Built-in function: symbol?
pub fn builtin_symbol_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("symbol?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Symbol(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// Built-in functions: list
pub fn builtin_list(args : Array[Value]) -> Result[Value, EvalError] {
  let mut result = Value::Nil
  let mut i = args.length()
  let _ = while i > 0 {
    i = i - 1
    result = Value::Pair(args[i], result)
  } else {
    ()
  }
  Ok(result)
}

/// Built-in function: length
pub fn builtin_length(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("length: requires exactly 1 argument"))
  }
  let mut len = 0
  let mut current = args[0]
  let _ = while true {
    match current {
      Value::Nil => break
      Value::Pair(_, cdr) => {
        len = len + 1
        current = cdr
      }
      _ =>
        return Err(
          EvalError::TypeError("length: argument must be a proper list"),
        )
    }
  } else {
    ()
  }
  Ok(Value::Number(Number::Int(len)))
}

/// Built-in functions: append
pub fn builtin_append(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Nil)
  }
  if args.length() == 1 {
    return Ok(args[0])
  }

  // Gather non-last list into array
  let lists : Array[Value] = []
  let mut i = 0
  let len = args.length() - 1
  let _ = while i < len {
    lists.push(args[i])
    i = i + 1
  } else {
    ()
  }

  // Last Element
  let mut result = args[args.length() - 1]

  // Back to Forward Concatenation
  let mut j = lists.length()
  let _ = while j > 0 {
    j = j - 1
    result = match append_two_lists(lists[j], result) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  } else {
    ()
  }

  Ok(result)
}

/// Auxiliary function to concatenate two lists
fn append_two_lists(list1 : Value, list2 : Value) -> Result[Value, EvalError] {
  match list1 {
    Value::Nil => Ok(list2)
    Value::Pair(car, cdr) => {
      let rest = match append_two_lists(cdr, list2) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      Ok(Value::Pair(car, rest))
    }
    _ => Err(EvalError::TypeError("append: arguments must be lists"))
  }
}

/// Built-in functions: reverse
pub fn builtin_reverse(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("reverse: requires exactly 1 argument"))
  }
  let mut result = Value::Nil
  let mut current = args[0]
  let _ = while true {
    match current {
      Value::Nil => break
      Value::Pair(car, cdr) => {
        result = Value::Pair(car, result)
        current = cdr
      }
      _ =>
        return Err(
          EvalError::TypeError("reverse: argument must be a proper list"),
        )
    }
  } else {
    ()
  }
  Ok(result)
}

/// Built-in function: list-ref
pub fn builtin_list_ref(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("list-ref: requires exactly 2 arguments"))
  }
  let index = match args[1] {
    Value::Number(Number::Int(n)) => {
      if n < 0 {
        return Err(EvalError::TypeError("list-ref: index must be non-negative"))
      }
      n
    }
    _ => return Err(EvalError::TypeError("list-ref: index must be an integer"))
  }

  let mut current = args[0]
  let mut i = 0
  let _ = while i < index {
    match current {
      Value::Pair(_, cdr) => {
        current = cdr
        i = i + 1
      }
      _ => return Err(EvalError::TypeError("list-ref: index out of bounds"))
    }
  } else {
    ()
  }

  match current {
    Value::Pair(car, _) => Ok(car)
    _ => Err(EvalError::TypeError("list-ref: index out of bounds"))
  }
}

/// Built-in function: list-tail
pub fn builtin_list_tail(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("list-tail: requires exactly 2 arguments"))
  }
  let k = match args[1] {
    Value::Number(Number::Int(n)) => {
      if n < 0 {
        return Err(EvalError::TypeError("list-tail: k must be non-negative"))
      }
      n
    }
    _ => return Err(EvalError::TypeError("list-tail: k must be an integer"))
  }

  let mut current = args[0]
  let mut i = 0
  let _ = while i < k {
    match current {
      Value::Pair(_, cdr) => {
        current = cdr
        i = i + 1
      }
      _ => return Err(EvalError::TypeError("list-tail: k exceeds list length"))
    }
  } else {
    ()
  }

  Ok(current)
}

/// Built-in function: assq
/// (assq obj alist) - Search for obj from alist by eq?
pub fn builtin_assq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("assq: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(pair, rest) => {
        match pair {
          Value::Pair(key, _) => {
            // comparison by eq?
            if values_eq(obj, key) {
              return Ok(pair)
            }
            current = rest
          }
          _ =>
            return Err(
              EvalError::TypeError("assq: alist element must be a pair"),
            )
        }
      }
      _ => return Err(EvalError::TypeError("assq: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// Built-in function: assv
/// (assv obj alist) - Search for obj from alist by eqv?
pub fn builtin_assv(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("assv: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(pair, rest) => {
        match pair {
          Value::Pair(key, _) => {
            // comparison by eqv?
            if values_eqv(obj, key) {
              return Ok(pair)
            }
            current = rest
          }
          _ =>
            return Err(
              EvalError::TypeError("assv: alist element must be a pair"),
            )
        }
      }
      _ => return Err(EvalError::TypeError("assv: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// Built-in function: assoc
/// (assoc obj alist) - Search for obj from alist by equal?
pub fn builtin_assoc(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("assoc: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(pair, rest) => {
        match pair {
          Value::Pair(key, _) => {
            // comparison by equal?
            if values_equal(obj, key) {
              return Ok(pair)
            }
            current = rest
          }
          _ =>
            return Err(
              EvalError::TypeError("assoc: alist element must be a pair"),
            )
        }
      }
      _ =>
        return Err(EvalError::TypeError("assoc: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// Built-in function: memq
/// (memq obj list) - eq obj from list? Search in and return a list starting at the location found
pub fn builtin_memq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("memq: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(head, tail) => {
        if values_eq(obj, head) {
          return Ok(current)
        }
        current = tail
      }
      _ => return Err(EvalError::TypeError("memq: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// Built-in function: memv
/// (memv obj list) - eqv obj from list? Search in and return a list starting at the location found
pub fn builtin_memv(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("memv: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(head, tail) => {
        if values_eqv(obj, head) {
          return Ok(current)
        }
        current = tail
      }
      _ => return Err(EvalError::TypeError("memv: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// Built-in function: member
/// (member obj list) - equal obj from list? Search in and return a list starting at the location found
pub fn builtin_member(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("member: requires exactly 2 arguments"))
  }
  let obj = args[0]
  let mut current = args[1]
  let _ = while true {
    match current {
      Value::Nil => return Ok(Value::Bool(false))
      Value::Pair(head, tail) => {
        if values_equal(obj, head) {
          return Ok(current)
        }
        current = tail
      }
      _ =>
        return Err(EvalError::TypeError("member: second argument must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Bool(false))
}

/// comparison of values by eq? (most stringent)
fn values_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    _ => false
  }
}

/// Built-in function: symbol- > string
/// (symbol- > string sym) - Convert symbol to string
pub fn builtin_symbol_to_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("symbol->string: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::Symbol(s) => Ok(Value::String(s))
    _ => Err(EvalError::TypeError("symbol->string: argument must be a symbol"))
  }
}

/// Built-in functions: string- > symbol
/// (string- > symbol str) - Convert string to symbol
pub fn builtin_string_to_symbol(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(
      EvalError::ArityError("string->symbol: requires exactly 1 argument"),
    )
  }
  match args[0] {
    Value::String(s) => Ok(Value::Symbol(s))
    _ => Err(EvalError::TypeError("string->symbol: argument must be a string"))
  }
}

/// Converts a list of values to an array.
pub fn list_to_array(list : Value) -> Result[Array[Value], EvalError] {
  let items : Array[Value] = []
  let mut current = list
  let _ = while true {
    match current {
      Value::Nil => return Ok(items)
      Value::Pair(car, cdr) => {
        items.push(car)
        current = cdr
      }
      _ => return Err(EvalError::TypeError("not a proper list"))
    }
  } else {
    ()
  }
  Ok(items)
}

/// Converts an array to a list of values.
pub fn array_to_list(items : Array[Value]) -> Result[Value, EvalError] {
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
