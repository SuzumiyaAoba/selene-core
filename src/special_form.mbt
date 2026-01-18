/// 特殊形式（Special Forms）
///
/// Scheme の特殊形式を実装する。
/// 特殊形式は通常の関数とは異なり、引数を評価する前に処理を行う。

/// if 特殊形式: (if test consequent alternative)
fn eval_if(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(test_expr, SExpr::Pair(consequent, rest)) => {
      // testを評価
      let test_val = match eval(test_expr, env) {
        Ok(v) => v
        Err(e) => return Err(e)
      }

      // #fのみがfalse、それ以外はtrue
      let is_true = match test_val {
        Value::Bool(false) => false
        _ => true
      }

      if is_true {
        eval(consequent, env)
      } else {
        match rest {
          SExpr::Pair(alternative, SExpr::Nil) => eval(alternative, env)
          SExpr::Nil => Ok(Value::Nil) // alternativeが省略された場合
          _ => Err(EvalError::InvalidSyntax("if: invalid syntax"))
        }
      }
    }
    _ => Err(EvalError::InvalidSyntax("if: requires at least 2 arguments"))
  }
}

/// lambda 特殊形式: (lambda (params...) body)
fn eval_lambda(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(params_expr, SExpr::Pair(body, SExpr::Nil)) => {
      // パラメータリストを抽出
      let params = match extract_param_names(params_expr) {
        Ok(p) => p
        Err(e) => return Err(e)
      }

      // クロージャを作成
      Ok(Value::Procedure(Procedure::Closure(params, body, env)))
    }
    _ => Err(EvalError::InvalidSyntax("lambda: requires parameter list and body"))
  }
}

/// パラメータリストからパラメータ名を抽出する。
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

/// define 特殊形式: (define name value)
/// 注: この実装は環境を返せないため、式コンテキストでは使用できません。
/// REPLで特別に処理される必要があります。
fn eval_define(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(
    EvalError::InvalidSyntax(
      "define: not supported in expression context (use REPL)",
    ),
  )
}

/// set! 特殊形式: (set! name value)
/// 注: この実装は環境を返せないため、式コンテキストでは使用できません。
/// REPLで特別に処理される必要があります。
fn eval_set(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(
    EvalError::InvalidSyntax("set!: not supported in expression context (use REPL)"),
  )
}

/// begin 特殊形式: (begin expr...)
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

/// and 特殊形式: (and test...)
/// 短絡評価を行い、最初の偽値を返すか、全て真なら最後の値を返す。
/// 引数がない場合は #t を返す。
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
        // #f のみが偽、それ以外は全て真
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

/// or 特殊形式: (or test...)
/// 短絡評価を行い、最初の真値を返すか、全て偽なら最後の値を返す。
/// 引数がない場合は #f を返す。
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
        // #f のみが偽、それ以外は全て真
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

/// let 特殊形式を評価する。
/// (let ((var1 val1) (var2 val2) ...) body ...)
fn eval_let(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // バインディングリストを解析
      let bindings : Array[Binding] = []
      let mut current = bindings_expr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            // 各バインディングは (var val) の形式
            match binding {
              SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(val_expr, SExpr::Nil)) => {
                // 値を現在の環境で評価
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

      // 新しい環境を作成
      let new_env = extend(env, bindings)

      // ボディを評価
      eval_begin(body, new_env)
    }
    _ => Err(EvalError::InvalidSyntax("let: invalid syntax"))
  }
}

/// let* 特殊形式を評価する。
/// (let* ((var1 val1) (var2 val2) ...) body ...)
fn eval_let_star(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // バインディングを順次評価し、環境を拡張
      let mut current_env = env
      let mut current = bindings_expr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            // 各バインディングは (var val) の形式
            match binding {
              SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(val_expr, SExpr::Nil)) => {
                // 値を現在の環境で評価
                let value = match eval(val_expr, current_env) {
                  Ok(v) => v
                  Err(e) => return Err(e)
                }
                // 環境を拡張（1つずつ）
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

      // ボディを評価
      eval_begin(body, current_env)
    }
    _ => Err(EvalError::InvalidSyntax("let*: invalid syntax"))
  }
}

/// letrec 特殊形式を評価する。
/// (letrec ((var1 val1) (var2 val2) ...) body ...)
///
/// 注: 不変環境での letrec の完全な実装は困難です。
/// この実装では、各バインディングを順次評価し、その時点での環境を次の評価に使用します。
/// これにより、後のバインディングが前のバインディングを参照できます。
fn eval_letrec(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // バインディングリストを解析
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

      // すべての変数を未定義値（Nil）で束縛
      let initial_bindings : Array[Binding] = []
      for name in names {
        initial_bindings.push((name, Value::Nil))
      }
      let mut recursive_env = extend(env, initial_bindings)

      // 各値を順次評価し、環境を更新
      // これにより、クロージャが現在の環境をキャプチャできる
      let mut i = 0
      let len = names.length()
      let _ = while i < len {
        let value = match eval(val_exprs[i], recursive_env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // 環境を更新（この更新された環境が次の評価で使用される）
        recursive_env = define_var(recursive_env, names[i], value)
        i = i + 1
      } else {
        ()
      }

      // ボディを評価
      eval_begin(body, recursive_env)
    }
    _ => Err(EvalError::InvalidSyntax("letrec: invalid syntax"))
  }
}

/// cond 特殊形式を評価する。
/// (cond (test1 expr1 ...) (test2 expr2 ...) ... [(else exprN ...)])
fn eval_cond(clauses : SExpr, env : Env) -> Result[Value, EvalError] {
  let mut current = clauses
  let _ = while true {
    match current {
      SExpr::Nil => {
        // すべての節が偽で、else もない場合
        // R5RS では未定義だが、ここでは未定義値（Nil）を返す
        return Ok(Value::Nil)
      }
      SExpr::Pair(clause, rest) => {
        match clause {
          // else 節: (else expr ...)
          SExpr::Pair(SExpr::Symbol("else"), body) => {
            // else 節は最後でなければならない（ただし、ここでは厳密にチェックしない）
            return eval_begin(body, env)
          }
          // 通常の節: (test expr ...)
          SExpr::Pair(test_expr, body) => {
            // test を評価
            let test_value = match eval(test_expr, env) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            // test が真（#f 以外）かどうかを判定
            let is_true = match test_value {
              Value::Bool(false) => false
              _ => true
            }
            if is_true {
              // body が空の場合、test の値を返す
              match body {
                SExpr::Nil => return Ok(test_value)
                _ => return eval_begin(body, env)
              }
            } else {
              // 次の節へ
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

/// case 特殊形式を評価する。
/// (case key
///   ((datum1 ...) expr1 ...)
///   ((datum2 ...) expr2 ...)
///   (else expr ...))
/// key を評価し、その値を各節の datum リストと eqv? で比較する。
fn eval_case(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(key_expr, clauses) => {
      // key を評価
      let key_value = match eval(key_expr, env) {
        Ok(v) => v
        Err(e) => return Err(e)
      }

      // 各節を順番に処理
      let mut current = clauses
      let _ = while true {
        match current {
          SExpr::Nil => {
            // すべての節がマッチせず、else もない場合
            return Ok(Value::Nil)
          }
          SExpr::Pair(clause, rest) => {
            match clause {
              // else 節: (else expr ...)
              SExpr::Pair(SExpr::Symbol("else"), body) => {
                return eval_begin(body, env)
              }
              // 通常の節: ((datum1 datum2 ...) expr ...)
              SExpr::Pair(datums, body) => {
                // datums リストと key_value を比較
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

/// case の datum リストに key が含まれているかチェックする（eqv? で比較）
fn check_case_datums(key : Value, datums : SExpr) -> Result[Bool, EvalError] {
  let mut current = datums
  let _ = while true {
    match current {
      SExpr::Nil => return Ok(false)
      SExpr::Pair(datum_expr, rest) => {
        // datum は評価せずにそのまま値に変換
        let datum_value = sexpr_to_value(datum_expr)
        // eqv? による比較
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

/// eqv? による値の比較
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

/// delay 特殊形式を評価する。
/// (delay expr) - expr の評価を遅延し、プロミスを返す
fn eval_delay(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(expr, SExpr::Nil) => {
      // プロミスを作成（未評価状態）
      let promise = Promise::{
        forced: { val: false },
        content: { val: PromiseContent::Delayed(expr, env) },
      }
      Ok(Value::Promise(promise))
    }
    _ => Err(EvalError::InvalidSyntax("delay: requires exactly one argument"))
  }
}

/// do 特殊形式を評価する。
/// (do ((var1 init1 step1) (var2 init2 step2) ...)
///     (test expr ...)
///   command ...)
fn eval_do(args : SExpr, env : Env) -> Result[Value, EvalError] {
  match args {
    SExpr::Pair(bindings_expr, SExpr::Pair(test_clause, commands)) => {
      // バインディングリストを解析
      let var_names : Array[String] = []
      let step_exprs : Array[SExpr?] = []
      let init_values : Array[Value] = []

      let parse_result = parse_do_bindings(bindings_expr, env, var_names, step_exprs, init_values)
      match parse_result {
        Err(e) => return Err(e)
        Ok(_) => ()
      }

      // test 節を解析
      let test_expr : SExpr = match test_clause {
        SExpr::Pair(t, _) => t
        _ => return Err(EvalError::InvalidSyntax("do: invalid test clause"))
      }
      let result_exprs : SExpr = match test_clause {
        SExpr::Pair(_, results) => results
        _ => return Err(EvalError::InvalidSyntax("do: invalid test clause"))
      }

      // 初期環境を作成
      let bindings : Array[Binding] = []
      let len = var_names.length()
      let mut i = 0
      while i < len {
        bindings.push((var_names[i], init_values[i]))
        i = i + 1
      }
      let mut loop_env = extend(env, bindings)

      // ループ
      while true {
        // test を評価
        let test_val = match eval(test_expr, loop_env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }

        let is_true = match test_val {
          Value::Bool(false) => false
          _ => true
        }

        if is_true {
          // test が真なら result を評価して返す
          return eval_begin(result_exprs, loop_env)
        }

        // commands を実行
        let cmd_result = eval_do_commands(commands, loop_env)
        match cmd_result {
          Err(e) => return Err(e)
          Ok(_) => ()
        }

        // step 式を評価（並列に）
        let new_values = eval_do_steps(step_exprs, var_names, loop_env)
        match new_values {
          Err(e) => return Err(e)
          Ok(vals) => {
            // 環境を更新
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

/// do のバインディングリストをパースする
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
          // (var init step) の形式
          SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, step_rest)) => {
            var_names.push(name)
            // init を評価
            let init_val = match eval(init_expr, env) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            init_values.push(init_val)
            // step があれば取得
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

/// do の commands を実行する
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

/// do の step 式を評価する
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
        // step がない場合は現在の値を維持
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
