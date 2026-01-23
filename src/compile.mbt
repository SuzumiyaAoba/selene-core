/// SExpr → IR コンパイラ
///
/// Scheme の S 式を中間表現 (IR) にコンパイルする。
/// レキシカルアドレッシングと末尾呼び出し最適化を行う。

/// コンパイル環境
/// ローカル変数のスコープを管理する
struct CompileEnv {
  /// 親環境
  parent : CompileEnv?
  /// 現在のフレームの変数名リスト
  locals : Array[String]
  /// グローバル変数のセット（組み込み関数など）
  globals : @hashmap.T[String, Unit]
}

/// 新しいコンパイル環境を作成する
fn new_compile_env(globals : @hashmap.T[String, Unit]) -> CompileEnv {
  { parent: None, locals: [], globals }
}

/// コンパイル環境を拡張する（新しいスコープに入る）
fn extend_compile_env(parent : CompileEnv, locals : Array[String]) -> CompileEnv {
  { parent: Some(parent), locals, globals: parent.globals }
}

/// 変数がローカルかどうかを調べ、VarRef を返す
fn lookup_local(env : CompileEnv, name : String) -> VarRef? {
  lookup_local_with_depth(env, name, 0)
}

/// 変数がローカルかどうかを調べ、深度付きで VarRef を返す
fn lookup_local_with_depth(env : CompileEnv, name : String, depth : Int) -> VarRef? {
  // 現在のフレームで検索
  let mut i = 0
  let len = env.locals.length()
  while i < len {
    if env.locals[i] == name {
      return Some({ name, depth, index: i })
    }
    i = i + 1
  }
  // 親環境で検索
  match env.parent {
    Some(parent) => lookup_local_with_depth(parent, name, depth + 1)
    None => None
  }
}

/// 変数がグローバルかどうかを調べる
fn is_global(env : CompileEnv, name : String) -> Bool {
  env.globals.contains(name)
}

/// 組み込み関数名をプリミティブ操作に変換する
fn name_to_primop(name : String) -> PrimOpKind? {
  match name {
    "+" => Some(PrimOpKind::Add)
    "-" => Some(PrimOpKind::Sub)
    "*" => Some(PrimOpKind::Mul)
    "/" => Some(PrimOpKind::Div)
    "quotient" => Some(PrimOpKind::Quotient)
    "remainder" => Some(PrimOpKind::Remainder)
    "modulo" => Some(PrimOpKind::Modulo)
    "abs" => Some(PrimOpKind::Abs)
    "max" => Some(PrimOpKind::Max)
    "min" => Some(PrimOpKind::Min)
    "gcd" => Some(PrimOpKind::Gcd)
    "lcm" => Some(PrimOpKind::Lcm)
    "=" => Some(PrimOpKind::NumEq)
    "<" => Some(PrimOpKind::Lt)
    ">" => Some(PrimOpKind::Gt)
    "<=" => Some(PrimOpKind::Le)
    ">=" => Some(PrimOpKind::Ge)
    "eq?" => Some(PrimOpKind::Eq)
    "eqv?" => Some(PrimOpKind::Eqv)
    "equal?" => Some(PrimOpKind::Equal)
    "zero?" => Some(PrimOpKind::ZeroP)
    "positive?" => Some(PrimOpKind::PositiveP)
    "negative?" => Some(PrimOpKind::NegativeP)
    "odd?" => Some(PrimOpKind::OddP)
    "even?" => Some(PrimOpKind::EvenP)
    "pair?" => Some(PrimOpKind::PairP)
    "number?" => Some(PrimOpKind::NumberP)
    "integer?" => Some(PrimOpKind::IntegerP)
    "real?" => Some(PrimOpKind::RealP)
    "boolean?" => Some(PrimOpKind::BooleanP)
    "symbol?" => Some(PrimOpKind::SymbolP)
    "null?" => Some(PrimOpKind::NullP)
    "procedure?" => Some(PrimOpKind::ProcedureP)
    "list?" => Some(PrimOpKind::ListP)
    "string?" => Some(PrimOpKind::StringP)
    "char?" => Some(PrimOpKind::CharP)
    "vector?" => Some(PrimOpKind::VectorP)
    "promise?" => Some(PrimOpKind::PromiseP)
    "port?" => Some(PrimOpKind::PortP)
    "cons" => Some(PrimOpKind::Cons)
    "car" => Some(PrimOpKind::Car)
    "cdr" => Some(PrimOpKind::Cdr)
    "set-car!" => Some(PrimOpKind::SetCar)
    "set-cdr!" => Some(PrimOpKind::SetCdr)
    "list" => Some(PrimOpKind::List)
    "length" => Some(PrimOpKind::Length)
    "append" => Some(PrimOpKind::Append)
    "reverse" => Some(PrimOpKind::Reverse)
    "list-ref" => Some(PrimOpKind::ListRef)
    "list-tail" => Some(PrimOpKind::ListTail)
    "char=?" => Some(PrimOpKind::CharEq)
    "char<?" => Some(PrimOpKind::CharLt)
    "char>?" => Some(PrimOpKind::CharGt)
    "char<=?" => Some(PrimOpKind::CharLe)
    "char>=?" => Some(PrimOpKind::CharGe)
    "char-alphabetic?" => Some(PrimOpKind::CharAlphabeticP)
    "char-numeric?" => Some(PrimOpKind::CharNumericP)
    "char-whitespace?" => Some(PrimOpKind::CharWhitespaceP)
    "char-upper-case?" => Some(PrimOpKind::CharUpperCaseP)
    "char-lower-case?" => Some(PrimOpKind::CharLowerCaseP)
    "char-upcase" => Some(PrimOpKind::CharUpcase)
    "char-downcase" => Some(PrimOpKind::CharDowncase)
    "char->integer" => Some(PrimOpKind::CharToInteger)
    "integer->char" => Some(PrimOpKind::IntegerToChar)
    "string-length" => Some(PrimOpKind::StringLength)
    "string-ref" => Some(PrimOpKind::StringRef)
    "string-append" => Some(PrimOpKind::StringAppend)
    "string=?" => Some(PrimOpKind::StringEq)
    "string<?" => Some(PrimOpKind::StringLt)
    "string>?" => Some(PrimOpKind::StringGt)
    "string<=?" => Some(PrimOpKind::StringLe)
    "string>=?" => Some(PrimOpKind::StringGe)
    "make-string" => Some(PrimOpKind::MakeString)
    "substring" => Some(PrimOpKind::Substring)
    "string->list" => Some(PrimOpKind::StringToList)
    "list->string" => Some(PrimOpKind::ListToString)
    "make-vector" => Some(PrimOpKind::MakeVector)
    "vector" => Some(PrimOpKind::Vector)
    "vector-length" => Some(PrimOpKind::VectorLength)
    "vector-ref" => Some(PrimOpKind::VectorRef)
    "vector-set!" => Some(PrimOpKind::VectorSet)
    "vector->list" => Some(PrimOpKind::VectorToList)
    "list->vector" => Some(PrimOpKind::ListToVector)
    "floor" => Some(PrimOpKind::Floor)
    "ceiling" => Some(PrimOpKind::Ceiling)
    "truncate" => Some(PrimOpKind::Truncate)
    "round" => Some(PrimOpKind::Round)
    "sqrt" => Some(PrimOpKind::Sqrt)
    "expt" => Some(PrimOpKind::Expt)
    "sin" => Some(PrimOpKind::Sin)
    "cos" => Some(PrimOpKind::Cos)
    "tan" => Some(PrimOpKind::Tan)
    "asin" => Some(PrimOpKind::Asin)
    "acos" => Some(PrimOpKind::Acos)
    "atan" => Some(PrimOpKind::Atan)
    "exp" => Some(PrimOpKind::Exp)
    "log" => Some(PrimOpKind::Log)
    "number->string" => Some(PrimOpKind::NumberToString)
    "string->number" => Some(PrimOpKind::StringToNumber)
    "symbol->string" => Some(PrimOpKind::SymbolToString)
    "string->symbol" => Some(PrimOpKind::StringToSymbol)
    "not" => Some(PrimOpKind::Not)
    "make-rectangular" => Some(PrimOpKind::MakeRectangular)
    "make-polar" => Some(PrimOpKind::MakePolar)
    "real-part" => Some(PrimOpKind::RealPart)
    "imag-part" => Some(PrimOpKind::ImagPart)
    "magnitude" => Some(PrimOpKind::Magnitude)
    "angle" => Some(PrimOpKind::Angle)
    "complex?" => Some(PrimOpKind::ComplexP)
    "numerator" => Some(PrimOpKind::Numerator)
    "denominator" => Some(PrimOpKind::Denominator)
    "rational?" => Some(PrimOpKind::RationalP)
    "exact?" => Some(PrimOpKind::ExactP)
    "inexact?" => Some(PrimOpKind::InexactP)
    "display" => Some(PrimOpKind::Display)
    "newline" => Some(PrimOpKind::Newline)
    "write" => Some(PrimOpKind::Write)
    "read" => Some(PrimOpKind::Read)
    "input-port?" => Some(PrimOpKind::InputPortP)
    "output-port?" => Some(PrimOpKind::OutputPortP)
    "open-input-file" => Some(PrimOpKind::OpenInputFile)
    "open-output-file" => Some(PrimOpKind::OpenOutputFile)
    "close-input-port" => Some(PrimOpKind::CloseInputPort)
    "close-output-port" => Some(PrimOpKind::CloseOutputPort)
    "read-char" => Some(PrimOpKind::ReadChar)
    "peek-char" => Some(PrimOpKind::PeekChar)
    "write-char" => Some(PrimOpKind::WriteChar)
    "eof-object?" => Some(PrimOpKind::EofObjectP)
    "apply" => Some(PrimOpKind::Apply)
    "map" => Some(PrimOpKind::Map)
    "for-each" => Some(PrimOpKind::ForEach)
    "filter" => Some(PrimOpKind::Filter)
    "fold-left" => Some(PrimOpKind::FoldLeft)
    "fold-right" => Some(PrimOpKind::FoldRight)
    "force" => Some(PrimOpKind::Force)
    "values" => Some(PrimOpKind::Values)
    "call-with-values" => Some(PrimOpKind::CallWithValues)
    "dynamic-wind" => Some(PrimOpKind::DynamicWind)
    "assq" => Some(PrimOpKind::Assq)
    "assv" => Some(PrimOpKind::Assv)
    "assoc" => Some(PrimOpKind::Assoc)
    "memq" => Some(PrimOpKind::Memq)
    "memv" => Some(PrimOpKind::Memv)
    "member" => Some(PrimOpKind::Member)
    "caar" => Some(PrimOpKind::Caar)
    "cadr" => Some(PrimOpKind::Cadr)
    "cdar" => Some(PrimOpKind::Cdar)
    "cddr" => Some(PrimOpKind::Cddr)
    "caaar" => Some(PrimOpKind::Caaar)
    "caadr" => Some(PrimOpKind::Caadr)
    "cadar" => Some(PrimOpKind::Cadar)
    "caddr" => Some(PrimOpKind::Caddr)
    "cdaar" => Some(PrimOpKind::Cdaar)
    "cdadr" => Some(PrimOpKind::Cdadr)
    "cddar" => Some(PrimOpKind::Cddar)
    "cdddr" => Some(PrimOpKind::Cdddr)
    _ => None
  }
}

/// グローバル環境の初期化（組み込み関数名を登録）
pub fn initial_globals() -> @hashmap.T[String, Unit] {
  let globals : @hashmap.T[String, Unit] = @hashmap.new()
  // 算術演算
  globals.set("+", ())
  globals.set("-", ())
  globals.set("*", ())
  globals.set("/", ())
  globals.set("quotient", ())
  globals.set("remainder", ())
  globals.set("modulo", ())
  globals.set("abs", ())
  globals.set("max", ())
  globals.set("min", ())
  globals.set("gcd", ())
  globals.set("lcm", ())
  // 比較
  globals.set("=", ())
  globals.set("<", ())
  globals.set(">", ())
  globals.set("<=", ())
  globals.set(">=", ())
  globals.set("eq?", ())
  globals.set("eqv?", ())
  globals.set("equal?", ())
  // 述語
  globals.set("zero?", ())
  globals.set("positive?", ())
  globals.set("negative?", ())
  globals.set("odd?", ())
  globals.set("even?", ())
  globals.set("pair?", ())
  globals.set("number?", ())
  globals.set("integer?", ())
  globals.set("real?", ())
  globals.set("boolean?", ())
  globals.set("symbol?", ())
  globals.set("null?", ())
  globals.set("procedure?", ())
  globals.set("list?", ())
  globals.set("string?", ())
  globals.set("char?", ())
  globals.set("vector?", ())
  globals.set("promise?", ())
  globals.set("port?", ())
  // リスト
  globals.set("cons", ())
  globals.set("car", ())
  globals.set("cdr", ())
  globals.set("set-car!", ())
  globals.set("set-cdr!", ())
  globals.set("list", ())
  globals.set("length", ())
  globals.set("append", ())
  globals.set("reverse", ())
  globals.set("list-ref", ())
  globals.set("list-tail", ())
  // 文字
  globals.set("char=?", ())
  globals.set("char<?", ())
  globals.set("char>?", ())
  globals.set("char<=?", ())
  globals.set("char>=?", ())
  globals.set("char-alphabetic?", ())
  globals.set("char-numeric?", ())
  globals.set("char-whitespace?", ())
  globals.set("char-upper-case?", ())
  globals.set("char-lower-case?", ())
  globals.set("char-upcase", ())
  globals.set("char-downcase", ())
  globals.set("char->integer", ())
  globals.set("integer->char", ())
  // 文字列
  globals.set("string-length", ())
  globals.set("string-ref", ())
  globals.set("string-append", ())
  globals.set("string=?", ())
  globals.set("string<?", ())
  globals.set("string>?", ())
  globals.set("string<=?", ())
  globals.set("string>=?", ())
  globals.set("make-string", ())
  globals.set("substring", ())
  globals.set("string->list", ())
  globals.set("list->string", ())
  // ベクトル
  globals.set("make-vector", ())
  globals.set("vector", ())
  globals.set("vector-length", ())
  globals.set("vector-ref", ())
  globals.set("vector-set!", ())
  globals.set("vector->list", ())
  globals.set("list->vector", ())
  // 数学
  globals.set("floor", ())
  globals.set("ceiling", ())
  globals.set("truncate", ())
  globals.set("round", ())
  globals.set("sqrt", ())
  globals.set("expt", ())
  globals.set("sin", ())
  globals.set("cos", ())
  globals.set("tan", ())
  globals.set("asin", ())
  globals.set("acos", ())
  globals.set("atan", ())
  globals.set("exp", ())
  globals.set("log", ())
  // 変換
  globals.set("number->string", ())
  globals.set("string->number", ())
  globals.set("symbol->string", ())
  globals.set("string->symbol", ())
  // 論理
  globals.set("not", ())
  // 複素数
  globals.set("make-rectangular", ())
  globals.set("make-polar", ())
  globals.set("real-part", ())
  globals.set("imag-part", ())
  globals.set("magnitude", ())
  globals.set("angle", ())
  globals.set("complex?", ())
  // 有理数
  globals.set("numerator", ())
  globals.set("denominator", ())
  globals.set("rational?", ())
  globals.set("exact?", ())
  globals.set("inexact?", ())
  // I/O
  globals.set("display", ())
  globals.set("newline", ())
  globals.set("write", ())
  globals.set("read", ())
  // ポート
  globals.set("input-port?", ())
  globals.set("output-port?", ())
  globals.set("open-input-file", ())
  globals.set("open-output-file", ())
  globals.set("close-input-port", ())
  globals.set("close-output-port", ())
  globals.set("read-char", ())
  globals.set("peek-char", ())
  globals.set("write-char", ())
  globals.set("eof-object?", ())
  // 高階
  globals.set("apply", ())
  globals.set("map", ())
  globals.set("for-each", ())
  globals.set("filter", ())
  globals.set("fold-left", ())
  globals.set("fold-right", ())
  globals.set("force", ())
  globals.set("values", ())
  globals.set("call-with-values", ())
  globals.set("dynamic-wind", ())
  // 連想リスト
  globals.set("assq", ())
  globals.set("assv", ())
  globals.set("assoc", ())
  globals.set("memq", ())
  globals.set("memv", ())
  globals.set("member", ())
  // cXXr
  globals.set("caar", ())
  globals.set("cadr", ())
  globals.set("cdar", ())
  globals.set("cddr", ())
  globals.set("caaar", ())
  globals.set("caadr", ())
  globals.set("cadar", ())
  globals.set("caddr", ())
  globals.set("cdaar", ())
  globals.set("cdadr", ())
  globals.set("cddar", ())
  globals.set("cdddr", ())
  // 継続
  globals.set("call/cc", ())
  globals.set("call-with-current-continuation", ())
  globals
}

/// SExpr を IR にコンパイルする
/// tail: 末尾位置かどうか
pub fn compile(
  expr : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match expr {
    // 自己評価式
    SExpr::Number(n) => Ok(IRExpr::Const(IRConst::Int(n)))
    SExpr::Bool(b) => Ok(IRExpr::Const(IRConst::Bool(b)))
    SExpr::Char(c) => Ok(IRExpr::Const(IRConst::Char(c)))
    SExpr::String(s) => Ok(IRExpr::Const(IRConst::String(s)))
    SExpr::Nil => Ok(IRExpr::Const(IRConst::Nil))

    // 変数参照
    SExpr::Symbol(name) => compile_var_ref(name, env)

    // quote
    SExpr::Quote(inner) => Ok(IRExpr::Quote(sexpr_to_ir_const(inner)))

    // ベクトル（自己評価）
    SExpr::Vector(items) => {
      let ir_items : Array[IRConst] = []
      for item in items {
        ir_items.push(sexpr_to_ir_const(item))
      }
      Ok(IRExpr::Const(IRConst::Vector(ir_items)))
    }

    // リスト（特殊形式または関数適用）
    SExpr::Pair(car, cdr) => compile_pair(car, cdr, env, tail)

    // quasiquote
    SExpr::Quasiquote(_) =>
      Err(CompileError::Unsupported("quasiquote in compiler"))
    SExpr::Unquote(_) =>
      Err(CompileError::SyntaxError("unquote outside quasiquote"))
    SExpr::UnquoteSplicing(_) =>
      Err(CompileError::SyntaxError("unquote-splicing outside quasiquote"))
  }
}

/// 変数参照をコンパイルする
fn compile_var_ref(name : String, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match lookup_local(env, name) {
    Some(var_ref) => Ok(IRExpr::Var(var_ref))
    None =>
      if is_global(env, name) {
        Ok(IRExpr::GlobalVar(name))
      } else {
        // 未定義の変数もグローバルとして扱う（後でエラーになる可能性あり）
        Ok(IRExpr::GlobalVar(name))
      }
  }
}

/// ペア（リスト）をコンパイルする
fn compile_pair(
  car : SExpr,
  cdr : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match car {
    // 特殊形式
    SExpr::Symbol("if") => compile_if(cdr, env, tail)
    SExpr::Symbol("lambda") => compile_lambda(cdr, env)
    SExpr::Symbol("begin") => compile_begin(cdr, env, tail)
    SExpr::Symbol("and") => compile_and(cdr, env, tail)
    SExpr::Symbol("or") => compile_or(cdr, env, tail)
    SExpr::Symbol("let") => compile_let(cdr, env, tail)
    SExpr::Symbol("let*") => compile_let_star(cdr, env, tail)
    SExpr::Symbol("letrec") => compile_letrec(cdr, env, tail)
    SExpr::Symbol("set!") => compile_set(cdr, env)
    SExpr::Symbol("quote") => compile_quote(cdr)
    SExpr::Symbol("delay") => compile_delay(cdr, env)
    SExpr::Symbol("call/cc") | SExpr::Symbol("call-with-current-continuation") =>
      compile_call_cc(cdr, env, tail)
    SExpr::Symbol("define") =>
      Err(CompileError::SyntaxError("define not allowed in expression context"))
    SExpr::Symbol("define-syntax") =>
      Err(CompileError::SyntaxError("define-syntax not allowed in expression context"))

    // 関数適用
    _ => compile_application(car, cdr, env, tail)
  }
}

/// if 式をコンパイルする
fn compile_if(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(test_expr, SExpr::Pair(then_expr, rest)) => {
      let test_ir = match compile(test_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      let then_ir = match compile(then_expr, env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      let else_ir = match rest {
        SExpr::Pair(else_expr, SExpr::Nil) =>
          match compile(else_expr, env, tail) {
            Ok(ir) => ir
            Err(e) => return Err(e)
          }
        SExpr::Nil => IRExpr::Const(IRConst::Nil)
        _ => return Err(CompileError::SyntaxError("if: invalid syntax"))
      }
      Ok(IRExpr::If(test_ir, then_ir, else_ir))
    }
    _ => Err(CompileError::SyntaxError("if: requires at least 2 arguments"))
  }
}

/// lambda 式をコンパイルする
fn compile_lambda(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(params_expr, body_rest) => {
      // パラメータを抽出
      let params = match extract_params(params_expr) {
        Ok(p) => p
        Err(e) => return Err(e)
      }
      // 新しい環境でボディをコンパイル
      let new_env = extend_compile_env(env, params.copy())
      // ボディを begin としてコンパイル（末尾位置）
      let body_ir = match compile_body(body_rest, new_env, true) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      // 自由変数を収集
      let free_vars = collect_free_vars(body_ir, params)
      Ok(IRExpr::Lambda({
        params,
        arity: params.length(),
        body: body_ir,
        free_vars,
      }))
    }
    _ => Err(CompileError::SyntaxError("lambda: invalid syntax"))
  }
}

/// パラメータリストを抽出する
fn extract_params(params : SExpr) -> Result[Array[String], CompileError] {
  let names : Array[String] = []
  let mut current = params
  while true {
    match current {
      SExpr::Nil => return Ok(names)
      SExpr::Pair(SExpr::Symbol(name), rest) => {
        names.push(name)
        current = rest
      }
      SExpr::Symbol(_) =>
        // 可変長引数はまだサポートしない
        return Err(CompileError::Unsupported("rest parameter"))
      _ => return Err(CompileError::SyntaxError("lambda: invalid parameter"))
    }
  }
  Ok(names)
}

/// ボディ（式のリスト）をコンパイルする
fn compile_body(
  body : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  let exprs : Array[SExpr] = []
  let mut current = body
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(expr, rest) => {
        exprs.push(expr)
        current = rest
      }
      _ => return Err(CompileError::SyntaxError("invalid body"))
    }
  }
  if exprs.length() == 0 {
    return Err(CompileError::SyntaxError("empty body"))
  }
  if exprs.length() == 1 {
    return compile(exprs[0], env, tail)
  }
  // 複数の式は begin として扱う
  let ir_exprs : Array[IRExpr] = []
  let len = exprs.length()
  let mut i = 0
  while i < len {
    let is_tail = tail && i == len - 1
    let ir = match compile(exprs[i], env, is_tail) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    ir_exprs.push(ir)
    i = i + 1
  }
  Ok(IRExpr::Begin(ir_exprs))
}

/// begin 式をコンパイルする
fn compile_begin(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  compile_body(args, env, tail)
}

/// and 式をコンパイルする
fn compile_and(
  args : SExpr,
  env : CompileEnv,
  _tail : Bool
) -> Result[IRExpr, CompileError] {
  let exprs : Array[SExpr] = []
  let mut current = args
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(expr, rest) => {
        exprs.push(expr)
        current = rest
      }
      _ => return Err(CompileError::SyntaxError("and: invalid syntax"))
    }
  }
  if exprs.length() == 0 {
    return Ok(IRExpr::Const(IRConst::Bool(true)))
  }
  let ir_exprs : Array[IRExpr] = []
  for expr in exprs {
    let ir = match compile(expr, env, false) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    ir_exprs.push(ir)
  }
  Ok(IRExpr::And(ir_exprs))
}

/// or 式をコンパイルする
fn compile_or(
  args : SExpr,
  env : CompileEnv,
  _tail : Bool
) -> Result[IRExpr, CompileError] {
  let exprs : Array[SExpr] = []
  let mut current = args
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(expr, rest) => {
        exprs.push(expr)
        current = rest
      }
      _ => return Err(CompileError::SyntaxError("or: invalid syntax"))
    }
  }
  if exprs.length() == 0 {
    return Ok(IRExpr::Const(IRConst::Bool(false)))
  }
  let ir_exprs : Array[IRExpr] = []
  for expr in exprs {
    let ir = match compile(expr, env, false) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    ir_exprs.push(ir)
  }
  Ok(IRExpr::Or(ir_exprs))
}

/// let 式をコンパイルする
fn compile_let(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      let bindings = match parse_let_bindings(bindings_expr, env) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      // 新しい環境を作成
      let names : Array[String] = []
      for b in bindings {
        names.push(b.name)
      }
      let new_env = extend_compile_env(env, names)
      // ボディをコンパイル
      let body_ir = match compile_body(body, new_env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Let(bindings, body_ir))
    }
    _ => Err(CompileError::SyntaxError("let: invalid syntax"))
  }
}

/// let バインディングをパースする
fn parse_let_bindings(
  bindings_expr : SExpr,
  env : CompileEnv
) -> Result[Array[LetBinding], CompileError] {
  let bindings : Array[LetBinding] = []
  let mut current = bindings_expr
  while true {
    match current {
      SExpr::Nil => return Ok(bindings)
      SExpr::Pair(binding, rest) => {
        match binding {
          SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, SExpr::Nil)) => {
            let init_ir = match compile(init_expr, env, false) {
              Ok(ir) => ir
              Err(e) => return Err(e)
            }
            bindings.push({ name, init: init_ir })
            current = rest
          }
          _ => return Err(CompileError::SyntaxError("let: invalid binding"))
        }
      }
      _ => return Err(CompileError::SyntaxError("let: bindings must be a list"))
    }
  }
  Ok(bindings)
}

/// let* 式をコンパイルする
fn compile_let_star(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // let* はネストした let に変換
      compile_let_star_bindings(bindings_expr, body, env, tail)
    }
    _ => Err(CompileError::SyntaxError("let*: invalid syntax"))
  }
}

/// let* バインディングを再帰的に処理する
fn compile_let_star_bindings(
  bindings_expr : SExpr,
  body : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match bindings_expr {
    SExpr::Nil => compile_body(body, env, tail)
    SExpr::Pair(binding, rest) => {
      match binding {
        SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, SExpr::Nil)) => {
          let init_ir = match compile(init_expr, env, false) {
            Ok(ir) => ir
            Err(e) => return Err(e)
          }
          let new_env = extend_compile_env(env, [name])
          let body_ir = match compile_let_star_bindings(rest, body, new_env, tail) {
            Ok(ir) => ir
            Err(e) => return Err(e)
          }
          Ok(IRExpr::Let([{ name, init: init_ir }], body_ir))
        }
        _ => Err(CompileError::SyntaxError("let*: invalid binding"))
      }
    }
    _ => Err(CompileError::SyntaxError("let*: bindings must be a list"))
  }
}

/// letrec 式をコンパイルする
fn compile_letrec(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // まず変数名を収集
      let names : Array[String] = []
      let mut current = bindings_expr
      while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(SExpr::Pair(SExpr::Symbol(name), _), rest) => {
            names.push(name)
            current = rest
          }
          _ => return Err(CompileError::SyntaxError("letrec: invalid binding"))
        }
      }
      // 新しい環境を作成（すべての変数が見える）
      let new_env = extend_compile_env(env, names.copy())
      // バインディングをパース（新しい環境で）
      let bindings = match parse_let_bindings(bindings_expr, new_env) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      // ボディをコンパイル
      let body_ir = match compile_body(body, new_env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Letrec(bindings, body_ir))
    }
    _ => Err(CompileError::SyntaxError("letrec: invalid syntax"))
  }
}

/// set! 式をコンパイルする
fn compile_set(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil)) => {
      let value_ir = match compile(value_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      match lookup_local(env, name) {
        Some(var_ref) => Ok(IRExpr::Set(var_ref, value_ir))
        None => Ok(IRExpr::GlobalSet(name, value_ir))
      }
    }
    _ => Err(CompileError::SyntaxError("set!: invalid syntax"))
  }
}

/// quote 式をコンパイルする
fn compile_quote(args : SExpr) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(datum, SExpr::Nil) => Ok(IRExpr::Quote(sexpr_to_ir_const(datum)))
    _ => Err(CompileError::SyntaxError("quote: requires exactly one argument"))
  }
}

/// delay 式をコンパイルする
fn compile_delay(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(expr, SExpr::Nil) => {
      let ir = match compile(expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Delay(ir))
    }
    _ => Err(CompileError::SyntaxError("delay: requires exactly one argument"))
  }
}

/// call/cc 式をコンパイルする
fn compile_call_cc(
  args : SExpr,
  env : CompileEnv,
  _tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(proc_expr, SExpr::Nil) => {
      let proc_ir = match compile(proc_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::CallCC(proc_ir))
    }
    _ => Err(CompileError::SyntaxError("call/cc: requires exactly one argument"))
  }
}

/// 関数適用をコンパイルする
fn compile_application(
  op : SExpr,
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  // 演算子をコンパイル
  let op_ir = match compile(op, env, false) {
    Ok(ir) => ir
    Err(e) => return Err(e)
  }

  // 引数をコンパイル
  let arg_irs : Array[IRExpr] = []
  let mut current = args
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(arg_expr, rest) => {
        let arg_ir = match compile(arg_expr, env, false) {
          Ok(ir) => ir
          Err(e) => return Err(e)
        }
        arg_irs.push(arg_ir)
        current = rest
      }
      _ => return Err(CompileError::SyntaxError("invalid argument list"))
    }
  }

  // プリミティブ操作への最適化
  match op {
    SExpr::Symbol(name) =>
      match name_to_primop(name) {
        Some(primop) => return Ok(IRExpr::PrimOp(primop, arg_irs))
        None => ()
      }
    _ => ()
  }

  // 末尾呼び出しかどうかで分岐
  if tail {
    Ok(IRExpr::TailApp(op_ir, arg_irs))
  } else {
    Ok(IRExpr::App(op_ir, arg_irs))
  }
}

/// 自由変数を収集する（簡易版）
fn collect_free_vars(_body : IRExpr, _bound : Array[String]) -> Array[VarRef] {
  // TODO: 本格的な自由変数解析を実装
  []
}

/// トップレベルの式をコンパイルする
pub fn compile_toplevel(expr : SExpr) -> Result[IRExpr, CompileError] {
  let globals = initial_globals()
  let env = new_compile_env(globals)
  compile_toplevel_expr(expr, env)
}

/// トップレベル式をコンパイルする（define をサポート）
fn compile_toplevel_expr(expr : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match expr {
    // (define name value)
    SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
      let value_ir = match compile(value_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::GlobalSet(name, value_ir))
    }
    // (define (name params...) body...)
    SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Pair(SExpr::Symbol(name), params), body)) => {
      // (define (f x y) body) => (define f (lambda (x y) body))
      let lambda_expr = SExpr::Pair(
        SExpr::Symbol("lambda"),
        SExpr::Pair(params, body),
      )
      let lambda_ir = match compile(lambda_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::GlobalSet(name, lambda_ir))
    }
    // 通常の式
    _ => compile(expr, env, false)
  }
}

/// 外部グローバル環境を使用してトップレベル式をコンパイルする
pub fn compile_toplevel_with_globals(
  expr : SExpr,
  globals : @hashmap.T[String, Unit]
) -> Result[IRExpr, CompileError] {
  let env = new_compile_env(globals)
  compile_toplevel_expr(expr, env)
}
