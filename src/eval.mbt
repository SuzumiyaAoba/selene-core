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
