/// リスト操作組み込み関数
///
/// Scheme のリスト操作を実装する。

/// 組み込み関数: cons
fn builtin_cons(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("cons: requires exactly 2 arguments"))
  }
  Ok(Value::Pair(args[0], args[1]))
}

/// 組み込み関数: car
fn builtin_car(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("car: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(car, _) => Ok(car)
    _ => Err(EvalError::TypeError("car: expected pair"))
  }
}

/// 組み込み関数: cdr
fn builtin_cdr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, cdr) => Ok(cdr)
    _ => Err(EvalError::TypeError("cdr: expected pair"))
  }
}

/// 組み込み関数: caar
fn builtin_caar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(x, _), _) => Ok(x)
    _ => Err(EvalError::TypeError("caar: expected nested pair"))
  }
}

/// 組み込み関数: cadr
fn builtin_cadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(x, _)) => Ok(x)
    _ => Err(EvalError::TypeError("cadr: expected pair with cdr being pair"))
  }
}

/// 組み込み関数: cdar
fn builtin_cdar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, x), _) => Ok(x)
    _ => Err(EvalError::TypeError("cdar: expected pair with car being pair"))
  }
}

/// 組み込み関数: cddr
fn builtin_cddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, x)) => Ok(x)
    _ => Err(EvalError::TypeError("cddr: expected pair with cdr being pair"))
  }
}

/// 組み込み関数: caaar
fn builtin_caaar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caaar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(x, _), _), _) => Ok(x)
    _ => Err(EvalError::TypeError("caaar: expected deeply nested pair"))
  }
}

/// 組み込み関数: caadr
fn builtin_caadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(x, _), _)) => Ok(x)
    _ => Err(EvalError::TypeError("caadr: expected appropriate nested pair"))
  }
}

/// 組み込み関数: cadar
fn builtin_cadar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cadar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(x, _)), _) => Ok(x)
    _ => Err(EvalError::TypeError("cadar: expected appropriate nested pair"))
  }
}

/// 組み込み関数: caddr
fn builtin_caddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("caddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(x, _))) => Ok(x)
    _ => Err(EvalError::TypeError("caddr: expected list with at least 3 elements"))
  }
}

/// 組み込み関数: cdaar
fn builtin_cdaar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdaar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(_, x), _), _) => Ok(x)
    _ => Err(EvalError::TypeError("cdaar: expected deeply nested pair"))
  }
}

/// 組み込み関数: cdadr
fn builtin_cdadr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdadr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(_, x), _)) => Ok(x)
    _ => Err(EvalError::TypeError("cdadr: expected appropriate nested pair"))
  }
}

/// 組み込み関数: cddar
fn builtin_cddar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cddar: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(_, x)), _) => Ok(x)
    _ => Err(EvalError::TypeError("cddar: expected appropriate nested pair"))
  }
}

/// 組み込み関数: cdddr
fn builtin_cdddr(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cdddr: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(_, x))) => Ok(x)
    _ => Err(EvalError::TypeError("cdddr: expected list with at least 3 elements"))
  }
}

/// 組み込み関数: symbol?
fn builtin_symbol_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("symbol?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Symbol(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: list
fn builtin_list(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: length
fn builtin_length(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: append
fn builtin_append(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Nil)
  }
  if args.length() == 1 {
    return Ok(args[0])
  }

  // 最後以外のリストを配列に集める
  let lists : Array[Value] = []
  let mut i = 0
  let len = args.length() - 1
  let _ = while i < len {
    lists.push(args[i])
    i = i + 1
  } else {
    ()
  }

  // 最後の要素
  let mut result = args[args.length() - 1]

  // 後ろから前に向かって連結
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

/// 2つのリストを連結する補助関数
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

/// 組み込み関数: reverse
fn builtin_reverse(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: list-ref
fn builtin_list_ref(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: list-tail
fn builtin_list_tail(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: assq
/// (assq obj alist) - alist から obj を eq? で検索
fn builtin_assq(args : Array[Value]) -> Result[Value, EvalError] {
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
            // eq? による比較
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

/// 組み込み関数: assv
/// (assv obj alist) - alist から obj を eqv? で検索
fn builtin_assv(args : Array[Value]) -> Result[Value, EvalError] {
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
            // eqv? による比較
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

/// 組み込み関数: assoc
/// (assoc obj alist) - alist から obj を equal? で検索
fn builtin_assoc(args : Array[Value]) -> Result[Value, EvalError] {
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
            // equal? による比較
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

/// 組み込み関数: memq
/// (memq obj list) - list から obj を eq? で検索し、見つかった位置から始まるリストを返す
fn builtin_memq(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: memv
/// (memv obj list) - list から obj を eqv? で検索し、見つかった位置から始まるリストを返す
fn builtin_memv(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: member
/// (member obj list) - list から obj を equal? で検索し、見つかった位置から始まるリストを返す
fn builtin_member(args : Array[Value]) -> Result[Value, EvalError] {
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

/// eq? による値の比較（最も厳密）
fn values_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    _ => false
  }
}

/// 組み込み関数: symbol->string
/// (symbol->string sym) - シンボルを文字列に変換
fn builtin_symbol_to_string(args : Array[Value]) -> Result[Value, EvalError] {
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

/// 組み込み関数: string->symbol
/// (string->symbol str) - 文字列をシンボルに変換
fn builtin_string_to_symbol(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Value のリストを配列に変換する。
fn list_to_array(list : Value) -> Result[Array[Value], EvalError] {
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

/// 配列を Value のリストに変換する。
fn array_to_list(items : Array[Value]) -> Result[Value, EvalError] {
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
