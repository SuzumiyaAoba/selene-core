/// Control flow built-in functions
///
/// Implement the control flow operation of the Scheme.

/// Built-in function: call/cc (call-with-current-continuation)
/// (call/cc proc) - captures the current continuation and passes it to proc
fn builtin_call_cc(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("call/cc: requires exactly 1 argument"))
  }

  // Argument must be a one-argument procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => {
      // Create a new continuation
      let cont_id = new_continuation_id()
      let cont = Value::Procedure(Procedure::Cont({ id: cont_id }))

      // Invoke by passing a continuation to the process
      let result = apply(proc, [cont])

      // Process Results
      match result {
        Ok(value) => Ok(value)
        Err(EvalError::ContinuationInvoked(id, value)) => {
          // If the continuation of this call/cc is called
          if id == cont_id {
            Ok(value)
          } else {
            // Propagate if another continuation is called
            Err(EvalError::ContinuationInvoked(id, value))
          }
        }
        Err(e) => Err(e)
      }
    }
    _ => Err(EvalError::TypeError("call/cc: argument must be a procedure"))
  }
}

/// Built-in functions: apply
/// (apply proc arg1... argN args) - args must be a list
fn builtin_apply(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("apply: requires at least 2 arguments"))
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("apply: first argument must be a procedure"),
      )
  }

  // Last argument must be a list
  let last_arg = args[args.length() - 1]
  let last_list_items = match list_to_array(last_arg) {
    Ok(items) => items
    Err(e) => return Err(e)
  }

  // Merge intermediate arguments with the last list element
  let combined_args : Array[Value] = []
  // Added intermediate arguments (args [1] to args [length-2])
  let mut i = 1
  let last_idx = args.length() - 1
  let _ = while i < last_idx {
    combined_args.push(args[i])
    i = i + 1
  } else {
    ()
  }
  // Add last list element
  for item in last_list_items {
    combined_args.push(item)
  }

  // Apply Procedure
  apply(proc, combined_args)
}

/// Built-in functions: map
/// (map proc list1 list2...) - applies proc to the corresponding element of each list and returns a list of results
fn builtin_map(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("map: requires at least 2 arguments"))
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(EvalError::TypeError("map: first argument must be a procedure"))
  }

  // All remaining arguments must be in the list
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

  // Check if all lists are the same length (simplified version: use the length of the first list)
  if lists.length() == 0 {
    return Ok(Value::Nil)
  }
  let list_len = lists[0].length()

  // Build results list
  let results : Array[Value] = []
  let mut idx = 0
  let _ = while idx < list_len {
    // Get idx th element from each list
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

    // Apply Procedure
    let result = match apply(proc, proc_args) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    results.push(result)
    idx = idx + 1
  } else {
    ()
  }

  // Convert Array to List
  array_to_list(results)
}

/// Built-in functions: for-each
/// (for - each proc list 1 list 2...) - apply proc to the corresponding element of each list (due to side effects)
fn builtin_for_each(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("for-each: requires at least 2 arguments"))
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("for-each: first argument must be a procedure"),
      )
  }

  // All remaining arguments must be in the list
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

/// Built-in functions: filter
/// (filter proc list) - Returns a list containing only elements for which proc returns true
fn builtin_filter(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("filter: requires exactly 2 arguments"))
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("filter: first argument must be a procedure"),
      )
  }

  // The second argument must be a list
  let list_items = match list_to_array(args[1]) {
    Ok(items) => items
    Err(e) => return Err(e)
  }

  // Build results list
  let results : Array[Value] = []
  for item in list_items {
    // Apply procedures to each element
    let result = match apply(proc, [item]) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    // Add to results only if true (all but # f are true)
    match result {
      Value::Bool(false) => ()
      _ => results.push(item)
    }
  }

  // Convert Array to List
  array_to_list(results)
}

/// Built-in functions: fold-left
/// (fold-left proc init list) - convolve list from left
fn builtin_fold_left(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(EvalError::ArityError("fold-left: requires exactly 3 arguments"))
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("fold-left: first argument must be a procedure"),
      )
  }

  let init = args[1]

  // The third argument must be a list
  let list_items = match list_to_array(args[2]) {
    Ok(items) => items
    Err(e) => return Err(e)
  }

  // Convolve from left: (proc (proc init e1) e2) e3)...
  let mut acc = init
  for item in list_items {
    acc = match apply(proc, [acc, item]) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  }

  Ok(acc)
}

/// Built-in function: fold-right
/// (fold-right proc init list) - convolve list from right
fn builtin_fold_right(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(
      EvalError::ArityError("fold-right: requires exactly 3 arguments"),
    )
  }

  // The first argument must be a procedure
  let proc = args[0]
  match proc {
    Value::Procedure(_) => ()
    _ =>
      return Err(
        EvalError::TypeError("fold-right: first argument must be a procedure"),
      )
  }

  let init = args[1]

  // The third argument must be a list
  let list_items = match list_to_array(args[2]) {
    Ok(items) => items
    Err(e) => return Err(e)
  }

  // Convolve from right: (proc e1 (proc e2 (proc e3 init)))...
  let mut acc = init
  let mut i = list_items.length()
  let _ = while i > 0 {
    i = i - 1
    acc = match apply(proc, [list_items[i], acc]) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  } else {
    ()
  }

  Ok(acc)
}

/// Built-in function: force
/// (force promise) - Force evaluate the promise and return the result
fn builtin_force(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("force: requires exactly 1 argument"))
  }

  match args[0] {
    Value::Promise(promise) => {
      // Check if you've already rated it
      if promise.forced.val {
        match promise.content.val {
          PromiseContent::Forced(value) => Ok(value)
          _ => Err(EvalError::InvalidSyntax("force: invalid promise state"))
        }
      } else {
        // Evaluate because it is unrated
        match promise.content.val {
          PromiseContent::Delayed(expr, env) => {
            let result = match eval(expr, env) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            // Memoize: Save Result
            promise.forced.val = true
            promise.content.val = PromiseContent::Forced(result)
            Ok(result)
          }
          PromiseContent::VMDelayed(closure) => {
            let result = match vm_apply_closure(closure, []) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            // Memoize: Save Result
            promise.forced.val = true
            promise.content.val = PromiseContent::Forced(result)
            Ok(result)
          }
          _ => Err(EvalError::InvalidSyntax("force: invalid promise state"))
        }
      }
    }
    // Returns the value other than the promise as it is (R5RS operation)
    other => Ok(other)
  }
}

/// Built-in function: promise?
/// (promise? obj) - Determine if obj is a Promise
fn builtin_promise_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("promise?: requires exactly 1 argument"))
  }

  match args[0] {
    Value::Promise(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// Built-in functions: values
/// (values obj...) - returns multiple values
fn builtin_values(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 1 {
    // Returns as is for a single value
    Ok(args[0])
  } else {
    // For multiple values, wrap with MultipleValues
    Ok(Value::MultipleValues(args))
  }
}

/// Built-in function: dynamic-wind
/// (dynamic-wind before thunk after) - Perform dynamic input/output processing
fn builtin_dynamic_wind(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(
      EvalError::ArityError("dynamic-wind: requires exactly 3 arguments"),
    )
  }

  // All arguments must be procedural
  let before = args[0]
  let thunk = args[1]
  let after = args[2]
  match (before, thunk, after) {
    (Value::Procedure(_), Value::Procedure(_), Value::Procedure(_)) => ()
    _ =>
      return Err(
        EvalError::TypeError("dynamic-wind: all arguments must be procedures"),
      )
  }

  // call before
  match apply(before, []) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }

  // call thunk
  let result = apply(thunk, [])

  // call after (whether thunk succeeds or fails)
  match apply(after, []) {
    Ok(_) => ()
    Err(e) => {
      // if an error occurs after, return it
      // Note: R5RS should prioritize thunk errors, but simplified implementation
      return Err(e)
    }
  }

  // returns the result of a thunk
  result
}

/// Built-in functions: call-with-values
/// (call-with-values producer consumer) - Pass the producer's result to the consumer
fn builtin_call_with_values(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(
      EvalError::ArityError("call-with-values: requires exactly 2 arguments"),
    )
  }

  // Both arguments must be procedural
  let producer = args[0]
  let consumer = args[1]
  match (producer, consumer) {
    (Value::Procedure(_), Value::Procedure(_)) => ()
    _ =>
      return Err(
        EvalError::TypeError("call-with-values: both arguments must be procedures"),
      )
  }

  // call producer without arguments
  let produced = match apply(producer, []) {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  // pass the results of the producer to the consumer
  match produced {
    Value::MultipleValues(values) => {
      // Pass multiple values as arguments to consumer
      apply(consumer, values)
    }
    single_value => {
      // Pass a single value to consumer
      apply(consumer, [single_value])
    }
  }
}
