/// Scheme 評価器の中核実装。

/// 評価エラーを表す型。
pub(all) enum EvalError {
  UnboundVariable(String)
  InvalidSyntax(String)
  TypeError(String)
  ArityError(String)
} derive(Show)

/// SExpr を Value に変換（評価せずに変換）。
fn sexpr_to_value(sexpr : SExpr) -> Value {
  match sexpr {
    SExpr::Nil => Value::Nil
    SExpr::Symbol(name) => Value::Symbol(name)
    SExpr::Number(n) => Value::Number(Number::Int(n))
    SExpr::Pair(car, cdr) =>
      Value::Pair(sexpr_to_value(car), sexpr_to_value(cdr))
    SExpr::Vector(items) => {
      let values : Array[Value] = []
      for item in items {
        values.push(sexpr_to_value(item))
      }
      Value::Vector(values)
    }
    SExpr::Quote(expr) => sexpr_to_value(expr)
    SExpr::Quasiquote(_) | SExpr::Unquote(_) | SExpr::UnquoteSplicing(_) =>
      panic()  // quasiquote 展開は別途実装予定
  }
}

/// S 式を評価する（最小実装）。
pub fn eval(expr : SExpr, env : Env) -> Result[Value, EvalError] {
  match expr {
    // 自己評価式
    SExpr::Number(n) => Ok(Value::Number(Number::Int(n)))

    // 変数参照
    SExpr::Symbol(name) => {
      match lookup(env, name) {
        Some(value) => Ok(value)
        None => Err(EvalError::UnboundVariable(name))
      }
    }

    // quote
    SExpr::Quote(quoted) => Ok(sexpr_to_value(quoted))

    // 空リスト
    SExpr::Nil => Ok(Value::Nil)

    // リスト（特殊形式または関数適用）
    SExpr::Pair(car, cdr) => {
      // 特殊形式のチェック
      match car {
        SExpr::Symbol("if") => eval_if(cdr, env)
        SExpr::Symbol("lambda") => eval_lambda(cdr, env)
        SExpr::Symbol("define") => eval_define(cdr, env)
        SExpr::Symbol("begin") => eval_begin(cdr, env)
        SExpr::Symbol("quote") => {
          // quote特殊形式: (quote expr)
          match cdr {
            SExpr::Pair(quoted, SExpr::Nil) => Ok(sexpr_to_value(quoted))
            _ => Err(EvalError::InvalidSyntax("quote: requires exactly one argument"))
          }
        }
        _ => {
          // 通常の関数適用
          let op = match eval(car, env) {
            Ok(v) => v
            Err(e) => return Err(e)
          }

          // 引数リストを取得
          let args : Array[Value] = []
          let mut current = cdr
          let _ = while true {
            match current {
              SExpr::Nil => break
              SExpr::Pair(arg_expr, rest) => {
                let arg_val = match eval(arg_expr, env) {
                  Ok(v) => v
                  Err(e) => return Err(e)
                }
                args.push(arg_val)
                current = rest
              }
              _ => return Err(EvalError::InvalidSyntax("improper list in application"))
            }
          } else { () }

          // 適用
          apply(op, args)
        }
      }
    }

    // Vector（自己評価）
    SExpr::Vector(_) => Ok(sexpr_to_value(expr))

    // その他の quote 系は TODO
    SExpr::Quasiquote(_) | SExpr::Unquote(_) | SExpr::UnquoteSplicing(_) =>
      Err(EvalError::InvalidSyntax("quasiquote: not yet implemented"))
  }
}

/// 手続きを引数に適用する。
pub fn apply(proc : Value, args : Array[Value]) -> Result[Value, EvalError] {
  match proc {
    Value::Procedure(Procedure::Native(name)) => {
      apply_builtin(name, args)
    }
    Value::Procedure(Procedure::Closure(params, body, closure_env)) => {
      // パラメータ数のチェック
      if params.length() != args.length() {
        return Err(EvalError::ArityError("closure: arity mismatch"))
      }

      // パラメータと引数を束縛
      let bindings : Array[Binding] = []
      let mut i = 0
      let len = params.length()
      let _ = while i < len {
        bindings.push((params[i], args[i]))
        i = i + 1
      } else { () }

      // 新しい環境で本体を評価
      let new_env = extend(closure_env, bindings)
      eval(body, new_env)
    }
    _ => Err(EvalError::TypeError("not a procedure"))
  }
}

/// 組み込み手続きを適用する。
fn apply_builtin(name : String, args : Array[Value]) -> Result[Value, EvalError] {
  match name {
    "+" => builtin_add(args)
    "-" => builtin_sub(args)
    "*" => builtin_mul(args)
    "/" => builtin_div(args)
    _ => Err(EvalError::InvalidSyntax("unknown builtin: " + name))
  }
}

/// 数値を取り出す補助関数。
fn expect_number(value : Value) -> Result[Number, EvalError] {
  match value {
    Value::Number(n) => Ok(n)
    _ => Err(EvalError::TypeError("expected number"))
  }
}

/// 整数演算（簡易版）。
fn add_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x + y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x + y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() + y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x + y.to_double())
  }
}

fn sub_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x - y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x - y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() - y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x - y.to_double())
  }
}

fn mul_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x * y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x * y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() * y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x * y.to_double())
  }
}

fn div_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(x / y)
    (Number::Real(x), Number::Real(y)) => Number::Real(x / y)
    (Number::Int(x), Number::Real(y)) => Number::Real(x.to_double() / y)
    (Number::Real(x), Number::Int(y)) => Number::Real(x / y.to_double())
  }
}

/// 組み込み関数: +
fn builtin_add(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(0)))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = add_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
}

/// 組み込み関数: -
fn builtin_sub(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("-: requires at least 1 argument"))
  }
  if args.length() == 1 {
    let num = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    return Ok(Value::Number(match num {
      Number::Int(x) => Number::Int(-x)
      Number::Real(x) => Number::Real(-x)
    }))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = sub_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
}

/// 組み込み関数: *
fn builtin_mul(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(1)))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = mul_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
}

/// 組み込み関数: /
fn builtin_div(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("/: requires at least 1 argument"))
  }
  if args.length() == 1 {
    let num = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    return Ok(Value::Number(match num {
      Number::Int(x) => Number::Int(1 / x)
      Number::Real(x) => Number::Real(1.0 / x)
    }))
  }
  let mut result = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let num = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    result = div_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
}

/// if 特殊形式: (if test consequent [alternative])
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
          SExpr::Nil => Ok(Value::Nil)  // alternativeが省略された場合
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
  } else { () }
  Ok(names)
}

/// define 特殊形式: (define name value)
/// 注: この実装は環境を返せないため、式コンテキストでは使用できません。
/// REPLで特別に処理される必要があります。
fn eval_define(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(EvalError::InvalidSyntax("define: not supported in expression context (use REPL)"))
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
  } else { () }
  Ok(last_value)
}

/// 初期環境を構築する（組み込み手続きを登録）。
pub fn initial_env() -> Env {
  let env = empty_env()
  let env = define_var(env, "+", Value::Procedure(Procedure::Native("+")))
  let env = define_var(env, "-", Value::Procedure(Procedure::Native("-")))
  let env = define_var(env, "*", Value::Procedure(Procedure::Native("*")))
  let env = define_var(env, "/", Value::Procedure(Procedure::Native("/")))
  env
}
