/// Special Forms
///
/// Implement special forms of Scheme.
/// Special forms differ from regular functions in that they perform processing before evaluating their arguments.

/// if special form: (if test consequent alternative)
fn eval_if(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(test_expr, SExpr::Pair(consequent, rest)) => {
      // evaluate test
      let test_val = match eval(test_expr, env) {
        Ok(v) => v
        Err(e) => return Err(e)
      }

      // Only #f is false, otherwise true
      let is_true = match test_val {
        Value::Bool(false) => false
        _ => true
      }

      if is_true {
        eval(consequent, env)
      } else {
        match rest {
          SExpr::Pair(alternative, SExpr::Nil) => eval(alternative, env)
          SExpr::Nil => Ok(Value::Nil) // If alternative is omitted
          _ => Err(EvalError::InvalidSyntax("if: invalid syntax"))
        }
      }
    }
    _ => Err(EvalError::InvalidSyntax("if: requires at least 2 arguments"))
  }
}

/// lambda special form: (lambda (params...) body)
fn eval_lambda(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(params_expr, SExpr::Pair(body, SExpr::Nil)) => {
      // Extract parameter list
      let params = match extract_param_names(params_expr) {
        Ok(p) => p
        Err(e) => return Err(e)
      }

      // create a closure
      Ok(Value::Procedure(Procedure::Closure(params, body, env)))
    }
    _ => Err(EvalError::InvalidSyntax("lambda: requires parameter list and body"))
  }
}

/// Extract parameter names from parameter list.
fn extract_param_names(params : SExpr) -> Result[Array[String], EvalError] {
  let names : Array[String] = []
  let mut current = params
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(names)
      SExpr::Pair(SExpr::Symbol(name), rest) => {
        names.push(name)
        current = rest
      }
      _ => return Err(EvalError::InvalidSyntax("lambda: invalid parameter list"))
    }
  } else {
    ()
  }
  Ok(names)
}

/// define special form: (define name value)
/// Note: This implementation cannot return an environment, so it cannot be used in an expression context.
/// Must be specially handled in the REPL.
fn eval_define(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(
    EvalError::InvalidSyntax(
      "define: not supported in expression context (use REPL)",
    ),
  )
}

/// set! special form: (set! name value)
/// Note: This implementation cannot return an environment, so it cannot be used in an expression context.
/// Must be specially handled in the REPL.
fn eval_set(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(
    EvalError::InvalidSyntax("set!: not supported in expression context (use REPL)"),
  )
}

/// begin special form: (begin expr...)
fn eval_begin(args : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut current = args
  let mut last_value = Value::Nil
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(last_value)
      SExpr::Pair(expr, rest) => {
        last_value = match eval(expr, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        current = rest
      }
      _ => return Err(EvalError::InvalidSyntax("begin: invalid syntax"))
    }
  } else {
    ()
  }
  Ok(last_value)
}

/// and special form: (and test...)
/// Performs short-circuit evaluation and returns the first false value, or the last value if all are true.
/// Returns #t if there are no arguments.
fn eval_and(args : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut current = args
  let mut last_value = Value::Bool(true)
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(last_value)
      SExpr::Pair(test_expr, rest) => {
        last_value = match eval(test_expr, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // Only #f is false, all others are true
        match last_value {
          Value::Bool(false) => return Ok(Value::Bool(false))
          _ => current = rest
        }
      }
      _ => return Err(EvalError::InvalidSyntax("and: invalid syntax"))
    }
  } else {
    ()
  }
  Ok(last_value)
}

/// or special form: (or test...)
/// Performs a short-circuit evaluation and returns the first true value, or if all are false, returns the last value.
/// Returns #f if there are no arguments.
fn eval_or(args : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut current = args
  let mut last_value = Value::Bool(false)
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(last_value)
      SExpr::Pair(test_expr, rest) => {
        last_value = match eval(test_expr, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // Only #f is false, all others are true
        match last_value {
          Value::Bool(false) => current = rest
          _ => return Ok(last_value)
        }
      }
      _ => return Err(EvalError::InvalidSyntax("or: invalid syntax"))
    }
  } else {
    ()
  }
  Ok(last_value)
}

/// Evaluate the let special form.
/// (let ((var1 val1) (var2 val2) ...) body ...)
fn eval_let(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // Parse binding list
      let bindings : Array[Binding] = []
      let mut current = bindings_expr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            // Each binding is of the form (var val)
            match binding {
              SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(val_expr, SExpr::Nil)) => {
                // Evaluate value in current environment
                let value = match eval(val_expr, env) {
                  Ok(v) => v
                  Err(e) => return Err(e)
                }
                bindings.push((name, value))
                current = rest
              }
              _ => return Err(EvalError::InvalidSyntax("let: invalid binding form"))
            }
          }
          _ => return Err(EvalError::InvalidSyntax("let: bindings must be a list"))
        }
      } else {
        ()
      }

      // Create a new environment
      let new_env = extend(env, bindings)

      // evaluate the body
      eval_begin(body, new_env)
    }
    _ => Err(EvalError::InvalidSyntax("let: invalid syntax"))
  }
}

/// Evaluate the let* special form.
/// (let* ((var1 val1) (var2 val2) ...) body ...)
fn eval_let_star(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // Evaluate bindings sequentially and expand your environment
      let mut current_env = env
      let mut current = bindings_expr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            // Each binding is of the form (var val)
            match binding {
              SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(val_expr, SExpr::Nil)) => {
                // Evaluate value in current environment
                let value = match eval(val_expr, current_env) {
                  Ok(v) => v
                  Err(e) => return Err(e)
                }
                // Extend your environment (one by one)
                current_env = extend(current_env, [(name, value)])
                current = rest
              }
              _ =>
                return Err(EvalError::InvalidSyntax("let*: invalid binding form"))
            }
          }
          _ => return Err(EvalError::InvalidSyntax("let*: bindings must be a list"))
        }
      } else {
        ()
      }

      // evaluate the body
      eval_begin(body, current_env)
    }
    _ => Err(EvalError::InvalidSyntax("let*: invalid syntax"))
  }
}

/// Evaluate the letrec special form.
/// (letrec ((var1 val1) (var2 val2) ...) body ...)
///
/// Note: A complete implementation of letrec in an immutable environment is difficult.
/// This implementation evaluates each binding sequentially and uses the current environment for the next evaluation.
/// This allows later bindings to reference earlier bindings.
fn eval_letrec(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // Parse binding list
      let names : Array[String] = []
      let val_exprs : Array[SExpr] = []

      let mut current = bindings_expr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            match binding {
              SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(val_expr, SExpr::Nil)) => {
                names.push(name)
                val_exprs.push(val_expr)
                current = rest
              }
              _ =>
                return Err(
                  EvalError::InvalidSyntax("letrec: invalid binding form"),
                )
            }
          }
          _ =>
            return Err(EvalError::InvalidSyntax("letrec: bindings must be a list"))
        }
      } else {
        ()
      }

      // Bind all variables with undefined values ​​(Nil)
      let initial_bindings : Array[Binding] = []
      for name in names {
        initial_bindings.push((name, Value::Nil))
      }
      let mut recursive_env = extend(env, initial_bindings)

      // Evaluate each value in turn and update the environment
      // This allows the closure to capture the current environment
      let mut i = 0
      let len = names.length()
      let _ = while i < len {
        let value = match eval(val_exprs[i], recursive_env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // Update the environment (this updated environment will be used in the next evaluation)
        recursive_env = define_var(recursive_env, names[i], value)
        i = i + 1
      } else {
        ()
      }

      // evaluate the body
      eval_begin(body, recursive_env)
    }
    _ => Err(EvalError::InvalidSyntax("letrec: invalid syntax"))
  }
}

/// Evaluate the cond special form.
/// (cond (test1 expr1 ...) (test2 expr2 ...) ... [(else exprN ...)])
fn eval_cond(clauses : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut current = clauses
  let _ = while true {
    match current {
      SExpr::Nil => {
        // If all clauses are false and there is no else
        // Undefined in R5RS, but returns an undefined value (Nil) here
        return Ok(Value::Nil)
      }
      SExpr::Pair(clause, rest) => {
        match clause {
          // else clause: (else expr ...)
          SExpr::Pair(SExpr::Symbol("else"), body) => {
            // else clause must be last (but not strictly checked here)
            return eval_begin(body, env)
          }
          // Regular clause: (test expr ...)
          SExpr::Pair(test_expr, body) => {
            // evaluate test
            let test_value = match eval(test_expr, env) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            // Determine whether test is true (other than #f)
            let is_true = match test_value {
              Value::Bool(false) => false
              _ => true
            }
            if is_true {
              // If body is empty, return the value of test
              match body {
                SExpr::Nil => return Ok(test_value)
                _ => return eval_begin(body, env)
              }
            } else {
              // Next section
              current = rest
            }
          }
          _ => return Err(EvalError::InvalidSyntax("cond: invalid clause"))
        }
      }
      _ => return Err(EvalError::InvalidSyntax("cond: clauses must be a list"))
    }
  } else {
    ()
  }
  Ok(Value::Nil)
}

/// Evaluate the case special form.
/// (case key
///   ((datum1 ...) expr1 ...)
///   ((datum2 ...) expr2 ...)
///   (else expr ...))
/// Evaluate key and compare its value with each clause's datum list using eqv?.
fn eval_case(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(key_expr, clauses) => {
      // evaluate key
      let key_value = match eval(key_expr, env) {
        Ok(v) => v
        Err(e) => return Err(e)
      }

      // Process each clause in turn
      let mut current = clauses
      let _ = while true {
        match current {
          SExpr::Nil => {
            // If all clauses do not match and there is no else
            return Ok(Value::Nil)
          }
          SExpr::Pair(clause, rest) => {
            match clause {
              // else clause: (else expr ...)
              SExpr::Pair(SExpr::Symbol("else"), body) => {
                return eval_begin(body, env)
              }
              // Regular clause: ((datum1 datum2 ...) expr ...)
              SExpr::Pair(datums, body) => {
                // Compare datums list and key_value
                let matched = match check_case_datums(key_value, datums) {
                  Ok(m) => m
                  Err(e) => return Err(e)
                }
                if matched {
                  return eval_begin(body, env)
                } else {
                  current = rest
                }
              }
              _ => return Err(EvalError::InvalidSyntax("case: invalid clause"))
            }
          }
          _ => return Err(EvalError::InvalidSyntax("case: clauses must be a list"))
        }
      } else {
        ()
      }
      Ok(Value::Nil)
    }
    _ => Err(EvalError::InvalidSyntax("case: requires key and clauses"))
  }
}

/// Check if key is included in the datum list of case (compared with eqv?)
fn check_case_datums(key : Value, datums : SExpr) -> Result[Bool, EvalError] {
  let mut current = datums
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(false)
      SExpr::Pair(datum_expr, rest) => {
        // datum is converted to a value without evaluation
        let datum_value = sexpr_to_value(datum_expr)
        // comparison by eqv?
        if values_eqv(key, datum_value) {
          return Ok(true)
        }
        current = rest
      }
      _ => return Err(EvalError::InvalidSyntax("case: datums must be a list"))
    }
  } else {
    ()
  }
  Ok(false)
}

/// Comparing values ​​with eqv?
fn values_eqv(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Real(y))) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    _ => false
  }
}

/// Evaluate the delay special form.
/// (delay expr) - delay evaluation of expr and return a promise
fn eval_delay(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(expr, SExpr::Nil) => {
      // Create promise (unevaluated state)
      let promise = Promise::{
        forced: { val: false },
        content: { val: PromiseContent::Delayed(expr, env) },
      }
      Ok(Value::Promise(promise))
    }
    _ => Err(EvalError::InvalidSyntax("delay: requires exactly one argument"))
  }
}

/// Evaluate the do special form.
/// (do ((var1 init1 step1) (var2 init2 step2) ...)
///     (test expr ...)
///   command ...)
fn eval_do(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, SExpr::Pair(test_clause, commands)) => {
      // Parse binding list
      let var_names : Array[String] = []
      let step_exprs : Array[SExpr?] = []
      let init_values : Array[Value] = []

      let parse_result = parse_do_bindings(bindings_expr, env, var_names, step_exprs, init_values)
      match parse_result {
        Err(e) => return Err(e)
        Ok(_) => ()
      }

      // Parse test clause
      let test_expr : SExpr = match test_clause {
        SExpr::Pair(t, _) => t
        _ => return Err(EvalError::InvalidSyntax("do: invalid test clause"))
      }
      let result_exprs : SExpr = match test_clause {
        SExpr::Pair(_, results) => results
        _ => return Err(EvalError::InvalidSyntax("do: invalid test clause"))
      }

      // Create initial environment
      let bindings : Array[Binding] = []
      let len = var_names.length()
      let mut i = 0
      while i < len {
        bindings.push((var_names[i], init_values[i]))
        i = i + 1
      }
      let mut loop_env = extend(env, bindings)

      // loop
      while true {
        // evaluate test
        let test_val = match eval(test_expr, loop_env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }

        let is_true = match test_val {
          Value::Bool(false) => false
          _ => true
        }

        if is_true {
          // If test is true, evaluate and return result
          return eval_begin(result_exprs, loop_env)
        }

        // run commands
        let cmd_result = eval_do_commands(commands, loop_env)
        match cmd_result {
          Err(e) => return Err(e)
          Ok(_) => ()
        }

        // Evaluate step expressions (in parallel)
        let new_values = eval_do_steps(step_exprs, var_names, loop_env)
        match new_values {
          Err(e) => return Err(e)
          Ok(vals) => {
            // Update environment
            let new_bindings : Array[Binding] = []
            let mut k = 0
            while k < len {
              new_bindings.push((var_names[k], vals[k]))
              k = k + 1
            }
            loop_env = extend(env, new_bindings)
          }
        }
      }

      Ok(Value::Nil)
    }
    _ => Err(EvalError::InvalidSyntax("do: invalid syntax"))
  }
}

/// Parse the binding list of do
fn parse_do_bindings(
  bindings_expr : SExpr,
  env : Env,
  var_names : Array[String],
  step_exprs : Array[SExpr?],
  init_values : Array[Value]
) -> Result[Unit, EvalError] {
  let mut current = bindings_expr
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(binding, rest) => {
        match binding {
          // (var init step) format
          SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, step_rest)) => {
            var_names.push(name)
            // evaluate init
            let init_val = match eval(init_expr, env) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            init_values.push(init_val)
            // Get step if it exists
            match step_rest {
              SExpr::Pair(step_expr, SExpr::Nil) => step_exprs.push(Some(step_expr))
              SExpr::Nil => step_exprs.push(None)
              _ => return Err(EvalError::InvalidSyntax("do: invalid binding"))
            }
            current = rest
          }
          _ => return Err(EvalError::InvalidSyntax("do: invalid binding"))
        }
      }
      _ => return Err(EvalError::InvalidSyntax("do: bindings must be a list"))
    }
  }
  Ok(())
}

/// execute do commands
fn eval_do_commands(commands : SExpr, env : Env) -> Result[Unit, EvalError] {
  let mut cmd = commands
  while true {
    match cmd {
      SExpr::Nil => break
      SExpr::Pair(command, rest) => {
        match eval(command, env) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        cmd = rest
      }
      _ => return Err(EvalError::InvalidSyntax("do: invalid command"))
    }
  }
  Ok(())
}

/// Evaluate the step expression in do
fn eval_do_steps(
  step_exprs : Array[SExpr?],
  var_names : Array[String],
  env : Env
) -> Result[Array[Value], EvalError] {
  let new_values : Array[Value] = []
  let mut j = 0
  let len = step_exprs.length()
  while j < len {
    let new_val = match step_exprs[j] {
      Some(step_expr) => {
        match eval(step_expr, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
      }
      None => {
        // If no step, keep current value
        match lookup(env, var_names[j]) {
          Some(v) => v
          None => return Err(EvalError::UnboundVariable(var_names[j]))
        }
      }
    }
    new_values.push(new_val)
    j = j + 1
  }
  Ok(new_values)
}

/// define-syntax special form: (define-syntax name transformer)
/// Define a macro
/// Note: This implementation cannot return an environment, so it cannot be used in an expression context.
/// Must be specially handled in the REPL.
fn eval_define_syntax(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(
    EvalError::InvalidSyntax(
      "define-syntax: not supported in expression context (use REPL)",
    ),
  )
}

/// let-syntax special form: (let-syntax ((name transformer) ...) body)
/// Define local macros
fn eval_let_syntax(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_sexpr, body_rest) => {
      // Handle binding
      let new_bindings : Array[Binding] = []
      let mut current = bindings_sexpr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            match binding {
              SExpr::Pair(
                SExpr::Symbol(name),
                SExpr::Pair(transformer_expr, SExpr::Nil)
              ) => {
                // Evaluate the transformer in your current environment
                let transformer = match eval(transformer_expr, env) {
                  Ok(Value::Syntax(rules)) => rules
                  Ok(_) =>
                    return Err(
                      EvalError::InvalidSyntax(
                        "let-syntax: transformer must be a syntax-rules",
                      ),
                    )
                  Err(e) => return Err(e)
                }
                new_bindings.push((name, Value::Syntax(transformer)))
              }
              _ =>
                return Err(
                  EvalError::InvalidSyntax(
                    "let-syntax: invalid binding",
                  ),
                )
            }
            current = rest
          }
          _ => return Err(EvalError::InvalidSyntax("let-syntax: invalid bindings list"))
        }
      } else {
        ()
      }

      // Create a new environment
      let new_env = extend(env, new_bindings)

      // Evaluate body (same as begin)
      eval_body(body_rest, new_env)
    }
    _ => Err(EvalError::InvalidSyntax("let-syntax: expected bindings and body"))
  }
}

/// letrec-syntax special form: (letrec-syntax ((name transformer) ...) body)
/// Define recursive local macros
fn eval_letrec_syntax(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_sexpr, body_rest) => {
      // First create a new environment (bind with undefined value)
      let binding_names : Array[String] = []
      let transformer_exprs : Array[SExpr] = []
      let mut current = bindings_sexpr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            match binding {
              SExpr::Pair(
                SExpr::Symbol(name),
                SExpr::Pair(transformer_expr, SExpr::Nil)
              ) => {
                binding_names.push(name)
                transformer_exprs.push(transformer_expr)
              }
              _ =>
                return Err(
                  EvalError::InvalidSyntax(
                    "letrec-syntax: invalid binding",
                  ),
                )
            }
            current = rest
          }
          _ =>
            return Err(EvalError::InvalidSyntax("letrec-syntax: invalid bindings list"))
        }
      } else {
        ()
      }

      // Create new environment with undefined values
      let placeholder_bindings : Array[Binding] = []
      for name in binding_names {
        placeholder_bindings.push((name, Value::Nil))
      }
      let new_env = extend(env, placeholder_bindings)

      // Evaluate transformers in new environment and update frames directly
      let mut i = 0
      let len = binding_names.length()
      let _ = while i < len {
        let transformer = match eval(transformer_exprs[i], new_env) {
          Ok(Value::Syntax(rules)) => rules
          Ok(_) =>
            return Err(
              EvalError::InvalidSyntax(
                "letrec-syntax: transformer must be a syntax-rules",
              ),
            )
          Err(e) => return Err(e)
        }
        // Update frame directly
        new_env.frame[i] = (binding_names[i], Value::Syntax(transformer))
        i = i + 1
      } else {
        ()
      }

      // evaluate the body
      eval_body(body_rest, new_env)
    }
    _ => Err(EvalError::InvalidSyntax("letrec-syntax: expected bindings and body"))
  }
}

/// Evaluate the body (list of expressions) and return the value of the last expression
fn eval_body(body : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut result = Value::Nil
  let mut current = body
  let _ = while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(expr, rest) => {
        result = match eval(expr, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        current = rest
      }
      _ => return Err(EvalError::InvalidSyntax("invalid body"))
    }
  } else {
    ()
  }
  Ok(result)
}

/// load special form: (load "filename")
/// Load and evaluate the file.
/// Note: define has limitations that are not reflected in the current environment.
fn eval_load(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(filename_expr, SExpr::Nil) => {
      // Evaluate file name
      let filename = match eval(filename_expr, env) {
        Ok(Value::String(s)) => s
        Ok(_) => return Err(EvalError::TypeError("load: expected string filename"))
        Err(e) => return Err(e)
      }
      // Check if file exists
      if not(file_exists(filename)) {
        return Err(EvalError::TypeError("load: cannot open file: " + filename))
      }
      // load file
      let content = read_file(filename)
      if content.length() == 0 {
        return Err(EvalError::TypeError("load: cannot read file: " + filename))
      }
      // Parse and convert to list of expressions
      let exprs = parse(content)
      // Evaluate each expression in turn (while changing env)
      let mut current_env = env
      let mut result = Value::Nil
      let len = exprs.length()
      let mut i = 0
      while i < len {
        let expr = exprs[i]
        // Special handling of define
        match expr {
          SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
            match eval(value_expr, current_env) {
              Ok(value) => {
                current_env = define_var(current_env, name, value)
                result = Value::Nil
              }
              Err(e) => return Err(e)
            }
          }
          SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Pair(name_expr, params), SExpr::Pair(body, SExpr::Nil))) => {
            // (define (name params...) body) format
            match name_expr {
              SExpr::Symbol(name) => {
                let param_names = match extract_param_names(params) {
                  Ok(p) => p
                  Err(e) => return Err(e)
                }
                let closure = Value::Procedure(Procedure::Closure(param_names, body, current_env))
                current_env = define_var(current_env, name, closure)
                result = Value::Nil
              }
              _ => return Err(EvalError::InvalidSyntax("load: invalid define syntax"))
            }
          }
          _ => {
            match eval(expr, current_env) {
              Ok(v) => result = v
              Err(e) => return Err(e)
            }
          }
        }
        i = i + 1
      }
      Ok(result)
    }
    _ => Err(EvalError::InvalidSyntax("load: requires exactly 1 argument"))
  }
}
