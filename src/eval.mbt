/// Scheme 評価器の中核実装。

/// 評価エラーを表す型。
pub(all) enum EvalError {
  UnboundVariable(String)
  InvalidSyntax(String)
  TypeError(String)
  ArityError(String)
  /// 継続が呼び出されたことを示す（エスケープ継続）
  ContinuationInvoked(Int, Value)
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
        SExpr::Symbol("case") => eval_case(cdr, env)
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
    Value::Procedure(Procedure::Cont(cont)) => {
      // 継続の呼び出し：引数は1つ
      if args.length() != 1 {
        return Err(EvalError::ArityError("continuation: requires exactly 1 argument"))
      }
      // 継続が呼び出されたことをエラーとして伝播
      Err(EvalError::ContinuationInvoked(cont.id, args[0]))
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
    "caar" => builtin_caar(args)
    "cadr" => builtin_cadr(args)
    "cdar" => builtin_cdar(args)
    "cddr" => builtin_cddr(args)
    "caaar" => builtin_caaar(args)
    "caadr" => builtin_caadr(args)
    "cadar" => builtin_cadar(args)
    "caddr" => builtin_caddr(args)
    "cdaar" => builtin_cdaar(args)
    "cdadr" => builtin_cdadr(args)
    "cddar" => builtin_cddar(args)
    "cdddr" => builtin_cdddr(args)
    "pair?" => builtin_pair_p(args)
    "number?" => builtin_number_p(args)
    "integer?" => builtin_integer_p(args)
    "real?" => builtin_real_p(args)
    "boolean?" => builtin_boolean_p(args)
    "symbol?" => builtin_symbol_p(args)
    "null?" => builtin_null_p(args)
    "procedure?" => builtin_procedure_p(args)
    "list?" => builtin_list_p(args)
    "zero?" => builtin_zero_p(args)
    "positive?" => builtin_positive_p(args)
    "negative?" => builtin_negative_p(args)
    "odd?" => builtin_odd_p(args)
    "even?" => builtin_even_p(args)
    "=" => builtin_num_eq(args)
    "<" => builtin_lt(args)
    ">" => builtin_gt(args)
    "<=" => builtin_le(args)
    ">=" => builtin_ge(args)
    "eq?" => builtin_eq_p(args)
    "eqv?" => builtin_eqv_p(args)
    "equal?" => builtin_equal_p(args)
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
    "assq" => builtin_assq(args)
    "assv" => builtin_assv(args)
    "assoc" => builtin_assoc(args)
    "memq" => builtin_memq(args)
    "memv" => builtin_memv(args)
    "member" => builtin_member(args)
    "symbol->string" => builtin_symbol_to_string(args)
    "string->symbol" => builtin_string_to_symbol(args)
    "string?" => builtin_string_p(args)
    "char?" => builtin_char_p(args)
    "char=?" => builtin_char_eq(args)
    "char<?" => builtin_char_lt(args)
    "char>?" => builtin_char_gt(args)
    "char<=?" => builtin_char_le(args)
    "char>=?" => builtin_char_ge(args)
    "char-alphabetic?" => builtin_char_alphabetic_p(args)
    "char-numeric?" => builtin_char_numeric_p(args)
    "char-whitespace?" => builtin_char_whitespace_p(args)
    "char-upper-case?" => builtin_char_upper_case_p(args)
    "char-lower-case?" => builtin_char_lower_case_p(args)
    "char-upcase" => builtin_char_upcase(args)
    "char-downcase" => builtin_char_downcase(args)
    "char->integer" => builtin_char_to_integer(args)
    "integer->char" => builtin_integer_to_char(args)
    "string->list" => builtin_string_to_list(args)
    "list->string" => builtin_list_to_string(args)
    "gcd" => builtin_gcd(args)
    "lcm" => builtin_lcm(args)
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
    "display" => builtin_display(args)
    "newline" => builtin_newline(args)
    "write" => builtin_write(args)
    "read" => builtin_read(args)
    "string->number" => builtin_string_to_number(args)
    "call/cc" | "call-with-current-continuation" => builtin_call_cc(args)
    _ => Err(EvalError::InvalidSyntax("unknown builtin: " + name))
  }
}

/// 組み込み関数: call/cc (call-with-current-continuation)
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
          _ => return Err(EvalError::TypeError("assq: alist element must be a pair"))
        }
      }
      _ => return Err(EvalError::TypeError("assq: second argument must be a list"))
    }
  } else { () }
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
          _ => return Err(EvalError::TypeError("assv: alist element must be a pair"))
        }
      }
      _ => return Err(EvalError::TypeError("assv: second argument must be a list"))
    }
  } else { () }
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
          _ => return Err(EvalError::TypeError("assoc: alist element must be a pair"))
        }
      }
      _ => return Err(EvalError::TypeError("assoc: second argument must be a list"))
    }
  } else { () }
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
  } else { () }
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
  } else { () }
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
      _ => return Err(EvalError::TypeError("member: second argument must be a list"))
    }
  } else { () }
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
    return Err(EvalError::ArityError("symbol->string: requires exactly 1 argument"))
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
    return Err(EvalError::ArityError("string->symbol: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(s) => Ok(Value::Symbol(s))
    _ => Err(EvalError::TypeError("string->symbol: argument must be a string"))
  }
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

/// 組み込み関数: procedure?
fn builtin_procedure_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("procedure?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Procedure(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: list?
fn builtin_list_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("list?: requires exactly 1 argument"))
  }
  fn is_list(v : Value) -> Bool {
    match v {
      Value::Nil => true
      Value::Pair(_, cdr) => is_list(cdr)
      _ => false
    }
  }
  Ok(Value::Bool(is_list(args[0])))
}

/// 組み込み関数: integer?
fn builtin_integer_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("integer?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Real(r)) => {
      // 整数値を持つ実数も integer? は #t を返す
      Ok(Value::Bool(r.floor() == r))
    }
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: real?
fn builtin_real_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("real?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 組み込み関数: zero?
fn builtin_zero_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("zero?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n == 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r == 0.0))
    _ => Err(EvalError::TypeError("zero?: argument must be a number"))
  }
}

/// 組み込み関数: positive?
fn builtin_positive_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("positive?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n > 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r > 0.0))
    _ => Err(EvalError::TypeError("positive?: argument must be a number"))
  }
}

/// 組み込み関数: negative?
fn builtin_negative_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("negative?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n < 0))
    Value::Number(Number::Real(r)) => Ok(Value::Bool(r < 0.0))
    _ => Err(EvalError::TypeError("negative?: argument must be a number"))
  }
}

/// 組み込み関数: odd?
fn builtin_odd_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("odd?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n % 2 != 0))
    Value::Number(Number::Real(r)) => {
      if r.floor() != r {
        Err(EvalError::TypeError("odd?: argument must be an integer"))
      } else {
        Ok(Value::Bool(r.to_int() % 2 != 0))
      }
    }
    _ => Err(EvalError::TypeError("odd?: argument must be an integer"))
  }
}

/// 組み込み関数: even?
fn builtin_even_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("even?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n % 2 == 0))
    Value::Number(Number::Real(r)) => {
      if r.floor() != r {
        Err(EvalError::TypeError("even?: argument must be an integer"))
      } else {
        Ok(Value::Bool(r.to_int() % 2 == 0))
      }
    }
    _ => Err(EvalError::TypeError("even?: argument must be an integer"))
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

/// 組み込み関数: eqv?
/// eq? よりも緩い等価性チェック（数値も含む）
fn builtin_eqv_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("eqv?: requires exactly 2 arguments"))
  }
  let result = match (args[0], args[1]) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(a), Value::Bool(b)) => a == b
    (Value::Number(Number::Int(a)), Value::Number(Number::Int(b))) => a == b
    (Value::Number(Number::Real(a)), Value::Number(Number::Real(b))) => a == b
    (Value::Char(a), Value::Char(b)) => a == b
    (Value::Symbol(a), Value::Symbol(b)) => a == b
    (Value::String(a), Value::String(b)) => physical_identity(a, b)
    (Value::Pair(_, _), Value::Pair(_, _)) => physical_identity(args[0], args[1])
    (Value::Vector(_), Value::Vector(_)) => physical_identity(args[0], args[1])
    (Value::Procedure(Procedure::Native(a)), Value::Procedure(Procedure::Native(b))) => a == b
    (Value::Procedure(Procedure::Closure(_, _, _)), Value::Procedure(Procedure::Closure(_, _, _))) =>
      physical_identity(args[0], args[1])
    (Value::Procedure(Procedure::Cont(a)), Value::Procedure(Procedure::Cont(b))) => a.id == b.id
    _ => false
  }
  Ok(Value::Bool(result))
}

/// 物理的同一性をチェックするヘルパー関数
/// MoonBit では参照比較が難しいため、常に false を返す
fn physical_identity[T](_a : T, _b : T) -> Bool {
  false
}

/// 組み込み関数: equal?
/// 構造的等価性をチェック（深い比較）
fn builtin_equal_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("equal?: requires exactly 2 arguments"))
  }
  Ok(Value::Bool(values_equal(args[0], args[1])))
}

/// 2つの Value が構造的に等しいかチェックする
fn values_equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Real(y))) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Real(y))) => x.to_double() == y
    (Value::Number(Number::Real(x)), Value::Number(Number::Int(y))) => x == y.to_double()
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::String(x), Value::String(y)) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Pair(car1, cdr1), Value::Pair(car2, cdr2)) =>
      values_equal(car1, car2) && values_equal(cdr1, cdr2)
    (Value::Vector(v1), Value::Vector(v2)) => {
      if v1.length() != v2.length() {
        false
      } else {
        let mut i = 0
        let len = v1.length()
        let mut result = true
        let _ = while i < len {
          if not(values_equal(v1[i], v2[i])) {
            result = false
            break
          }
          i = i + 1
        } else { () }
        result
      }
    }
    (Value::Procedure(Procedure::Native(x)), Value::Procedure(Procedure::Native(y))) => x == y
    (Value::Procedure(Procedure::Cont(x)), Value::Procedure(Procedure::Cont(y))) => x.id == y.id
    _ => false
  }
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
      } else { () }
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
  } else { () }
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

/// 組み込み関数: char=?
/// (char=? char1 char2) - 文字が等しいかを判定
fn builtin_char_eq(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a == b))
    _ => Err(EvalError::TypeError("char=?: arguments must be characters"))
  }
}

/// 組み込み関数: char<?
/// (char<? char1 char2) - char1 が char2 より小さいかを判定
fn builtin_char_lt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() < b.to_int()))
    _ => Err(EvalError::TypeError("char<?: arguments must be characters"))
  }
}

/// 組み込み関数: char>?
/// (char>? char1 char2) - char1 が char2 より大きいかを判定
fn builtin_char_gt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() > b.to_int()))
    _ => Err(EvalError::TypeError("char>?: arguments must be characters"))
  }
}

/// 組み込み関数: char<=?
/// (char<=? char1 char2) - char1 が char2 以下かを判定
fn builtin_char_le(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char<=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() <= b.to_int()))
    _ => Err(EvalError::TypeError("char<=?: arguments must be characters"))
  }
}

/// 組み込み関数: char>=?
/// (char>=? char1 char2) - char1 が char2 以上かを判定
fn builtin_char_ge(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("char>=?: requires exactly 2 arguments"))
  }
  match (args[0], args[1]) {
    (Value::Char(a), Value::Char(b)) => Ok(Value::Bool(a.to_int() >= b.to_int()))
    _ => Err(EvalError::TypeError("char>=?: arguments must be characters"))
  }
}

/// 組み込み関数: char-alphabetic?
/// (char-alphabetic? char) - 文字がアルファベットかを判定
fn builtin_char_alphabetic_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-alphabetic?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_alpha = (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
      Ok(Value::Bool(is_alpha))
    }
    _ => Err(EvalError::TypeError("char-alphabetic?: argument must be a character"))
  }
}

/// 組み込み関数: char-numeric?
/// (char-numeric? char) - 文字が数字かを判定
fn builtin_char_numeric_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-numeric?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_numeric = code >= 48 && code <= 57
      Ok(Value::Bool(is_numeric))
    }
    _ => Err(EvalError::TypeError("char-numeric?: argument must be a character"))
  }
}

/// 組み込み関数: char-whitespace?
/// (char-whitespace? char) - 文字が空白文字かを判定
fn builtin_char_whitespace_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-whitespace?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let is_whitespace = c == ' ' || c == '\t' || c == '\n' || c == '\r'
      Ok(Value::Bool(is_whitespace))
    }
    _ => Err(EvalError::TypeError("char-whitespace?: argument must be a character"))
  }
}

/// 組み込み関数: char-upper-case?
/// (char-upper-case? char) - 文字が大文字かを判定
fn builtin_char_upper_case_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-upper-case?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_upper = code >= 65 && code <= 90
      Ok(Value::Bool(is_upper))
    }
    _ => Err(EvalError::TypeError("char-upper-case?: argument must be a character"))
  }
}

/// 組み込み関数: char-lower-case?
/// (char-lower-case? char) - 文字が小文字かを判定
fn builtin_char_lower_case_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-lower-case?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      let is_lower = code >= 97 && code <= 122
      Ok(Value::Bool(is_lower))
    }
    _ => Err(EvalError::TypeError("char-lower-case?: argument must be a character"))
  }
}

/// 組み込み関数: char-upcase
/// (char-upcase char) - 文字を大文字に変換
fn builtin_char_upcase(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-upcase: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      if code >= 97 && code <= 122 {
        // 小文字 -> 大文字
        Ok(Value::Char(Char::from_int(code - 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-upcase: argument must be a character"))
  }
}

/// 組み込み関数: char-downcase
/// (char-downcase char) - 文字を小文字に変換
fn builtin_char_downcase(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char-downcase: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => {
      let code = c.to_int()
      if code >= 65 && code <= 90 {
        // 大文字 -> 小文字
        Ok(Value::Char(Char::from_int(code + 32)))
      } else {
        Ok(Value::Char(c))
      }
    }
    _ => Err(EvalError::TypeError("char-downcase: argument must be a character"))
  }
}

/// 組み込み関数: char->integer
/// (char->integer char) - 文字を整数（文字コード）に変換
fn builtin_char_to_integer(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("char->integer: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Char(c) => Ok(Value::Number(Number::Int(c.to_int())))
    _ => Err(EvalError::TypeError("char->integer: argument must be a character"))
  }
}

/// 組み込み関数: integer->char
/// (integer->char n) - 整数（文字コード）を文字に変換
fn builtin_integer_to_char(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("integer->char: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      if n >= 0 && n <= 1114111 {
        Ok(Value::Char(Char::from_int(n)))
      } else {
        Err(EvalError::TypeError("integer->char: integer out of valid Unicode range"))
      }
    }
    _ => Err(EvalError::TypeError("integer->char: argument must be an integer"))
  }
}

/// 組み込み関数: string->list
/// (string->list str) - 文字列を文字のリストに変換
fn builtin_string_to_list(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("string->list: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(s) => {
      let chars = s.to_array()
      let mut result = Value::Nil
      let mut i = chars.length()
      let _ = while i > 0 {
        i = i - 1
        result = Value::Pair(Value::Char(chars[i]), result)
      } else { () }
      Ok(result)
    }
    _ => Err(EvalError::TypeError("string->list: argument must be a string"))
  }
}

/// 組み込み関数: list->string
/// (list->string list) - 文字のリストを文字列に変換
fn builtin_list_to_string(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("list->string: requires exactly 1 argument"))
  }
  let chars : Array[Char] = []
  let mut current = args[0]
  let _ = while true {
    match current {
      Value::Nil => break
      Value::Pair(Value::Char(c), rest) => {
        chars.push(c)
        current = rest
      }
      Value::Pair(_, _) => return Err(EvalError::TypeError("list->string: list must contain only characters"))
      _ => return Err(EvalError::TypeError("list->string: argument must be a proper list"))
    }
  } else { () }

  let mut result = ""
  for c in chars {
    result = result + c.to_string()
  }
  Ok(Value::String(result))
}

/// 組み込み関数: gcd
/// (gcd n1 n2 ...) - 最大公約数を計算
fn builtin_gcd(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(0)))
  }

  fn gcd_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if b_abs == 0 {
      a_abs
    } else {
      gcd_two(b_abs, a_abs % b_abs)
    }
  }

  let mut result = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(EvalError::TypeError("gcd: arguments must be integers"))
  }

  let mut i = 1
  let _ = while i < args.length() {
    let n = match args[i] {
      Value::Number(Number::Int(n)) => n
      _ => return Err(EvalError::TypeError("gcd: arguments must be integers"))
    }
    result = gcd_two(result, n)
    i = i + 1
  } else { () }

  Ok(Value::Number(Number::Int(result)))
}

/// 組み込み関数: lcm
/// (lcm n1 n2 ...) - 最小公倍数を計算
fn builtin_lcm(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 0 {
    return Ok(Value::Number(Number::Int(1)))
  }

  fn gcd_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if b_abs == 0 {
      a_abs
    } else {
      gcd_two(b_abs, a_abs % b_abs)
    }
  }

  fn lcm_two(a : Int, b : Int) -> Int {
    let a_abs = if a < 0 { -a } else { a }
    let b_abs = if b < 0 { -b } else { b }
    if a_abs == 0 || b_abs == 0 {
      0
    } else {
      (a_abs / gcd_two(a_abs, b_abs)) * b_abs
    }
  }

  let mut result = match args[0] {
    Value::Number(Number::Int(n)) => if n < 0 { -n } else { n }
    _ => return Err(EvalError::TypeError("lcm: arguments must be integers"))
  }

  let mut i = 1
  let _ = while i < args.length() {
    let n = match args[i] {
      Value::Number(Number::Int(n)) => n
      _ => return Err(EvalError::TypeError("lcm: arguments must be integers"))
    }
    result = lcm_two(result, n)
    i = i + 1
  } else { () }

  Ok(Value::Number(Number::Int(result)))
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

/// 値を表示用文字列に変換する（displayで使用）
fn value_to_display_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Char(c) => c.to_string()
    Value::String(s) => s  // displayは文字列を引用符なしで出力
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_display_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + value_to_display_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_display_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(items) => {
      let mut result = "#("
      let len = items.length()
      let mut i = 0
      let _ = while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + value_to_display_string(items[i])
        i = i + 1
      } else { () }
      result + ")"
    }
    Value::Procedure(Procedure::Native(name)) => "#<procedure:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<procedure:closure>"
    Value::Procedure(Procedure::Cont(cont)) => "#<continuation:" + cont.id.to_string() + ">"
  }
}

/// 値を書き込み用文字列に変換する（writeで使用）
fn value_to_write_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""  // writeは文字列を引用符付きで出力
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_write_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + value_to_write_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_write_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(items) => {
      let mut result = "#("
      let len = items.length()
      let mut i = 0
      let _ = while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + value_to_write_string(items[i])
        i = i + 1
      } else { () }
      result + ")"
    }
    Value::Procedure(Procedure::Native(name)) => "#<procedure:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<procedure:closure>"
    Value::Procedure(Procedure::Cont(cont)) => "#<continuation:" + cont.id.to_string() + ">"
  }
}

/// 組み込み関数: display
/// (display obj) - objを人間が読みやすい形式で出力する（文字列は引用符なし）
/// 注: MoonBitではprintlnのみが利用可能なため、改行付きで出力されます
fn builtin_display(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("display: requires exactly 1 argument"))
  }
  let output = value_to_display_string(args[0])
  println(output)
  Ok(Value::Nil)  // displayは未定義値を返す（Nilで代用）
}

/// 組み込み関数: newline
/// (newline) - 改行を出力する
fn builtin_newline(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 0 {
    return Err(EvalError::ArityError("newline: requires exactly 0 arguments"))
  }
  println("")
  Ok(Value::Nil)  // newlineは未定義値を返す（Nilで代用）
}

/// 組み込み関数: write
/// (write obj) - objを機械が読める形式で出力する（文字列は引用符付き）
/// 注: MoonBitではprintlnのみが利用可能なため、改行付きで出力されます
fn builtin_write(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("write: requires exactly 1 argument"))
  }
  let output = value_to_write_string(args[0])
  println(output)
  Ok(Value::Nil)  // writeは未定義値を返す（Nilで代用）
}

/// 組み込み関数: read
/// (read) - 標準入力から1つのS式を読み取って返す
/// 注: このバージョンはJS バックエンド専用です
fn builtin_read(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 0 {
    return Err(EvalError::ArityError("read: requires exactly 0 arguments"))
  }
  // JS FFI経由で標準入力から一行読み取る
  let line = read_line()
  // パースしてS式に変換
  let sexpr = parse_one(line)
  // S式をValueに変換（評価せずにデータとして返す）
  Ok(sexpr_to_value(sexpr))
}

/// 組み込み関数: string->number
/// (string->number str) - 文字列を数値に変換する（失敗時は#fを返す）
fn builtin_string_to_number(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("string->number: requires exactly 1 argument"))
  }
  match args[0] {
    Value::String(s) => {
      // まず整数としてパースを試みる
      // try?を使ってResult型に変換
      let int_result = try? @strconv.parse_int(s)
      match int_result {
        Ok(n) => return Ok(Value::Number(Number::Int(n)))
        Err(_) => ()
      }
      // 整数でなければ実数としてパースを試みる
      let double_result = try? @strconv.parse_double(s)
      match double_result {
        Ok(d) => return Ok(Value::Number(Number::Real(d)))
        Err(_) => ()
      }
      // どちらも失敗したら#fを返す
      Ok(Value::Bool(false))
    }
    _ => Err(EvalError::TypeError("string->number: argument must be a string"))
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
  let env = define_var(env, "gcd", Value::Procedure(Procedure::Native("gcd")))
  let env = define_var(env, "lcm", Value::Procedure(Procedure::Native("lcm")))
  // リスト操作
  let env = define_var(env, "cons", Value::Procedure(Procedure::Native("cons")))
  let env = define_var(env, "car", Value::Procedure(Procedure::Native("car")))
  let env = define_var(env, "cdr", Value::Procedure(Procedure::Native("cdr")))
  let env = define_var(env, "caar", Value::Procedure(Procedure::Native("caar")))
  let env = define_var(env, "cadr", Value::Procedure(Procedure::Native("cadr")))
  let env = define_var(env, "cdar", Value::Procedure(Procedure::Native("cdar")))
  let env = define_var(env, "cddr", Value::Procedure(Procedure::Native("cddr")))
  let env = define_var(env, "caaar", Value::Procedure(Procedure::Native("caaar")))
  let env = define_var(env, "caadr", Value::Procedure(Procedure::Native("caadr")))
  let env = define_var(env, "cadar", Value::Procedure(Procedure::Native("cadar")))
  let env = define_var(env, "caddr", Value::Procedure(Procedure::Native("caddr")))
  let env = define_var(env, "cdaar", Value::Procedure(Procedure::Native("cdaar")))
  let env = define_var(env, "cdadr", Value::Procedure(Procedure::Native("cdadr")))
  let env = define_var(env, "cddar", Value::Procedure(Procedure::Native("cddar")))
  let env = define_var(env, "cdddr", Value::Procedure(Procedure::Native("cdddr")))
  let env = define_var(env, "list", Value::Procedure(Procedure::Native("list")))
  let env = define_var(env, "length", Value::Procedure(Procedure::Native("length")))
  let env = define_var(env, "append", Value::Procedure(Procedure::Native("append")))
  let env = define_var(env, "reverse", Value::Procedure(Procedure::Native("reverse")))
  let env = define_var(env, "list-ref", Value::Procedure(Procedure::Native("list-ref")))
  let env = define_var(env, "list-tail", Value::Procedure(Procedure::Native("list-tail")))
  // 連想リスト
  let env = define_var(env, "assq", Value::Procedure(Procedure::Native("assq")))
  let env = define_var(env, "assv", Value::Procedure(Procedure::Native("assv")))
  let env = define_var(env, "assoc", Value::Procedure(Procedure::Native("assoc")))
  // メンバーシップ
  let env = define_var(env, "memq", Value::Procedure(Procedure::Native("memq")))
  let env = define_var(env, "memv", Value::Procedure(Procedure::Native("memv")))
  let env = define_var(env, "member", Value::Procedure(Procedure::Native("member")))
  // シンボル変換
  let env = define_var(env, "symbol->string", Value::Procedure(Procedure::Native("symbol->string")))
  let env = define_var(env, "string->symbol", Value::Procedure(Procedure::Native("string->symbol")))
  // 型判定
  let env = define_var(env, "pair?", Value::Procedure(Procedure::Native("pair?")))
  let env = define_var(env, "number?", Value::Procedure(Procedure::Native("number?")))
  let env = define_var(env, "integer?", Value::Procedure(Procedure::Native("integer?")))
  let env = define_var(env, "real?", Value::Procedure(Procedure::Native("real?")))
  let env = define_var(env, "boolean?", Value::Procedure(Procedure::Native("boolean?")))
  let env = define_var(env, "symbol?", Value::Procedure(Procedure::Native("symbol?")))
  let env = define_var(env, "null?", Value::Procedure(Procedure::Native("null?")))
  let env = define_var(env, "procedure?", Value::Procedure(Procedure::Native("procedure?")))
  let env = define_var(env, "list?", Value::Procedure(Procedure::Native("list?")))
  // 比較演算
  let env = define_var(env, "=", Value::Procedure(Procedure::Native("=")))
  let env = define_var(env, "<", Value::Procedure(Procedure::Native("<")))
  let env = define_var(env, ">", Value::Procedure(Procedure::Native(">")))
  let env = define_var(env, "<=", Value::Procedure(Procedure::Native("<=")))
  let env = define_var(env, ">=", Value::Procedure(Procedure::Native(">=")))
  let env = define_var(env, "eq?", Value::Procedure(Procedure::Native("eq?")))
  let env = define_var(env, "eqv?", Value::Procedure(Procedure::Native("eqv?")))
  let env = define_var(env, "equal?", Value::Procedure(Procedure::Native("equal?")))
  // 数値述語
  let env = define_var(env, "zero?", Value::Procedure(Procedure::Native("zero?")))
  let env = define_var(env, "positive?", Value::Procedure(Procedure::Native("positive?")))
  let env = define_var(env, "negative?", Value::Procedure(Procedure::Native("negative?")))
  let env = define_var(env, "odd?", Value::Procedure(Procedure::Native("odd?")))
  let env = define_var(env, "even?", Value::Procedure(Procedure::Native("even?")))
  // 論理演算
  let env = define_var(env, "not", Value::Procedure(Procedure::Native("not")))
  // 高階関数
  let env = define_var(env, "apply", Value::Procedure(Procedure::Native("apply")))
  let env = define_var(env, "map", Value::Procedure(Procedure::Native("map")))
  let env = define_var(env, "for-each", Value::Procedure(Procedure::Native("for-each")))
  // 文字列操作
  let env = define_var(env, "string?", Value::Procedure(Procedure::Native("string?")))
  let env = define_var(env, "char?", Value::Procedure(Procedure::Native("char?")))
  // 文字比較
  let env = define_var(env, "char=?", Value::Procedure(Procedure::Native("char=?")))
  let env = define_var(env, "char<?", Value::Procedure(Procedure::Native("char<?")))
  let env = define_var(env, "char>?", Value::Procedure(Procedure::Native("char>?")))
  let env = define_var(env, "char<=?", Value::Procedure(Procedure::Native("char<=?")))
  let env = define_var(env, "char>=?", Value::Procedure(Procedure::Native("char>=?")))
  // 文字分類
  let env = define_var(env, "char-alphabetic?", Value::Procedure(Procedure::Native("char-alphabetic?")))
  let env = define_var(env, "char-numeric?", Value::Procedure(Procedure::Native("char-numeric?")))
  let env = define_var(env, "char-whitespace?", Value::Procedure(Procedure::Native("char-whitespace?")))
  let env = define_var(env, "char-upper-case?", Value::Procedure(Procedure::Native("char-upper-case?")))
  let env = define_var(env, "char-lower-case?", Value::Procedure(Procedure::Native("char-lower-case?")))
  // 文字変換
  let env = define_var(env, "char-upcase", Value::Procedure(Procedure::Native("char-upcase")))
  let env = define_var(env, "char-downcase", Value::Procedure(Procedure::Native("char-downcase")))
  let env = define_var(env, "char->integer", Value::Procedure(Procedure::Native("char->integer")))
  let env = define_var(env, "integer->char", Value::Procedure(Procedure::Native("integer->char")))
  // 文字列/リスト変換
  let env = define_var(env, "string->list", Value::Procedure(Procedure::Native("string->list")))
  let env = define_var(env, "list->string", Value::Procedure(Procedure::Native("list->string")))
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
  // I/O関数
  let env = define_var(env, "display", Value::Procedure(Procedure::Native("display")))
  let env = define_var(env, "newline", Value::Procedure(Procedure::Native("newline")))
  let env = define_var(env, "write", Value::Procedure(Procedure::Native("write")))
  let env = define_var(env, "read", Value::Procedure(Procedure::Native("read")))
  // 文字列変換
  let env = define_var(env, "string->number", Value::Procedure(Procedure::Native("string->number")))
  // 継続
  let env = define_var(env, "call/cc", Value::Procedure(Procedure::Native("call/cc")))
  let env = define_var(env, "call-with-current-continuation", Value::Procedure(Procedure::Native("call-with-current-continuation")))
  env
}
