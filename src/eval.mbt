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

    // リスト（関数適用のみ、簡易版）
    SExpr::Pair(car, cdr) => {
      // 演算子を評価
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

/// 初期環境を構築する（組み込み手続きを登録）。
pub fn initial_env() -> Env {
  let env = empty_env()
  let env = define_var(env, "+", Value::Procedure(Procedure::Native("+")))
  let env = define_var(env, "-", Value::Procedure(Procedure::Native("-")))
  let env = define_var(env, "*", Value::Procedure(Procedure::Native("*")))
  let env = define_var(env, "/", Value::Procedure(Procedure::Native("/")))
  env
}
