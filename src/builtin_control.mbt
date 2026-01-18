/// 制御フロー組み込み関数
///
/// Scheme の制御フロー操作を実装する。

/// 組み込み関数: call/cc (call-with-current-continuation)
/// (call/cc proc) - 現在の継続を捕獲し、procに渡す
fn builtin_call_cc(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("call/cc: requires exactly 1 argument"))
  }

  // 引数は1引数の手続きでなければならない
  let proc = args[0]
  match proc {
    Value::Procedure(_) => {
      // 新しい継続を作成
      let cont_id = new_continuation_id()
      let cont = Value::Procedure(Procedure::Cont({ id: cont_id }))

      // 手続きに継続を渡して呼び出す
      let result = apply(proc, [cont])

      // 結果を処理
      match result {
        Ok(value) => Ok(value)
        Err(EvalError::ContinuationInvoked(id, value)) => {
          // この call/cc の継続が呼び出された場合
          if id == cont_id {
            Ok(value)
          } else {
            // 別の継続が呼び出された場合は伝播
            Err(EvalError::ContinuationInvoked(id, value))
          }
        }
        Err(e) => Err(e)
      }
    }
    _ => Err(EvalError::TypeError("call/cc: argument must be a procedure"))
  }
}

/// 組み込み関数: apply
/// (apply proc arg1 ... argN args) - args はリストでなければならない
fn builtin_apply(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("apply: requires at least 2 arguments"))
  }

  // 最初の引数は手続きでなければならない
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("apply: first argument must be a procedure"),
      )
  }

  // 最後の引数はリストでなければならない
  let last_arg = args[args.length() - 1]
  let last_list_items = match list_to_array(last_arg) {
    Ok(items) => items
    Err(e) => return Err(e)
  }

  // 中間の引数と最後のリストの要素を結合
  let combined_args : Array[Value] = []
  // 中間の引数（args[1] から args[length-2]）を追加
  let mut i = 1
  let last_idx = args.length() - 1
  let _ = while i < last_idx {
    combined_args.push(args[i])
    i = i + 1
  } else {
    ()
  }
  // 最後のリストの要素を追加
  for item in last_list_items {
    combined_args.push(item)
  }

  // 手続きを適用
  apply(proc, combined_args)
}

/// 組み込み関数: map
/// (map proc list1 list2 ...) - 各リストの対応する要素に proc を適用し、結果のリストを返す
fn builtin_map(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("map: requires at least 2 arguments"))
  }

  // 最初の引数は手続きでなければならない
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(EvalError::TypeError("map: first argument must be a procedure"))
  }

  // 残りの引数はすべてリストでなければならない
  let lists : Array[Array[Value]] = []
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let list_items = match list_to_array(args[i]) {
      Ok(items) => items
      Err(e) => return Err(e)
    }
    lists.push(list_items)
    i = i + 1
  } else {
    ()
  }

  // すべてのリストが同じ長さかチェック（簡易版：最初のリストの長さを使用）
  if lists.length() == 0 {
    return Ok(Value::Nil)
  }
  let list_len = lists[0].length()

  // 結果リストを構築
  let results : Array[Value] = []
  let mut idx = 0
  let _ = while idx < list_len {
    // 各リストから idx 番目の要素を取得
    let proc_args : Array[Value] = []
    let mut list_idx = 0
    let _ = while list_idx < lists.length() {
      if idx >= lists[list_idx].length() {
        return Err(
          EvalError::InvalidSyntax("map: lists must have the same length"),
        )
      }
      proc_args.push(lists[list_idx][idx])
      list_idx = list_idx + 1
    } else {
      ()
    }

    // 手続きを適用
    let result = match apply(proc, proc_args) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    results.push(result)
    idx = idx + 1
  } else {
    ()
  }

  // 配列をリストに変換
  array_to_list(results)
}

/// 組み込み関数: for-each
/// (for-each proc list1 list2 ...) - 各リストの対応する要素に proc を適用（副作用のため）
fn builtin_for_each(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("for-each: requires at least 2 arguments"))
  }

  // 最初の引数は手続きでなければならない
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("for-each: first argument must be a procedure"),
      )
  }

  // 残りの引数はすべてリストでなければならない
  let lists : Array[Array[Value]] = []
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let list_items = match list_to_array(args[i]) {
      Ok(items) => items
      Err(e) => return Err(e)
    }
    lists.push(list_items)
    i = i + 1
  } else {
    ()
  }

  if lists.length() == 0 {
    return Ok(Value::Nil)
  }
  let list_len = lists[0].length()

  let mut idx = 0
  let _ = while idx < list_len {
    let proc_args : Array[Value] = []
    let mut list_idx = 0
    let _ = while list_idx < lists.length() {
      if idx >= lists[list_idx].length() {
        return Err(
          EvalError::InvalidSyntax("for-each: lists must have the same length"),
        )
      }
      proc_args.push(lists[list_idx][idx])
      list_idx = list_idx + 1
    } else {
      ()
    }

    match apply(proc, proc_args) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
    idx = idx + 1
  } else {
    ()
  }

  Ok(Value::Nil)
}
