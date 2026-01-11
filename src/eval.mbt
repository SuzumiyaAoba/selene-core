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
    SExpr::Bool(b) => Ok(Value::Bool(b))

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
    "list" => builtin_list(args)
    "length" => builtin_length(args)
    "append" => builtin_append(args)
    "reverse" => builtin_reverse(args)
    "list-ref" => builtin_list_ref(args)
    "list-tail" => builtin_list_tail(args)
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
  env
}
