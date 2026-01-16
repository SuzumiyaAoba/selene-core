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
    SExpr::Bool(b) => Value::Bool(b)
    SExpr::Symbol(name) => Value::Symbol(name)
    SExpr::Number(n) => Value::Number(Number::Int(n))
    SExpr::Char(c) => Value::Char(c)
    SExpr::String(s) => Value::String(s)
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
    SExpr::Quasiquote(expr) => Value::Pair(
      Value::Symbol("quasiquote"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
    SExpr::Unquote(expr) => Value::Pair(
      Value::Symbol("unquote"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
    SExpr::UnquoteSplicing(expr) => Value::Pair(
      Value::Symbol("unquote-splicing"),
      Value::Pair(sexpr_to_value(expr), Value::Nil)
    )
  }
}

/// quasiquote 式を展開する。
/// depth はネストレベルを表す（0 = トップレベル）
fn expand_quasiquote(
  sexpr : SExpr,
  env : Env,
  depth : Int
) -> Result[Value, EvalError] {
  match sexpr {
    // unquote: depth が 0 なら評価、そうでなければ再帰
    SExpr::Unquote(inner) =>
      if depth == 0 {
        eval(inner, env)
      } else {
        match expand_quasiquote(inner, env, depth - 1) {
          Ok(expanded) =>
            Ok(Value::Pair(Value::Symbol("unquote"), Value::Pair(expanded, Value::Nil)))
          Err(e) => Err(e)
        }
      }
    // unquote-splicing: depth が 0 ならエラー（リストコンテキスト外）
    SExpr::UnquoteSplicing(_) =>
      if depth == 0 {
        Err(EvalError::InvalidSyntax("unquote-splicing: not in list context"))
      } else {
        match sexpr {
          SExpr::UnquoteSplicing(inner) => {
            match expand_quasiquote(inner, env, depth - 1) {
              Ok(expanded) =>
                Ok(Value::Pair(Value::Symbol("unquote-splicing"), Value::Pair(expanded, Value::Nil)))
              Err(e) => Err(e)
            }
          }
          _ => panic()
        }
      }
    // ネストした quasiquote
    SExpr::Quasiquote(inner) => {
      match expand_quasiquote(inner, env, depth + 1) {
        Ok(expanded) =>
          Ok(Value::Pair(Value::Symbol("quasiquote"), Value::Pair(expanded, Value::Nil)))
        Err(e) => Err(e)
      }
    }
    // リスト: 各要素を処理
    SExpr::Pair(car, cdr) => expand_quasiquote_list(car, cdr, env, depth)
    // quote: 中身を変換
    SExpr::Quote(inner) =>
      Ok(Value::Pair(Value::Symbol("quote"), Value::Pair(sexpr_to_value(inner), Value::Nil)))
    // アトム: そのまま変換
    _ => Ok(sexpr_to_value(sexpr))
  }
}

/// リストの quasiquote 展開（unquote-splicing 対応）
fn expand_quasiquote_list(
  car : SExpr,
  cdr : SExpr,
  env : Env,
  depth : Int
) -> Result[Value, EvalError] {
  // car が unquote-splicing の場合
  match car {
    SExpr::UnquoteSplicing(inner) =>
      if depth == 0 {
        // 評価してスプライス
        let spliced = match eval(inner, env) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // cdr を展開
        let rest = match expand_quasiquote(cdr, env, depth) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        // spliced を rest の前に追加
        append_values(spliced, rest)
      } else {
        // depth > 0 の場合は構造を保持
        let expanded_inner = match expand_quasiquote(inner, env, depth - 1) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let expanded_cdr = match expand_quasiquote(cdr, env, depth) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        Ok(Value::Pair(
          Value::Pair(Value::Symbol("unquote-splicing"), Value::Pair(expanded_inner, Value::Nil)),
          expanded_cdr
        ))
      }
    _ => {
      // 通常の要素
      let expanded_car = match expand_quasiquote(car, env, depth) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let expanded_cdr = match expand_quasiquote(cdr, env, depth) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      Ok(Value::Pair(expanded_car, expanded_cdr))
    }
  }
}

/// 2 つの Value リストを連結する。
fn append_values(list1 : Value, list2 : Value) -> Result[Value, EvalError] {
  match list1 {
    Value::Nil => Ok(list2)
    Value::Pair(car, cdr) => {
      match append_values(cdr, list2) {
        Ok(rest) => Ok(Value::Pair(car, rest))
        Err(e) => Err(e)
      }
    }
    _ => Err(EvalError::TypeError("unquote-splicing: expected list"))
  }
}

/// S 式を評価する（最小実装）。
pub fn eval(expr : SExpr, env : Env) -> Result[Value, EvalError] {
  match expr {
    // 自己評価式
    SExpr::Number(n) => Ok(Value::Number(Number::Int(n)))
    SExpr::Bool(b) => Ok(Value::Bool(b))
    SExpr::Char(c) => Ok(Value::Char(c))
    SExpr::String(s) => Ok(Value::String(s))

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
        SExpr::Symbol("set!") => eval_set(cdr, env)
        SExpr::Symbol("begin") => eval_begin(cdr, env)
        SExpr::Symbol("and") => eval_and(cdr, env)
        SExpr::Symbol("or") => eval_or(cdr, env)
        SExpr::Symbol("let") => eval_let(cdr, env)
        SExpr::Symbol("let*") => eval_let_star(cdr, env)
        SExpr::Symbol("letrec") => eval_letrec(cdr, env)
        SExpr::Symbol("cond") => eval_cond(cdr, env)
        SExpr::Symbol("quote") => {
          // quote特殊形式: (quote expr)
          match cdr {
            SExpr::Pair(quoted, SExpr::Nil) => Ok(sexpr_to_value(quoted))
            _ => Err(EvalError::InvalidSyntax("quote: requires exactly one argument"))
          }
        }
        SExpr::Symbol("quasiquote") => {
          // quasiquote特殊形式: (quasiquote expr)
          match cdr {
            SExpr::Pair(inner, SExpr::Nil) => expand_quasiquote(inner, env, 0)
            _ => Err(EvalError::InvalidSyntax("quasiquote: requires exactly one argument"))
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

    // quasiquote 展開
    SExpr::Quasiquote(inner) => expand_quasiquote(inner, env, 0)

    // unquote/unquote-splicing は quasiquote 外で使用された場合エラー
    SExpr::Unquote(_) =>
      Err(EvalError::InvalidSyntax("unquote: not in quasiquote"))
    SExpr::UnquoteSplicing(_) =>
      Err(EvalError::InvalidSyntax("unquote-splicing: not in quasiquote"))
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
    "quotient" => builtin_quotient(args)
    "remainder" => builtin_remainder(args)
    "modulo" => builtin_modulo(args)
    "abs" => builtin_abs(args)
    "max" => builtin_max(args)
    "min" => builtin_min(args)
    "cons" => builtin_cons(args)
    "car" => builtin_car(args)
    "cdr" => builtin_cdr(args)
    "pair?" => builtin_pair_p(args)
    "number?" => builtin_number_p(args)
    "boolean?" => builtin_boolean_p(args)
    "symbol?" => builtin_symbol_p(args)
    "null?" => builtin_null_p(args)
    "=" => builtin_num_eq(args)
    "<" => builtin_lt(args)
    ">" => builtin_gt(args)
    "<=" => builtin_le(args)
    ">=" => builtin_ge(args)
    "eq?" => builtin_eq_p(args)
    "not" => builtin_not(args)
    "apply" => builtin_apply(args)
    "map" => builtin_map(args)
    "for-each" => builtin_for_each(args)
    "list" => builtin_list(args)
    "length" => builtin_length(args)
    "append" => builtin_append(args)
    "reverse" => builtin_reverse(args)
    "list-ref" => builtin_list_ref(args)
    "list-tail" => builtin_list_tail(args)
    "string?" => builtin_string_p(args)
    "char?" => builtin_char_p(args)
    "string-length" => builtin_string_length(args)
    "string-ref" => builtin_string_ref(args)
    "string-append" => builtin_string_append(args)
    "string=?" => builtin_string_eq(args)
    "make-string" => builtin_make_string(args)
    "substring" => builtin_substring(args)
    "vector?" => builtin_vector_p(args)
    "make-vector" => builtin_make_vector(args)
    "vector" => builtin_vector(args)
    "vector-length" => builtin_vector_length(args)
    "vector-ref" => builtin_vector_ref(args)
    "vector-set!" => builtin_vector_set(args)
    "vector->list" => builtin_vector_to_list(args)
    "list->vector" => builtin_list_to_vector(args)
    "floor" => builtin_floor(args)
    "ceiling" => builtin_ceiling(args)
    "truncate" => builtin_truncate(args)
    "round" => builtin_round(args)
    "sqrt" => builtin_sqrt(args)
    "expt" => builtin_expt(args)
    "exact?" => builtin_exact_p(args)
    "inexact?" => builtin_inexact_p(args)
    "number->string" => builtin_number_to_string(args)
    "sin" => builtin_sin(args)
    "cos" => builtin_cos(args)
    "tan" => builtin_tan(args)
    "asin" => builtin_asin(args)
    "acos" => builtin_acos(args)
    "atan" => builtin_atan(args)
    "exp" => builtin_exp(args)
    "log" => builtin_log(args)
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

fn max_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(if x > y { x } else { y })
    (Number::Real(x), Number::Real(y)) => Number::Real(if x > y { x } else { y })
    (Number::Int(x), Number::Real(y)) => {
      let x_real = x.to_double()
      Number::Real(if x_real > y { x_real } else { y })
    }
    (Number::Real(x), Number::Int(y)) => {
      let y_real = y.to_double()
      Number::Real(if x > y_real { x } else { y_real })
    }
  }
}

fn min_numbers(a : Number, b : Number) -> Number {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => Number::Int(if x < y { x } else { y })
    (Number::Real(x), Number::Real(y)) => Number::Real(if x < y { x } else { y })
    (Number::Int(x), Number::Real(y)) => {
      let x_real = x.to_double()
      Number::Real(if x_real < y { x_real } else { y })
    }
    (Number::Real(x), Number::Int(y)) => {
      let y_real = y.to_double()
      Number::Real(if x < y_real { x } else { y_real })
    }
  }
}

/// 数値比較の補助関数
fn compare_numbers_equal(a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => x == y
    (Number::Real(x), Number::Real(y)) => x == y
    (Number::Int(x), Number::Real(y)) => x.to_double() == y
    (Number::Real(x), Number::Int(y)) => x == y.to_double()
  }
}

fn compare_numbers_less(a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => x < y
    (Number::Real(x), Number::Real(y)) => x < y
    (Number::Int(x), Number::Real(y)) => x.to_double() < y
    (Number::Real(x), Number::Int(y)) => x < y.to_double()
  }
}

fn compare_numbers_greater(a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => x > y
    (Number::Real(x), Number::Real(y)) => x > y
    (Number::Int(x), Number::Real(y)) => x.to_double() > y
    (Number::Real(x), Number::Int(y)) => x > y.to_double()
  }
}

fn compare_numbers_less_or_equal(a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => x <= y
    (Number::Real(x), Number::Real(y)) => x <= y
    (Number::Int(x), Number::Real(y)) => x.to_double() <= y
    (Number::Real(x), Number::Int(y)) => x <= y.to_double()
  }
}

fn compare_numbers_greater_or_equal(a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => x >= y
    (Number::Real(x), Number::Real(y)) => x >= y
    (Number::Int(x), Number::Real(y)) => x.to_double() >= y
    (Number::Real(x), Number::Int(y)) => x >= y.to_double()
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

/// 組み込み関数: quotient
fn builtin_quotient(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("quotient: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("quotient: division by zero"))
      }
      Ok(Value::Number(Number::Int(x / y)))
    }
    _ => Err(EvalError::TypeError("quotient: requires integer arguments"))
  }
}

/// 組み込み関数: remainder
fn builtin_remainder(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("remainder: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("remainder: division by zero"))
      }
      Ok(Value::Number(Number::Int(x % y)))
    }
    _ => Err(EvalError::TypeError("remainder: requires integer arguments"))
  }
}

/// 組み込み関数: modulo
fn builtin_modulo(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("modulo: requires exactly 2 arguments"))
  }
  let a = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let b = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      if y == 0 {
        return Err(EvalError::TypeError("modulo: division by zero"))
      }
      let r = x % y
      // Scheme modulo: result has same sign as divisor
      let result = if (r > 0 && y < 0) || (r < 0 && y > 0) {
        r + y
      } else {
        r
      }
      Ok(Value::Number(Number::Int(result)))
    }
    _ => Err(EvalError::TypeError("modulo: requires integer arguments"))
  }
}

/// 組み込み関数: abs
fn builtin_abs(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("abs: requires exactly 1 argument"))
  }
  let num = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  Ok(Value::Number(match num {
    Number::Int(x) => Number::Int(if x < 0 { -x } else { x })
    Number::Real(x) => Number::Real(if x < 0.0 { -x } else { x })
  }))
}

/// 組み込み関数: max
fn builtin_max(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("max: requires at least 1 argument"))
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
    result = max_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
}

/// 組み込み関数: min
fn builtin_min(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Err(EvalError::ArityError("min: requires at least 1 argument"))
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
    result = min_numbers(result, num)
    i = i + 1
  } else { () }
  Ok(Value::Number(result))
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
  } else { () }
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
      _ => return Err(EvalError::TypeError("length: argument must be a proper list"))
    }
  } else { () }
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
  } else { () }

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
  } else { () }

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
      _ => return Err(EvalError::TypeError("reverse: argument must be a proper list"))
    }
  } else { () }
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
  } else { () }

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
  } else { () }

  Ok(current)
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

/// set! 特殊形式: (set! name value)
/// 注: この実装は環境を返せないため、式コンテキストでは使用できません。
/// REPLで特別に処理される必要があります。
fn eval_set(_args : SExpr, _env : Env) -> Result[Value, EvalError] {
  Err(EvalError::InvalidSyntax("set!: not supported in expression context (use REPL)"))
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

/// 組み込み関数: null?
fn builtin_null_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("null?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Nil => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: pair?
fn builtin_pair_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("pair?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Pair(_, _) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: number?
fn builtin_number_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("number?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: boolean?
fn builtin_boolean_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("boolean?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Bool(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 数値比較の補助関数
fn compare_numbers(op : String, a : Number, b : Number) -> Bool {
  match (a, b) {
    (Number::Int(x), Number::Int(y)) => {
      match op {
        "=" => x == y
        "<" => x < y
        ">" => x > y
        "<=" => x <= y
        ">=" => x >= y
        _ => false
      }
    }
    (Number::Real(x), Number::Real(y)) => {
      match op {
        "=" => x == y
        "<" => x < y
        ">" => x > y
        "<=" => x <= y
        ">=" => x >= y
        _ => false
      }
    }
    (Number::Int(x), Number::Real(y)) => {
      let xd = x.to_double()
      match op {
        "=" => xd == y
        "<" => xd < y
        ">" => xd > y
        "<=" => xd <= y
        ">=" => xd >= y
        _ => false
      }
    }
    (Number::Real(x), Number::Int(y)) => {
      let yd = y.to_double()
      match op {
        "=" => x == yd
        "<" => x < yd
        ">" => x > yd
        "<=" => x <= yd
        ">=" => x >= yd
        _ => false
      }
    }
  }
}

/// 組み込み関数: =
fn builtin_num_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("=: requires at least 2 arguments"))
  }
  let first = match expect_number(args[0]) {
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
    if !compare_numbers("=", first, num) {
      return Ok(Value::Bool(false))
    }
    i = i + 1
  } else { () }
  Ok(Value::Bool(true))
}

/// 組み込み関数: <
fn builtin_lt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("<: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers("<", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else { () }
  Ok(Value::Bool(true))
}

/// 組み込み関数: >
fn builtin_gt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError(">: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers(">", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else { () }
  Ok(Value::Bool(true))
}

/// 組み込み関数: <=
fn builtin_le(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError("<=: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers("<=", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else { () }
  Ok(Value::Bool(true))
}

/// 組み込み関数: >=
fn builtin_ge(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 2 {
    return Err(EvalError::ArityError(">=: requires at least 2 arguments"))
  }
  let mut prev = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut i = 1
  let len = args.length()
  let _ = while i < len {
    let curr = match expect_number(args[i]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if !compare_numbers(">=", prev, curr) {
      return Ok(Value::Bool(false))
    }
    prev = curr
    i = i + 1
  } else { () }
  Ok(Value::Bool(true))
}

/// 組み込み関数: eq?
fn builtin_eq_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("eq?: requires exactly 2 arguments"))
  }
  // 簡易実装: 数値とブール値の等価性チェック
  let result = match (args[0], args[1]) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(a), Value::Bool(b)) => a == b
    (Value::Number(Number::Int(a)), Value::Number(Number::Int(b))) => a == b
    (Value::Symbol(a), Value::Symbol(b)) => a == b
    _ => false
  }
  Ok(Value::Bool(result))
}

/// 組み込み関数: not
fn builtin_not(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("not: requires exactly 1 argument"))
  }
  let result = match args[0] {
    Value::Bool(false) => true
    _ => false
  }
  Ok(Value::Bool(result))
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
  } else { () }
  Ok(items)
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
    _ => return Err(EvalError::TypeError("apply: first argument must be a procedure"))
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
  } else { () }
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
    _ => return Err(EvalError::TypeError("map: first argument must be a procedure"))
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
  } else { () }

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
        return Err(EvalError::InvalidSyntax("map: lists must have the same length"))
      }
      proc_args.push(lists[list_idx][idx])
      list_idx = list_idx + 1
    } else { () }

    // 手続きを適用
    let result = match apply(proc, proc_args) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    results.push(result)
    idx = idx + 1
  } else { () }

  // 配列をリストに変換
  array_to_list(results)
}

/// 配列を Value のリストに変換する。
fn array_to_list(items : Array[Value]) -> Result[Value, EvalError] {
  let mut result = Value::Nil
  let mut i = items.length()
  let _ = while i > 0 {
    i = i - 1
    result = Value::Pair(items[i], result)
  } else { () }
  Ok(result)
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
    _ => return Err(EvalError::TypeError("for-each: first argument must be a procedure"))
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
  } else { () }

  // すべてのリストが同じ長さかチェック
  if lists.length() == 0 {
    return Ok(Value::Nil)
  }
  let list_len = lists[0].length()

  // 各要素に手続きを適用（結果は捨てる）
  let mut idx = 0
  let _ = while idx < list_len {
    // 各リストから idx 番目の要素を取得
    let proc_args : Array[Value] = []
    let mut list_idx = 0
    let _ = while list_idx < lists.length() {
      if idx >= lists[list_idx].length() {
        return Err(EvalError::InvalidSyntax("for-each: lists must have the same length"))
      }
      proc_args.push(lists[list_idx][idx])
      list_idx = list_idx + 1
    } else { () }

    // 手続きを適用（結果は無視）
    let _ = match apply(proc, proc_args) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
    idx = idx + 1
  } else { () }

  // for-each は未定義値を返す
  Ok(Value::Nil)
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
  } else { () }
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
  } else { () }
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
      } else { () }

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
              _ => return Err(EvalError::InvalidSyntax("let*: invalid binding form"))
            }
          }
          _ => return Err(EvalError::InvalidSyntax("let*: bindings must be a list"))
        }
      } else { () }

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
              _ => return Err(EvalError::InvalidSyntax("letrec: invalid binding form"))
            }
          }
          _ => return Err(EvalError::InvalidSyntax("letrec: bindings must be a list"))
        }
      } else { () }

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
      } else { () }

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
  } else { () }
  Ok(Value::Nil)
}

/// 組み込み関数: string?
/// (string? obj) - obj が文字列かどうかを判定
fn builtin_string_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("string?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: char?
/// (char? obj) - obj が文字かどうかを判定
fn builtin_char_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: string-length
/// (string-length str) - 文字列の長さを返す
fn builtin_string_length(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("string-length: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(s) => Ok(Value::Number(Number::Int(s.length())))
    _ => Err(EvalError::TypeError("string-length: argument must be a string"))
  }
}

/// 組み込み関数: string-ref
/// (string-ref str k) - 文字列の k 番目の文字を返す
fn builtin_string_ref(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("string-ref: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::String(s), Value::Number(Number::Int(k))) => {
      let chars : Array[Char] = s.iter().collect()
      if k < 0 || k >= chars.length() {
        return Err(EvalError::InvalidSyntax("string-ref: index out of bounds"))
      }
      Ok(Value::Char(chars[k]))
    }
    (Value::String(_), _) => Err(EvalError::TypeError("string-ref: second argument must be an integer"))
    _ => Err(EvalError::TypeError("string-ref: first argument must be a string"))
  }
}

/// 組み込み関数: string-append
/// (string-append str1 str2 ...) - 文字列を連結する
fn builtin_string_append(args : Array[Value]) -> Result[Value, EvalError] {
  let builder = StringBuilder::new()
  for arg in args {
    match arg {
      Value::String(s) => builder.write_string(s)
      _ => return Err(EvalError::TypeError("string-append: all arguments must be strings"))
    }
  }
  Ok(Value::String(builder.to_string()))
}

/// 組み込み関数: string=?
/// (string=? str1 str2) - 文字列が等しいかを判定
fn builtin_string_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("string=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::String(s1), Value::String(s2)) => Ok(Value::Bool(s1 == s2))
    _ => Err(EvalError::TypeError("string=?: both arguments must be strings"))
  }
}

/// 組み込み関数: make-string
/// (make-string k [char]) - 長さ k の文字列を作成（オプションで文字を指定）
fn builtin_make_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() < 1 || args.length() > 2 {
    return Err(EvalError::ArityError("make-string: requires 1 or 2 arguments"))
  }
  match args[0] {
    Value::Number(Number::Int(k)) => {
      if k < 0 {
        return Err(EvalError::InvalidSyntax("make-string: length must be non-negative"))
      }
      let ch = if args.length() == 2 {
        match args[1] {
          Value::Char(c) => c
          _ => return Err(EvalError::TypeError("make-string: second argument must be a character"))
        }
      } else {
        ' '  // デフォルトはスペース
      }
      let builder = StringBuilder::new()
      let mut i = 0
      let _ = while i < k {
        builder.write_char(ch)
        i = i + 1
      } else { () }
      Ok(Value::String(builder.to_string()))
    }
    _ => Err(EvalError::TypeError("make-string: first argument must be an integer"))
  }
}

/// 組み込み関数: substring
/// (substring str start end) - 文字列の部分文字列を返す
fn builtin_substring(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(EvalError::ArityError("substring: requires exactly 3 arguments"))
  }
  match (args[0], args[1], args[2]) {
    (Value::String(s), Value::Number(Number::Int(start)), Value::Number(Number::Int(end))) => {
      if start < 0 || end < start || end > s.length() {
        return Err(EvalError::InvalidSyntax("substring: invalid range"))
      }
      let chars : Array[Char] = s.iter().collect()
      let builder = StringBuilder::new()
      let mut i = start
      let _ = while i < end {
        builder.write_char(chars[i])
        i = i + 1
      } else { () }
      Ok(Value::String(builder.to_string()))
    }
    (Value::String(_), _, _) => Err(EvalError::TypeError("substring: second and third arguments must be integers"))
    _ => Err(EvalError::TypeError("substring: first argument must be a string"))
  }
}

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
        return Err(EvalError::InvalidSyntax("make-vector: length must be non-negative"))
      }
      let fill = if args.length() == 2 {
        args[1]
      } else {
        Value::Nil  // デフォルトは ()
      }
      let items : Array[Value] = []
      let mut i = 0
      let _ = while i < k {
        items.push(fill)
        i = i + 1
      } else { () }
      Ok(Value::Vector(items))
    }
    _ => Err(EvalError::TypeError("make-vector: first argument must be an integer"))
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
    return Err(EvalError::ArityError("vector-length: requires exactly 1 argument"))
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
    return Err(EvalError::ArityError("vector-ref: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Vector(items), Value::Number(Number::Int(k))) => {
      if k < 0 || k >= items.length() {
        return Err(EvalError::InvalidSyntax("vector-ref: index out of bounds"))
      }
      Ok(items[k])
    }
    (Value::Vector(_), _) => Err(EvalError::TypeError("vector-ref: second argument must be an integer"))
    _ => Err(EvalError::TypeError("vector-ref: first argument must be a vector"))
  }
}

/// 組み込み関数: vector-set!
/// (vector-set! vector k obj) - ベクトルの k 番目の要素を obj に設定
/// 注: 不変環境モデルのため、新しいベクトルを返す
fn builtin_vector_set(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 3 {
    return Err(EvalError::ArityError("vector-set!: requires exactly 3 arguments"))
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
      } else { () }
      // 注: 本来は副作用のみで戻り値は未定義だが、不変モデルでは新しいベクトルを返す
      Ok(Value::Vector(new_items))
    }
    (Value::Vector(_), _) => Err(EvalError::TypeError("vector-set!: second argument must be an integer"))
    _ => Err(EvalError::TypeError("vector-set!: first argument must be a vector"))
  }
}

/// 組み込み関数: vector->list
/// (vector->list vector) - ベクトルをリストに変換
fn builtin_vector_to_list(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("vector->list: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Vector(items) => {
      let mut result = Value::Nil
      let mut i = items.length()
      let _ = while i > 0 {
        i = i - 1
        result = Value::Pair(items[i], result)
      } else { () }
      Ok(result)
    }
    _ => Err(EvalError::TypeError("vector->list: argument must be a vector"))
  }
}

/// 組み込み関数: list->vector
/// (list->vector list) - リストをベクトルに変換
fn builtin_list_to_vector(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("list->vector: requires exactly 1 argument"))
  }
  let list_items = match list_to_array(args[0]) {
    Ok(items) => items
    Err(e) => return Err(e)
  }
  Ok(Value::Vector(list_items))
}

/// 組み込み関数: floor
/// (floor x) - x 以下の最大の整数を返す
fn builtin_floor(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("floor: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Int(r.floor().to_int())))
    _ => Err(EvalError::TypeError("floor: argument must be a number"))
  }
}

/// 組み込み関数: ceiling
/// (ceiling x) - x 以上の最小の整数を返す
fn builtin_ceiling(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("ceiling: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Int(r.ceil().to_int())))
    _ => Err(EvalError::TypeError("ceiling: argument must be a number"))
  }
}

/// 組み込み関数: truncate
/// (truncate x) - x を 0 に向かって丸める
fn builtin_truncate(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("truncate: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Int(r.to_int())))
    _ => Err(EvalError::TypeError("truncate: argument must be a number"))
  }
}

/// 組み込み関数: round
/// (round x) - x を最も近い整数に丸める（.5 の場合は偶数に丸める）
fn builtin_round(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("round: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => {
      // 四捨五入（.5の場合は最も近い偶数に丸める）
      let rounded = r.round()
      Ok(Value::Number(Number::Int(rounded.to_int())))
    }
    _ => Err(EvalError::TypeError("round: argument must be a number"))
  }
}

/// 組み込み関数: sqrt
/// (sqrt x) - x の平方根を返す
fn builtin_sqrt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("sqrt: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = n.to_double().sqrt()
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(r.sqrt())))
    _ => Err(EvalError::TypeError("sqrt: argument must be a number"))
  }
}

/// 組み込み関数: expt
/// (expt x y) - x の y 乗を返す
fn builtin_expt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("expt: requires exactly 2 arguments"))
  }
  let base = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let exp = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (base, exp) {
    (Number::Int(b), Number::Int(e)) => {
      if e >= 0 {
        // 整数のべき乗（非負の指数）
        let result = b.to_double().pow(e.to_double())
        if result.floor() == result && result.to_int() != 0 {
          Ok(Value::Number(Number::Int(result.to_int())))
        } else {
          Ok(Value::Number(Number::Real(result)))
        }
      } else {
        // 負の指数は実数になる
        Ok(Value::Number(Number::Real(b.to_double().pow(e.to_double()))))
      }
    }
    _ => {
      let b_real = match base {
        Number::Int(n) => n.to_double()
        Number::Real(r) => r
      }
      let e_real = match exp {
        Number::Int(n) => n.to_double()
        Number::Real(r) => r
      }
      Ok(Value::Number(Number::Real(b_real.pow(e_real))))
    }
  }
}

// 注: MoonBit の Double 型は三角関数や対数関数のメソッドをサポートしていないため、
// sin, cos, tan, asin, acos, atan, exp, log は実装できません

/// 組み込み関数: exact?
/// (exact? z) - z が正確な数（整数）かどうかを判定
fn builtin_exact_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("exact?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Real(_)) => Ok(Value::Bool(false))
    _ => Err(EvalError::TypeError("exact?: argument must be a number"))
  }
}

/// 組み込み関数: inexact?
/// (inexact? z) - z が不正確な数（実数）かどうかを判定
fn builtin_inexact_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("inexact?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(false))
    Value::Number(Number::Real(_)) => Ok(Value::Bool(true))
    _ => Err(EvalError::TypeError("inexact?: argument must be a number"))
  }
}

/// 組み込み関数: number->string
/// (number->string z) - 数値を文字列に変換
fn builtin_number_to_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("number->string: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::String(n.to_string()))
    Value::Number(Number::Real(r)) => Ok(Value::String(r.to_string()))
    _ => Err(EvalError::TypeError("number->string: argument must be a number"))
  }
}

// 注: MoonBit の String 型は to_int/to_double メソッドをサポートしていないため、
// string->number は実装できません

/// 組み込み関数: sin
/// (sin x) - x のサイン（正弦）を返す（ラジアン）
fn builtin_sin(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("sin: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.sin(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.sin(r))))
    _ => Err(EvalError::TypeError("sin: argument must be a number"))
  }
}

/// 組み込み関数: cos
/// (cos x) - x のコサイン（余弦）を返す（ラジアン）
fn builtin_cos(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cos: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.cos(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.cos(r))))
    _ => Err(EvalError::TypeError("cos: argument must be a number"))
  }
}

/// 組み込み関数: tan
/// (tan x) - x のタンジェント（正接）を返す（ラジアン）
fn builtin_tan(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("tan: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.tan(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.tan(r))))
    _ => Err(EvalError::TypeError("tan: argument must be a number"))
  }
}

/// 組み込み関数: asin
/// (asin x) - x のアークサイン（逆正弦）を返す（ラジアン）
fn builtin_asin(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("asin: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.asin(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.asin(r))))
    _ => Err(EvalError::TypeError("asin: argument must be a number"))
  }
}

/// 組み込み関数: acos
/// (acos x) - x のアークコサイン（逆余弦）を返す（ラジアン）
fn builtin_acos(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("acos: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.acos(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.acos(r))))
    _ => Err(EvalError::TypeError("acos: argument must be a number"))
  }
}

/// 組み込み関数: atan
/// (atan x) または (atan y x) - アークタンジェント（逆正接）を返す（ラジアン）
/// 1引数の場合: atan(x)
/// 2引数の場合: atan2(y, x)
fn builtin_atan(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 1 {
    match args[0] {
      Value::Number(Number::Int(n)) => {
        let r = @math.atan(n.to_double())
        Ok(Value::Number(Number::Real(r)))
      }
      Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.atan(r))))
      _ => Err(EvalError::TypeError("atan: argument must be a number"))
    }
  } else if args.length() == 2 {
    let y = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    let x = match expect_number(args[1]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    let y_real = match y {
      Number::Int(n) => n.to_double()
      Number::Real(r) => r
    }
    let x_real = match x {
      Number::Int(n) => n.to_double()
      Number::Real(r) => r
    }
    Ok(Value::Number(Number::Real(@math.atan2(y_real, x_real))))
  } else {
    Err(EvalError::ArityError("atan: requires 1 or 2 arguments"))
  }
}

/// 組み込み関数: exp
/// (exp x) - e の x 乗を返す
fn builtin_exp(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("exp: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.exp(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.exp(r))))
    _ => Err(EvalError::TypeError("exp: argument must be a number"))
  }
}

/// 組み込み関数: log
/// (log x) - x の自然対数を返す
fn builtin_log(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("log: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.ln(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(@math.ln(r))))
    _ => Err(EvalError::TypeError("log: argument must be a number"))
  }
}

/// 初期環境を構築する（組み込み手続きを登録）。
pub fn initial_env() -> Env {
  let env = empty_env()
  // 算術演算
  let env = define_var(env, "+", Value::Procedure(Procedure::Native("+")))
  let env = define_var(env, "-", Value::Procedure(Procedure::Native("-")))
  let env = define_var(env, "*", Value::Procedure(Procedure::Native("*")))
  let env = define_var(env, "/", Value::Procedure(Procedure::Native("/")))
  let env = define_var(env, "quotient", Value::Procedure(Procedure::Native("quotient")))
  let env = define_var(env, "remainder", Value::Procedure(Procedure::Native("remainder")))
  let env = define_var(env, "modulo", Value::Procedure(Procedure::Native("modulo")))
  let env = define_var(env, "abs", Value::Procedure(Procedure::Native("abs")))
  let env = define_var(env, "max", Value::Procedure(Procedure::Native("max")))
  let env = define_var(env, "min", Value::Procedure(Procedure::Native("min")))
  // リスト操作
  let env = define_var(env, "cons", Value::Procedure(Procedure::Native("cons")))
  let env = define_var(env, "car", Value::Procedure(Procedure::Native("car")))
  let env = define_var(env, "cdr", Value::Procedure(Procedure::Native("cdr")))
  let env = define_var(env, "list", Value::Procedure(Procedure::Native("list")))
  let env = define_var(env, "length", Value::Procedure(Procedure::Native("length")))
  let env = define_var(env, "append", Value::Procedure(Procedure::Native("append")))
  let env = define_var(env, "reverse", Value::Procedure(Procedure::Native("reverse")))
  let env = define_var(env, "list-ref", Value::Procedure(Procedure::Native("list-ref")))
  let env = define_var(env, "list-tail", Value::Procedure(Procedure::Native("list-tail")))
  // 型判定
  let env = define_var(env, "pair?", Value::Procedure(Procedure::Native("pair?")))
  let env = define_var(env, "number?", Value::Procedure(Procedure::Native("number?")))
  let env = define_var(env, "boolean?", Value::Procedure(Procedure::Native("boolean?")))
  let env = define_var(env, "symbol?", Value::Procedure(Procedure::Native("symbol?")))
  let env = define_var(env, "null?", Value::Procedure(Procedure::Native("null?")))
  // 比較演算
  let env = define_var(env, "=", Value::Procedure(Procedure::Native("=")))
  let env = define_var(env, "<", Value::Procedure(Procedure::Native("<")))
  let env = define_var(env, ">", Value::Procedure(Procedure::Native(">")))
  let env = define_var(env, "<=", Value::Procedure(Procedure::Native("<=")))
  let env = define_var(env, ">=", Value::Procedure(Procedure::Native(">=")))
  let env = define_var(env, "eq?", Value::Procedure(Procedure::Native("eq?")))
  // 論理演算
  let env = define_var(env, "not", Value::Procedure(Procedure::Native("not")))
  // 高階関数
  let env = define_var(env, "apply", Value::Procedure(Procedure::Native("apply")))
  let env = define_var(env, "map", Value::Procedure(Procedure::Native("map")))
  let env = define_var(env, "for-each", Value::Procedure(Procedure::Native("for-each")))
  // 文字列操作
  let env = define_var(env, "string?", Value::Procedure(Procedure::Native("string?")))
  let env = define_var(env, "char?", Value::Procedure(Procedure::Native("char?")))
  let env = define_var(env, "string-length", Value::Procedure(Procedure::Native("string-length")))
  let env = define_var(env, "string-ref", Value::Procedure(Procedure::Native("string-ref")))
  let env = define_var(env, "string-append", Value::Procedure(Procedure::Native("string-append")))
  let env = define_var(env, "string=?", Value::Procedure(Procedure::Native("string=?")))
  let env = define_var(env, "make-string", Value::Procedure(Procedure::Native("make-string")))
  let env = define_var(env, "substring", Value::Procedure(Procedure::Native("substring")))
  // ベクトル操作
  let env = define_var(env, "vector?", Value::Procedure(Procedure::Native("vector?")))
  let env = define_var(env, "make-vector", Value::Procedure(Procedure::Native("make-vector")))
  let env = define_var(env, "vector", Value::Procedure(Procedure::Native("vector")))
  let env = define_var(env, "vector-length", Value::Procedure(Procedure::Native("vector-length")))
  let env = define_var(env, "vector-ref", Value::Procedure(Procedure::Native("vector-ref")))
  let env = define_var(env, "vector-set!", Value::Procedure(Procedure::Native("vector-set!")))
  let env = define_var(env, "vector->list", Value::Procedure(Procedure::Native("vector->list")))
  let env = define_var(env, "list->vector", Value::Procedure(Procedure::Native("list->vector")))
  // 数値関数
  let env = define_var(env, "floor", Value::Procedure(Procedure::Native("floor")))
  let env = define_var(env, "ceiling", Value::Procedure(Procedure::Native("ceiling")))
  let env = define_var(env, "truncate", Value::Procedure(Procedure::Native("truncate")))
  let env = define_var(env, "round", Value::Procedure(Procedure::Native("round")))
  let env = define_var(env, "sqrt", Value::Procedure(Procedure::Native("sqrt")))
  let env = define_var(env, "expt", Value::Procedure(Procedure::Native("expt")))
  let env = define_var(env, "exact?", Value::Procedure(Procedure::Native("exact?")))
  let env = define_var(env, "inexact?", Value::Procedure(Procedure::Native("inexact?")))
  let env = define_var(env, "number->string", Value::Procedure(Procedure::Native("number->string")))
  // 三角関数
  let env = define_var(env, "sin", Value::Procedure(Procedure::Native("sin")))
  let env = define_var(env, "cos", Value::Procedure(Procedure::Native("cos")))
  let env = define_var(env, "tan", Value::Procedure(Procedure::Native("tan")))
  let env = define_var(env, "asin", Value::Procedure(Procedure::Native("asin")))
  let env = define_var(env, "acos", Value::Procedure(Procedure::Native("acos")))
  let env = define_var(env, "atan", Value::Procedure(Procedure::Native("atan")))
  // 指数・対数関数
  let env = define_var(env, "exp", Value::Procedure(Procedure::Native("exp")))
  let env = define_var(env, "log", Value::Procedure(Procedure::Native("log")))
  env
}
