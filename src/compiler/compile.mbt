/// SExpr → IR compiler
///
/// Compile a Scheme S-expression into an intermediate representation (IR).
/// Performs lexical addressing and tail call optimization.

/// compilation environment
/// Manage the scope of local variables
struct CompileEnv {
  /// parent environment
  parent : CompileEnv?
  /// Variable name list for current frame
  locals : Array[String]
  /// a set of global variables (such as built-in functions)
  globals : @hashmap.T[String, Unit]
}

/// Create a new compilation environment
fn new_compile_env(globals : @hashmap.T[String, Unit]) -> CompileEnv {
  { parent: None, locals: [], globals }
}

/// Extend the compilation environment (enter a new scope)
fn extend_compile_env(parent : CompileEnv, locals : Array[String]) -> CompileEnv {
  { parent: Some(parent), locals, globals: parent.globals }
}

/// Extend the current frame (let/letrec). Keeps the same call frame depth.
fn extend_compile_env_same_frame(parent : CompileEnv, locals : Array[String]) -> CompileEnv {
  let combined : Array[String] = parent.locals.copy()
  for name in locals {
    combined.push(name)
  }
  { parent: parent.parent, locals: combined, globals: parent.globals }
}

/// Check if variable is local and return VarRef
fn lookup_local(env : CompileEnv, name : String) -> VarRef? {
  lookup_local_with_depth(env, name, 0)
}

/// Check if variable is local and return VarRef with depth
fn lookup_local_with_depth(env : CompileEnv, name : String, depth : Int) -> VarRef? {
  // Search in current frame
  let mut i = env.locals.length()
  while i > 0 {
    i = i - 1
    if env.locals[i] == name {
      return Some({ name, depth, index: i })
    }
  }
  // Search in parent environment
  match env.parent {
    Some(parent) => lookup_local_with_depth(parent, name, depth + 1)
    None => None
  }
}

/// Check if variable is global
fn is_global(env : CompileEnv, name : String) -> Bool {
  env.globals.contains(name)
}

/// Check if a name is shadowed by a local variable in the current scope
fn is_shadowed(env : CompileEnv, name : String) -> Bool {
  for local in env.locals {
    if local == name {
      return true
    }
  }
  false
}

/// Convert built-in function names to primitive operations
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
    // map/for-each are defined as Scheme prelude functions (not PrimOps)
    // so they run in the main VM and call/cc works correctly inside them
    "map" => None
    "for-each" => None
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

/// Initializing the global environment (registering built-in function names)
pub fn initial_globals() -> @hashmap.T[String, Unit] {
  let globals : @hashmap.T[String, Unit] = @hashmap.new()
  // Arithmetic operations
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
  // comparison
  globals.set("=", ())
  globals.set("<", ())
  globals.set(">", ())
  globals.set("<=", ())
  globals.set(">=", ())
  globals.set("eq?", ())
  globals.set("eqv?", ())
  globals.set("equal?", ())
  // predicate
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
  // list
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
  // character
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
  // string
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
  // vector
  globals.set("make-vector", ())
  globals.set("vector", ())
  globals.set("vector-length", ())
  globals.set("vector-ref", ())
  globals.set("vector-set!", ())
  globals.set("vector->list", ())
  globals.set("list->vector", ())
  // mathematics
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
  // Conversion
  globals.set("number->string", ())
  globals.set("string->number", ())
  globals.set("symbol->string", ())
  globals.set("string->symbol", ())
  // logic
  globals.set("not", ())
  // Complex number
  globals.set("make-rectangular", ())
  globals.set("make-polar", ())
  globals.set("real-part", ())
  globals.set("imag-part", ())
  globals.set("magnitude", ())
  globals.set("angle", ())
  globals.set("complex?", ())
  // Set of rational numbers
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
  // Port
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
  // Takashina
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
  // Associations List
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
  // continuation
  globals.set("call/cc", ())
  globals.set("call-with-current-continuation", ())
  globals
}

/// Compile SExpr to IR
/// tail: whether it is the tail position
pub fn compile(
  expr : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match expr {
    // self-assessment
    SExpr::Number(n) => Ok(IRExpr::Const(IRConst::Int(n)))
    SExpr::Bool(b) => Ok(IRExpr::Const(IRConst::Bool(b)))
    SExpr::Char(c) => Ok(IRExpr::Const(IRConst::Char(c)))
    SExpr::String(s) => Ok(IRExpr::Const(IRConst::String(s)))
    SExpr::Nil => Ok(IRExpr::Const(IRConst::Nil))

    // variable reference
    SExpr::Symbol(name) => compile_var_ref(name, env)

    // quote (check for shadowing)
    SExpr::Quote(inner) => {
      if is_shadowed(env, "quote") {
        // quote is shadowed, treat as function application: (quote inner)
        let quote_symbol = SExpr::Symbol("quote")
        let args = SExpr::Pair(inner, SExpr::Nil)
        compile_pair(quote_symbol, args, env, tail)
      } else {
        // quote is not shadowed, use the built-in quote
        Ok(IRExpr::Quote(sexpr_to_ir_const(inner)))
      }
    }

    // Vector (self-evaluation)
    SExpr::Vector(items) => {
      let ir_items : Array[IRConst] = []
      for item in items {
        ir_items.push(sexpr_to_ir_const(item))
      }
      Ok(IRExpr::Const(IRConst::Vector(ir_items)))
    }

    // list (special form or function applied)
    SExpr::Pair(car, cdr) => compile_pair(car, cdr, env, tail)

    // quasiquote
    SExpr::Quasiquote(inner) => compile_quasiquote(inner, env, 0)
    SExpr::Unquote(_) =>
      Err(CompileError::SyntaxError("unquote outside quasiquote"))
    SExpr::UnquoteSplicing(_) =>
      Err(CompileError::SyntaxError("unquote-splicing outside quasiquote"))
  }
}

/// Compile variable references
fn compile_var_ref(name : String, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match lookup_local(env, name) {
    Some(var_ref) => Ok(IRExpr::Var(var_ref))
    None =>
      if is_global(env, name) {
        Ok(IRExpr::GlobalVar(name))
      } else {
        // Treat undefined variables as global (possibly an error later)
        Ok(IRExpr::GlobalVar(name))
      }
  }
}

/// Compile pairs (lists)
fn compile_pair(
  car : SExpr,
  cdr : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match car {
    // special format (but check for shadowing first)
    SExpr::Symbol(name) if !is_shadowed(env, name) => {
      match name {
        "if" => compile_if(cdr, env, tail)
        "lambda" => compile_lambda(cdr, env)
        "begin" => compile_begin(cdr, env, tail)
        "and" => compile_and(cdr, env, tail)
        "or" => compile_or(cdr, env, tail)
        "cond" => compile_cond(cdr, env, tail)
        "case" => compile_case(cdr, env, tail)
        "let" => compile_let(cdr, env, tail)
        "let*" => compile_let_star(cdr, env, tail)
        "letrec" => compile_letrec(cdr, env, tail)
        "do" => compile_do(cdr, env, tail)
        "set!" => compile_set(cdr, env)
        "quote" => compile_quote(cdr)
        "quasiquote" => compile_quasiquote_form(cdr, env)
        "delay" => compile_delay(cdr, env)
        "call/cc" | "call-with-current-continuation" =>
          compile_call_cc(cdr, env, tail)
        "define" =>
          Err(CompileError::SyntaxError("define not allowed in expression context"))
        "define-syntax" =>
          Err(CompileError::SyntaxError("define-syntax not allowed in expression context"))
        _ => compile_application(car, cdr, env, tail)
      }
    }

    // function application (includes shadowed special forms)
    _ => compile_application(car, cdr, env, tail)
  }
}

/// Compile the if expression
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

/// Compile lambda expressions
fn compile_lambda(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(params_expr, body_rest) => {
      // extract parameters
      let params_result = match extract_params(params_expr) {
        Ok(p) => p
        Err(e) => return Err(e)
      }

      // Build full parameter list including rest param for environment
      let all_params = params_result.params.copy()
      match params_result.rest_param {
        Some(rest_name) => all_params.push(rest_name)
        None => ()
      }

      // Compile the body in the new environment
      let new_env = extend_compile_env(env, all_params.copy())
      // Compile body as begin (tail position)
      let body_ir = match compile_body(body_rest, new_env, true) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      // Collect free variables (depth remains the same)
      let free_vars = collect_free_vars(body_ir, all_params)

      // Set! Collect variables to be set!
      let set_vars = collect_set_vars(body_ir)
      // Determine which parameters require boxing
      let boxed_params : Array[Int] = []
      let mut i = 0
      while i < all_params.length() {
        if needs_boxing(all_params[i], free_vars, set_vars) {
          boxed_params.push(i)
        }
        i = i + 1
      }
      // Determine local variables that require boxing (Let/Letrec)
      // Note: Free variables are captured values ​​and will not be added to boxed_locals here
      // boxed_locals is for let/letrec bound variables defined inside lambda
      let boxed_locals : Array[String] = []
      // TODO: Parse local variables (processed separately in Let/Letrec)

      // Determine which free variables require boxing
      let boxed_free_vars : Array[Int] = []
      let mut j = 0
      while j < free_vars.length() {
        let free_var = free_vars[j]
        // Check if this free variable is set! anywhere in the lambda body
        // This is important for shared mutable state across closures
        for sv in set_vars {
          if sv == free_var.name {
            boxed_free_vars.push(j)
            break
          }
        }
        j = j + 1
      }

      Ok(IRExpr::Lambda({
        params: all_params,
        arity: params_result.params.length(),
        rest_param: params_result.rest_param,
        body: body_ir,
        free_vars,
        boxed_params,
        boxed_locals,
        boxed_free_vars,
      }))
    }
    _ => Err(CompileError::SyntaxError("lambda: invalid syntax"))
  }
}

/// Result of parameter extraction
struct ParamsResult {
  /// Required parameter names
  params : Array[String]
  /// Rest parameter name (if any)
  rest_param : String?
}

/// Extract parameter list
/// Supports:
///   (lambda (a b c) ...) - fixed arity
///   (lambda args ...) - all args collected into list
///   (lambda (a b . rest) ...) - required args + rest list
fn extract_params(params_expr : SExpr) -> Result[ParamsResult, CompileError] {
  match params_expr {
    // (lambda args ...) - single symbol, all args collected
    SExpr::Symbol(name) =>
      Ok({ params: [], rest_param: Some(name) })
    // (lambda () ...) or (lambda (a b ...) ...)
    _ => {
      let names : Array[String] = []
      let mut current = params_expr
      while true {
        match current {
          SExpr::Nil => return Ok({ params: names, rest_param: None })
          SExpr::Pair(SExpr::Symbol(name), rest) => {
            names.push(name)
            current = rest
          }
          // Improper list: (a b . rest)
          SExpr::Symbol(rest_name) =>
            return Ok({ params: names, rest_param: Some(rest_name) })
          _ => return Err(CompileError::SyntaxError("lambda: invalid parameter"))
        }
      }
      Ok({ params: names, rest_param: None })
    }
  }
}

/// Compile the body (list of expressions)
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

  // Splice begin forms at the beginning of the body (R5RS 5.2.2)
  // (begin (define ...) ...) at body start is equivalent to (define ...)
  // Only splice if "begin" is the keyword, not a variable binding
  let begin_is_keyword = lookup_local(env, "begin").is_empty()
  let spliced_exprs : Array[SExpr] = []
  let mut splice_done = false
  for expr in exprs {
    if not(splice_done) {
      match expr {
        SExpr::Pair(SExpr::Symbol("begin"), begin_body) if begin_is_keyword => {
          // Splice begin contents
          let mut current = begin_body
          let _ = while true {
            match current {
              SExpr::Pair(item, rest) => {
                spliced_exprs.push(item)
                current = rest
              }
              _ => break
            }
          } else { () }
          continue
        }
        SExpr::Pair(SExpr::Symbol("define"), _) => {
          spliced_exprs.push(expr)
          continue
        }
        _ => {
          splice_done = true
          spliced_exprs.push(expr)
        }
      }
    } else {
      spliced_exprs.push(expr)
    }
  }
  let exprs = spliced_exprs

  // Check for internal defines at the beginning of the body
  let defines : Array[(String, SExpr)] = []  // (name, init_expr)
  let mut body_start = 0

  let mut i = 0
  let _ = while i < exprs.length() {
    match exprs[i] {
      SExpr::Pair(SExpr::Symbol("define"), def_rest) => {
        // Parse the define
        match parse_internal_define(def_rest) {
          Ok((name, init)) => {
            defines.push((name, init))
            body_start = i + 1
            i = i + 1
          }
          Err(e) => return Err(e)
        }
      }
      _ => break ()  // Stop at first non-define
    }
  } else {
    ()
  }

  // If there are internal defines, convert to letrec
  if defines.length() > 0 {
    // Ensure there is at least one expression after defines
    if body_start >= exprs.length() {
      return Err(CompileError::SyntaxError("body must have at least one expression after defines"))
    }

    // Build letrec bindings
    let bindings : Array[LetBinding] = []
    let names : Array[String] = []
    for def in defines {
      let name = def.0
      let init_expr = def.1
      names.push(name)
      // Create new env with all define names for compiling init expressions
      let new_env = extend_compile_env_same_frame(env, names.copy())
      let init_ir = match compile(init_expr, new_env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      bindings.push({ name, init: init_ir })
    }

    // Create new env with all define names for compiling body
    let new_env = extend_compile_env_same_frame(env, names)

    // Build body from remaining expressions
    let body_exprs : Array[SExpr] = []
    let mut j = body_start
    let _ = while j < exprs.length() {
      body_exprs.push(exprs[j])
      j = j + 1
    } else {
      ()
    }

    let body_ir = if body_exprs.length() == 1 {
      match compile(body_exprs[0], new_env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
    } else {
      // Multiple expressions - compile as begin
      let ir_list : Array[IRExpr] = []
      let mut k = 0
      let _ = while k < body_exprs.length() {
        let is_tail = tail && k == body_exprs.length() - 1
        let ir = match compile(body_exprs[k], new_env, is_tail) {
          Ok(ir) => ir
          Err(e) => return Err(e)
        }
        ir_list.push(ir)
        k = k + 1
      } else {
        ()
      }
      IRExpr::Begin(ir_list)
    }

    return Ok(IRExpr::Letrec(bindings, body_ir))
  }

  // No internal defines - original behavior
  if exprs.length() == 1 {
    return compile(exprs[0], env, tail)
  }
  // Treat multiple expressions as begin
  let ir_exprs : Array[IRExpr] = []
  let len = exprs.length()
  let mut idx = 0
  while idx < len {
    let is_tail = tail && idx == len - 1
    let ir = match compile(exprs[idx], env, is_tail) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    ir_exprs.push(ir)
    idx = idx + 1
  }
  Ok(IRExpr::Begin(ir_exprs))
}

/// Parse an internal define: (define name expr) or (define (name args...) body...)
fn parse_internal_define(args : SExpr) -> Result[(String, SExpr), CompileError] {
  match args {
    // (define name expr)
    SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, SExpr::Nil)) =>
      Ok((name, init_expr))
    // (define (name args...) body...)
    SExpr::Pair(SExpr::Pair(SExpr::Symbol(name), params), body) => {
      // Convert to (define name (lambda (args...) body...))
      let lambda_expr = SExpr::Pair(
        SExpr::Symbol("lambda"),
        SExpr::Pair(params, body),
      )
      Ok((name, lambda_expr))
    }
    _ => Err(CompileError::SyntaxError("invalid internal define syntax"))
  }
}

/// Compile the begin expression
fn compile_begin(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  compile_body(args, env, tail)
}

/// Compile the and expression
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

/// Compile or expression
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

/// Compile the cond expression
/// (cond (test expr ...) ... [(else expr ...)])
fn compile_cond(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  // Parse clauses: Array of (test_expr, body_exprs_list)
  let clause_tests : Array[SExpr] = []
  let clause_bodies : Array[Array[SExpr]] = []
  let mut current = args
  let _ = while true {
    match current {
      SExpr::Nil => break ()
      SExpr::Pair(clause, rest) => {
        match clause {
          SExpr::Pair(test_expr, body_exprs) => {
            let expr_list : Array[SExpr] = []
            let mut expr_current = body_exprs
            let _ = while true {
              match expr_current {
                SExpr::Nil => break ()
                SExpr::Pair(e, r) => {
                  expr_list.push(e)
                  expr_current = r
                }
                _ => return Err(CompileError::SyntaxError("cond: invalid clause"))
              }
            } else {
              ()
            }
            clause_tests.push(test_expr)
            clause_bodies.push(expr_list)
            current = rest
          }
          _ => return Err(CompileError::SyntaxError("cond: invalid clause"))
        }
      }
      _ => return Err(CompileError::SyntaxError("cond: invalid syntax"))
    }
  } else {
    ()
  }

  if clause_tests.length() == 0 {
    // Empty cond returns unspecified (nil)
    return Ok(IRExpr::Const(IRConst::Nil))
  }

  // Build nested if from the end
  compile_cond_clauses(clause_tests, clause_bodies, 0, env, tail)
}

/// Compile cond clauses recursively
fn compile_cond_clauses(
  tests : Array[SExpr],
  bodies : Array[Array[SExpr]],
  index : Int,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  if index >= tests.length() {
    // No more clauses, return unspecified (nil)
    return Ok(IRExpr::Const(IRConst::Nil))
  }

  let test_sexpr = tests[index]
  let exprs = bodies[index]

  // Check for else clause
  match test_sexpr {
    SExpr::Symbol("else") => {
      // else must be last clause
      if index != tests.length() - 1 {
        return Err(CompileError::SyntaxError("cond: else clause must be last"))
      }
      if exprs.length() == 0 {
        return Ok(IRExpr::Const(IRConst::Nil))
      }
      // Compile body as begin
      compile_body_exprs(exprs, env, tail)
    }
    _ => {
      // Regular clause
      let test_ir = match compile(test_sexpr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }

      let then_ir = if exprs.length() == 0 {
        // (cond (test) ...) - return test value if true
        // This requires special handling, for now just return nil
        IRExpr::Const(IRConst::Nil)
      } else {
        match compile_body_exprs(exprs, env, tail) {
          Ok(ir) => ir
          Err(e) => return Err(e)
        }
      }

      let else_ir = match compile_cond_clauses(tests, bodies, index + 1, env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }

      Ok(IRExpr::If(test_ir, then_ir, else_ir))
    }
  }
}

/// Compile a list of expressions as a body (returns last value)
fn compile_body_exprs(
  exprs : Array[SExpr],
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  if exprs.length() == 0 {
    return Ok(IRExpr::Const(IRConst::Nil))
  }
  if exprs.length() == 1 {
    return compile(exprs[0], env, tail)
  }
  // Multiple expressions: compile as begin
  let ir_exprs : Array[IRExpr] = []
  let mut i = 0
  let _ = while i < exprs.length() {
    let is_last = i == exprs.length() - 1
    let ir = match compile(exprs[i], env, if is_last { tail } else { false }) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    ir_exprs.push(ir)
    i = i + 1
  } else {
    ()
  }
  Ok(IRExpr::Begin(ir_exprs))
}

/// Compile the case expression
/// (case key ((datum ...) expr ...) ... [(else expr ...)])
fn compile_case(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  // Parse: (case key clause ...)
  match args {
    SExpr::Pair(key_expr, clauses) => {
      // Compile key expression
      let key_ir = match compile(key_expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }

      // Parse clauses
      let clause_datums : Array[Array[SExpr]] = []  // each clause has list of datums
      let clause_bodies : Array[Array[SExpr]] = []
      let mut has_else = false
      let mut current = clauses
      let _ = while true {
        match current {
          SExpr::Nil => break ()
          SExpr::Pair(clause, rest) => {
            match clause {
              SExpr::Pair(datums_or_else, body_exprs) => {
                // Parse body expressions
                let body_list : Array[SExpr] = []
                let mut body_current = body_exprs
                let _ = while true {
                  match body_current {
                    SExpr::Nil => break ()
                    SExpr::Pair(e, r) => {
                      body_list.push(e)
                      body_current = r
                    }
                    _ => return Err(CompileError::SyntaxError("case: invalid clause body"))
                  }
                } else {
                  ()
                }

                // Check for else clause
                match datums_or_else {
                  SExpr::Symbol("else") => {
                    has_else = true
                    clause_datums.push([])  // empty datums for else
                    clause_bodies.push(body_list)
                    current = rest
                  }
                  _ => {
                    // Parse datum list
                    let datum_list : Array[SExpr] = []
                    let mut datum_current = datums_or_else
                    let _ = while true {
                      match datum_current {
                        SExpr::Nil => break ()
                        SExpr::Pair(d, r) => {
                          datum_list.push(d)
                          datum_current = r
                        }
                        _ => return Err(CompileError::SyntaxError("case: invalid datum list"))
                      }
                    } else {
                      ()
                    }
                    clause_datums.push(datum_list)
                    clause_bodies.push(body_list)
                    current = rest
                  }
                }
              }
              _ => return Err(CompileError::SyntaxError("case: invalid clause"))
            }
          }
          _ => return Err(CompileError::SyntaxError("case: invalid syntax"))
        }
      } else {
        ()
      }

      // Verify else is last if present
      if has_else && clause_datums.length() > 0 {
        let last_idx = clause_datums.length() - 1
        if clause_datums[last_idx].length() != 0 {
          return Err(CompileError::SyntaxError("case: else clause must be last"))
        }
      }

      // Build: (let ((tmp key)) (cond ...))
      // Use a unique temp variable name
      let temp_name = "$case-key"
      let temp_binding : LetBinding = { name: temp_name, init: key_ir }

      // Extend env with $case-key so body VarRef indices account for the Let binding
      let case_env = extend_compile_env_same_frame(env, [temp_name])

      // Build cond clauses from case clauses
      let cond_ir = compile_case_to_cond(
        temp_name, clause_datums, clause_bodies, 0, case_env, tail
      )
      match cond_ir {
        Ok(body) => {
          Ok(IRExpr::Let([temp_binding], body))
        }
        Err(e) => Err(e)
      }
    }
    _ => Err(CompileError::SyntaxError("case: invalid syntax"))
  }
}

/// Convert case clauses to nested if expressions
fn compile_case_to_cond(
  temp_name : String,
  datums : Array[Array[SExpr]],
  bodies : Array[Array[SExpr]],
  index : Int,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  if index >= datums.length() {
    // No more clauses
    return Ok(IRExpr::Const(IRConst::Nil))
  }

  let datum_list = datums[index]
  let body_exprs = bodies[index]

  // Check for else clause (empty datum list at the end)
  if datum_list.length() == 0 {
    // else clause - just compile the body
    return compile_body_exprs(body_exprs, env, tail)
  }

  // Build test: (or (eqv? tmp datum1) (eqv? tmp datum2) ...)
  let temp_var_ref = match lookup_local(env, temp_name) {
    Some(ref) => ref
    None => { name: temp_name, depth: 0, index: 0 } // fallback
  }
  let temp_var = IRExpr::Var(temp_var_ref)

  // Build eqv? comparisons for each datum
  let eqv_tests : Array[IRExpr] = []
  for datum in datum_list {
    let datum_ir = match compile_quote_inner(datum) {
      Ok(ir) => ir
      Err(e) => return Err(e)
    }
    // (eqv? tmp datum)
    let eqv_test = IRExpr::PrimOp(PrimOpKind::Eqv, [temp_var, datum_ir])
    eqv_tests.push(eqv_test)
  }

  // Combine tests with or
  let test_ir = if eqv_tests.length() == 1 {
    eqv_tests[0]
  } else {
    IRExpr::Or(eqv_tests)
  }

  // Compile then branch (body expressions)
  let then_ir = match compile_body_exprs(body_exprs, env, tail) {
    Ok(ir) => ir
    Err(e) => return Err(e)
  }

  // Compile else branch (remaining clauses)
  let else_ir = match compile_case_to_cond(temp_name, datums, bodies, index + 1, env, tail) {
    Ok(ir) => ir
    Err(e) => return Err(e)
  }

  Ok(IRExpr::If(test_ir, then_ir, else_ir))
}

/// Compile a quoted expression to IR (for case datums)
fn compile_quote_inner(expr : SExpr) -> Result[IRExpr, CompileError] {
  Ok(IRExpr::Const(sexpr_to_ir_const(expr)))
}

/// Compile the let expression
fn compile_let(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(bindings_expr, body)) => {
      let (param_names, init_exprs) = match parse_named_let_bindings(bindings_expr) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let params_expr = sexpr_list_from_names(param_names)
      let lambda_expr = SExpr::Pair(
        SExpr::Symbol("lambda"),
        SExpr::Pair(params_expr, body),
      )
      let binding = SExpr::Pair(
        SExpr::Symbol(name),
        SExpr::Pair(lambda_expr, SExpr::Nil),
      )
      let letrec_bindings = SExpr::Pair(binding, SExpr::Nil)
      let letrec_expr = SExpr::Pair(
        SExpr::Symbol("letrec"),
        SExpr::Pair(letrec_bindings, SExpr::Pair(SExpr::Symbol(name), SExpr::Nil)),
      )
      let app_expr = sexpr_list_from_exprs(
        append_exprs([letrec_expr], init_exprs),
      )
      compile(app_expr, env, tail)
    }
    SExpr::Pair(bindings_expr, body) => {
      let bindings = match parse_let_bindings(bindings_expr, env) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      // Create a new environment
      let names : Array[String] = []
      for b in bindings {
        names.push(b.name)
      }
      let new_env = extend_compile_env_same_frame(env, names)
      // compile body
      let body_ir = match compile_body(body, new_env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Let(bindings, body_ir))
    }
    _ => Err(CompileError::SyntaxError("let: invalid syntax"))
  }
}

fn sexpr_list_from_exprs(items : Array[SExpr]) -> SExpr {
  let mut result = SExpr::Nil
  let mut i = items.length()
  let _ = while i > 0 {
    i = i - 1
    result = SExpr::Pair(items[i], result)
  } else {
    ()
  }
  result
}

fn sexpr_list_from_names(names : Array[String]) -> SExpr {
  sexpr_list_from_exprs(sexpr_names(names))
}

fn append_exprs(prefix : Array[SExpr], suffix : Array[SExpr]) -> Array[SExpr] {
  let result : Array[SExpr] = []
  for item in prefix {
    result.push(item)
  }
  for item in suffix {
    result.push(item)
  }
  result
}

fn sexpr_names(names : Array[String]) -> Array[SExpr] {
  let items : Array[SExpr] = []
  for name in names {
    items.push(SExpr::Symbol(name))
  }
  items
}

fn parse_named_let_bindings(
  bindings_expr : SExpr
) -> Result[(Array[String], Array[SExpr]), CompileError] {
  let names : Array[String] = []
  let inits : Array[SExpr] = []
  let mut current = bindings_expr
  while true {
    match current {
      SExpr::Nil => return Ok((names, inits))
      SExpr::Pair(binding, rest) => {
        match binding {
          SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(init_expr, SExpr::Nil)) => {
            names.push(name)
            inits.push(init_expr)
            current = rest
          }
          _ => return Err(CompileError::SyntaxError("let: invalid binding"))
        }
      }
      _ => return Err(CompileError::SyntaxError("let: bindings must be a list"))
    }
  }
  Ok((names, inits))
}

/// Parse the let binding
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

/// Compile let* expressions
fn compile_let_star(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // let* converts to nested let
      compile_let_star_bindings(bindings_expr, body, env, tail)
    }
    _ => Err(CompileError::SyntaxError("let*: invalid syntax"))
  }
}

/// Process let* bindings recursively
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
          let new_env = extend_compile_env_same_frame(env, [name])
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

/// Compile the letrec expression
fn compile_letrec(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, body) => {
      // First collect variable names
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
      // Create a new environment (all variables visible)
      let new_env = extend_compile_env_same_frame(env, names.copy())
      // Parse binding (in new environment)
      let bindings = match parse_let_bindings(bindings_expr, new_env) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      // compile body
      let body_ir = match compile_body(body, new_env, tail) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Letrec(bindings, body_ir))
    }
    _ => Err(CompileError::SyntaxError("letrec: invalid syntax"))
  }
}

/// Compile do loop by transforming to letrec
/// (do ((var init step) ...) (test expr ...) body ...)
/// Transforms to:
/// (letrec ((loop (lambda (var ...)
///                  (if test
///                      (begin expr ...)
///                      (begin body ... (loop step ...))))))
///   (loop init ...))
fn compile_do(
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(bindings_expr, SExpr::Pair(test_clause, body)) => {
      // Parse bindings: ((var init step) ...)
      let vars : Array[SExpr] = []
      let inits : Array[SExpr] = []
      let steps : Array[SExpr] = []

      let mut current = bindings_expr
      while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            match binding {
              // (var init step)
              SExpr::Pair(SExpr::Symbol(v), SExpr::Pair(init, SExpr::Pair(step, SExpr::Nil))) => {
                vars.push(SExpr::Symbol(v))
                inits.push(init)
                steps.push(step)
                current = rest
              }
              // (var init) - step defaults to var
              SExpr::Pair(SExpr::Symbol(v), SExpr::Pair(init, SExpr::Nil)) => {
                vars.push(SExpr::Symbol(v))
                inits.push(init)
                steps.push(SExpr::Symbol(v))
                current = rest
              }
              _ => return Err(CompileError::SyntaxError("do: invalid binding"))
            }
          }
          _ => return Err(CompileError::SyntaxError("do: invalid bindings"))
        }
      }

      // Parse test clause: (test expr ...)
      let test_expr : SExpr = match test_clause {
        SExpr::Pair(t, _) => t
        _ => return Err(CompileError::SyntaxError("do: invalid test clause"))
      }
      let result_exprs : SExpr = match test_clause {
        SExpr::Pair(_, results) => results
        _ => return Err(CompileError::SyntaxError("do: invalid test clause"))
      }

      // Generate a unique loop name
      let loop_sym = SExpr::Symbol("__do_loop__")

      // Build (loop step ...) call
      let loop_call = build_list_from_array(append_exprs([loop_sym], steps))

      // Build the else branch: (begin body ... (loop step ...))
      let else_branch = if body == SExpr::Nil {
        loop_call
      } else {
        // (begin body ... (loop step ...))
        let body_list = sexpr_to_array(body)
        let begin_body = append_exprs(append_exprs([SExpr::Symbol("begin")], body_list), [loop_call])
        build_list_from_array(begin_body)
      }

      // Build the then branch: (begin result_exprs ...)
      let then_branch = if result_exprs == SExpr::Nil {
        SExpr::Nil
      } else {
        let result_list = sexpr_to_array(result_exprs)
        if result_list.length() == 1 {
          result_list[0]
        } else {
          build_list_from_array(append_exprs([SExpr::Symbol("begin")], result_list))
        }
      }

      // Build (if test then_branch else_branch)
      let if_expr = build_list_from_array([SExpr::Symbol("if"), test_expr, then_branch, else_branch])

      // Build (lambda (var ...) if_expr)
      let params = build_list_from_array(vars)
      let lambda_expr = build_list_from_array([SExpr::Symbol("lambda"), params, if_expr])

      // Build ((loop lambda_expr))
      let loop_binding = build_list_from_array([loop_sym, lambda_expr])
      let bindings = build_list_from_array([loop_binding])

      // Build (loop init ...)
      let initial_call = build_list_from_array(append_exprs([loop_sym], inits))

      // Build (letrec ((loop lambda_expr)) (loop init ...))
      let letrec_expr = build_list_from_array([SExpr::Symbol("letrec"), bindings, initial_call])

      // Compile the transformed expression
      compile(letrec_expr, env, tail)
    }
    _ => Err(CompileError::SyntaxError("do: invalid syntax"))
  }
}

/// Convert SExpr list to array
fn sexpr_to_array(expr : SExpr) -> Array[SExpr] {
  let result : Array[SExpr] = []
  let mut current = expr
  while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(car, cdr) => {
        result.push(car)
        current = cdr
      }
      _ => {
        result.push(current)
        break
      }
    }
  }
  result
}

/// Build SExpr list from array
fn build_list_from_array(arr : Array[SExpr]) -> SExpr {
  let mut result = SExpr::Nil
  let mut i = arr.length() - 1
  while i >= 0 {
    result = SExpr::Pair(arr[i], result)
    i = i - 1
  }
  result
}

/// set! Compile the expression
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

/// Compile a quote expression
fn compile_quote(args : SExpr) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(datum, SExpr::Nil) => Ok(IRExpr::Quote(sexpr_to_ir_const(datum)))
    _ => Err(CompileError::SyntaxError("quote: requires exactly one argument"))
  }
}

/// Compile the delay expression
fn compile_delay(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(expr, SExpr::Nil) => {
      // Compile body in a new nested env (like a 0-arg lambda)
      // so that VarRef depths account for the extra lambda scope
      let new_env = extend_compile_env(env, [])
      let body_ir = match compile(expr, new_env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      // Collect free variables (all params are empty since arity=0)
      let free_vars = collect_free_vars(body_ir, [])
      let set_vars = collect_set_vars(body_ir)
      let boxed_free_vars : Array[Int] = []
      let mut j = 0
      while j < free_vars.length() {
        let free_var = free_vars[j]
        for sv in set_vars {
          if sv == free_var.name {
            boxed_free_vars.push(j)
            break
          }
        }
        j = j + 1
      }
      let lambda_info : LambdaInfo = {
        params: [],
        arity: 0,
        rest_param: None,
        body: body_ir,
        free_vars,
        boxed_params: [],
        boxed_locals: [],
        boxed_free_vars,
      }
      Ok(IRExpr::Delay(IRExpr::Lambda(lambda_info)))
    }
    _ => Err(CompileError::SyntaxError("delay: requires exactly one argument"))
  }
}

/// Compile call/cc expressions
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

/// Compile function application
fn compile_application(
  op : SExpr,
  args : SExpr,
  env : CompileEnv,
  tail : Bool
) -> Result[IRExpr, CompileError] {
  // compile operator
  let op_ir = match compile(op, env, false) {
    Ok(ir) => ir
    Err(e) => return Err(e)
  }

  // compile arguments
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

  // Optimization for primitive operations
  match op {
    SExpr::Symbol(name) =>
      match lookup_local(env, name) {
        Some(_) => ()
        None =>
          match name_to_primop(name) {
            Some(primop) => return Ok(IRExpr::PrimOp(primop, arg_irs))
            None => ()
          }
      }
    _ => ()
  }

  // Branch depending on whether it is a tail call or not
  if tail {
    Ok(IRExpr::TailApp(op_ir, arg_irs))
  } else {
    Ok(IRExpr::App(op_ir, arg_irs))
  }
}

/// Set! Collect variables to be set!
fn collect_set_vars(body : IRExpr) -> Array[String] {
  let set_vars : Array[String] = []
  let seen : @hashmap.T[String, Unit] = @hashmap.new()

  fn visit(expr : IRExpr) -> Unit {
    match expr {
      IRExpr::Set(var_ref, value) => {
        if !seen.contains(var_ref.name) {
          set_vars.push(var_ref.name)
          seen.set(var_ref.name, ())
        }
        visit(value)
      }
      IRExpr::GlobalSet(_name, value) => {
        visit(value)
      }
      IRExpr::Const(_) => ()
      IRExpr::Var(_) => ()
      IRExpr::GlobalVar(_) => ()
      IRExpr::If(cond, then_branch, else_branch) => {
        visit(cond)
        visit(then_branch)
        visit(else_branch)
      }
      IRExpr::Begin(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
      IRExpr::Lambda(info) => {
        // Do not search inside nested lambdas
        visit(info.body)
      }
      IRExpr::App(func, args) => {
        visit(func)
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::TailApp(func, args) => {
        visit(func)
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::Let(bindings, body) => {
        for binding in bindings {
          visit(binding.init)
        }
        visit(body)
      }
      IRExpr::Letrec(bindings, body) => {
        for binding in bindings {
          visit(binding.init)
        }
        visit(body)
      }
      IRExpr::PrimOp(_kind, args) => {
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::CallCC(proc) => {
        visit(proc)
      }
      IRExpr::Quote(_) => ()
      IRExpr::Delay(body) => {
        visit(body)
      }
      IRExpr::And(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
      IRExpr::Or(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
    }
  }

  visit(body)
  set_vars
}

/// Collect free variables
fn collect_free_vars(body : IRExpr, bound : Array[String]) -> Array[VarRef] {
  let free_vars : Array[VarRef] = []
  let seen : @hashmap.T[String, Unit] = @hashmap.new()

  fn visit(expr : IRExpr) -> Unit {
    match expr {
      IRExpr::Var(var_ref) => {
        // If depth > 0 (that is, it is a free variable) and it has not already been found
        if var_ref.depth > 0 && !seen.contains(var_ref.name) {
          free_vars.push(var_ref)
          seen.set(var_ref.name, ())
        }
      }
      IRExpr::Const(_) => ()
      IRExpr::GlobalVar(_) => ()
      IRExpr::If(cond, then_branch, else_branch) => {
        visit(cond)
        visit(then_branch)
        visit(else_branch)
      }
      IRExpr::Begin(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
      IRExpr::Lambda(info) => {
        // For nested lambdas, check their free_vars
        // If a nested lambda has a free var with depth > 1, it means
        // that variable comes from beyond this lambda's scope
        // and we need to capture it too (at depth - 1)
        for var_ref in info.free_vars {
          if var_ref.depth > 1 && !seen.contains(var_ref.name) {
            // The nested lambda references a variable from 2+ levels up
            // So the current lambda needs to capture it at depth - 1
            free_vars.push({
              name: var_ref.name,
              depth: var_ref.depth - 1,
              index: var_ref.index,
            })
            seen.set(var_ref.name, ())
          }
        }
      }
      IRExpr::App(func, args) => {
        visit(func)
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::TailApp(func, args) => {
        visit(func)
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::Let(bindings, body) => {
        for binding in bindings {
          visit(binding.init)
        }
        visit(body)
      }
      IRExpr::Letrec(bindings, body) => {
        for binding in bindings {
          visit(binding.init)
        }
        visit(body)
      }
      IRExpr::Set(var_ref, value) => {
        if var_ref.depth > 0 && !seen.contains(var_ref.name) {
          free_vars.push(var_ref)
          seen.set(var_ref.name, ())
        }
        visit(value)
      }
      IRExpr::GlobalSet(_name, value) => {
        visit(value)
      }
      IRExpr::PrimOp(_kind, args) => {
        for arg in args {
          visit(arg)
        }
      }
      IRExpr::CallCC(proc) => {
        visit(proc)
      }
      IRExpr::Quote(_) => ()
      IRExpr::Delay(body) => {
        visit(body)
      }
      IRExpr::And(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
      IRExpr::Or(exprs) => {
        for expr in exprs {
          visit(expr)
        }
      }
    }
  }

  visit(body)
  // Sort free variables by (depth, index) (for stability)
  free_vars.sort_by(fn(a : VarRef, b : VarRef) -> Int {
    let depth_cmp = a.depth - b.depth
    if depth_cmp != 0 {
      depth_cmp
    } else {
      a.index - b.index
    }
  })
  free_vars
}

/// Determine whether boxing is required
fn needs_boxing(var_name : String, free_vars : Array[VarRef], set_vars : Array[String]) -> Bool {
  // Is it referenced as a free variable?
  let is_free = {
    let mut found = false
    for var_ref in free_vars {
      if var_ref.name == var_name {
        found = true
        break
      }
    }
    found
  }
  // set! Has it been set?
  let is_set = {
    let mut found = false
    for v in set_vars {
      if v == var_name {
        found = true
        break
      }
    }
    found
  }
  is_free || is_set
}

/// Compile top-level expressions
pub fn compile_toplevel(expr : SExpr) -> Result[IRExpr, CompileError] {
  let globals = initial_globals()
  let env = new_compile_env(globals)
  compile_toplevel_expr(expr, env)
}

/// Compile top-level expressions (define supported)
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
    // normal expression
    _ => compile(expr, env, false)
  }
}

/// Compile top-level expressions using external global environment
pub fn compile_toplevel_with_globals(
  expr : SExpr,
  globals : @hashmap.T[String, Unit]
) -> Result[IRExpr, CompileError] {
  let env = new_compile_env(globals)
  compile_toplevel_expr(expr, env)
}

/// =============================================
/// Quasiquote Compilation
/// =============================================

/// Compile (quasiquote expr) form
fn compile_quasiquote_form(args : SExpr, env : CompileEnv) -> Result[IRExpr, CompileError] {
  match args {
    SExpr::Pair(inner, SExpr::Nil) => compile_quasiquote(inner, env, 0)
    _ => Err(CompileError::SyntaxError("quasiquote: requires exactly one argument"))
  }
}

/// Compile quasiquote expression
/// depth tracks nesting level (0 = top level quasiquote)
fn compile_quasiquote(
  expr : SExpr,
  env : CompileEnv,
  depth : Int
) -> Result[IRExpr, CompileError] {
  match expr {
    // unquote: evaluate if depth == 0, otherwise preserve structure
    SExpr::Unquote(inner) =>
      if depth == 0 {
        compile(inner, env, false)
      } else {
        // Nested unquote - decrease depth and preserve structure
        match compile_quasiquote(inner, env, depth - 1) {
          Ok(inner_compiled) =>
            // Build (unquote inner_compiled)
            Ok(IRExpr::PrimOp(
              PrimOpKind::Cons,
              [
                IRExpr::Const(IRConst::Symbol("unquote")),
                IRExpr::PrimOp(
                  PrimOpKind::Cons,
                  [inner_compiled, IRExpr::Const(IRConst::Nil)]
                )
              ]
            ))
          Err(e) => Err(e)
        }
      }

    // unquote-splicing at top level (not in list context) is an error
    SExpr::UnquoteSplicing(inner) =>
      if depth == 0 {
        Err(CompileError::SyntaxError("unquote-splicing: not in list context"))
      } else {
        match compile_quasiquote(inner, env, depth - 1) {
          Ok(inner_compiled) =>
            // Build (unquote-splicing inner_compiled)
            Ok(IRExpr::PrimOp(
              PrimOpKind::Cons,
              [
                IRExpr::Const(IRConst::Symbol("unquote-splicing")),
                IRExpr::PrimOp(
                  PrimOpKind::Cons,
                  [inner_compiled, IRExpr::Const(IRConst::Nil)]
                )
              ]
            ))
          Err(e) => Err(e)
        }
      }

    // nested quasiquote: increase depth
    SExpr::Quasiquote(inner) =>
      match compile_quasiquote(inner, env, depth + 1) {
        Ok(inner_compiled) =>
          // Build (quasiquote inner_compiled)
          Ok(IRExpr::PrimOp(
            PrimOpKind::Cons,
            [
              IRExpr::Const(IRConst::Symbol("quasiquote")),
              IRExpr::PrimOp(
                PrimOpKind::Cons,
                [inner_compiled, IRExpr::Const(IRConst::Nil)]
              )
            ]
          ))
        Err(e) => Err(e)
      }

    // List: handle each element, with special handling for unquote-splicing
    SExpr::Pair(car, cdr) => compile_quasiquote_list(car, cdr, env, depth)

    // Quote: preserve as constant
    SExpr::Quote(inner) => Ok(IRExpr::Const(sexpr_to_ir_const(expr)))

    // Atoms: convert to constant
    _ => Ok(IRExpr::Const(sexpr_to_ir_const(expr)))
  }
}

/// Compile quasiquoted list with support for unquote-splicing
fn compile_quasiquote_list(
  car : SExpr,
  cdr : SExpr,
  env : CompileEnv,
  depth : Int
) -> Result[IRExpr, CompileError] {
  match car {
    // unquote-splicing in list context
    SExpr::UnquoteSplicing(inner) =>
      if depth == 0 {
        // Evaluate inner and append with rest
        match compile(inner, env, false) {
          Ok(spliced) =>
            match compile_quasiquote(cdr, env, depth) {
              Ok(rest) =>
                // (append spliced rest)
                Ok(IRExpr::PrimOp(PrimOpKind::Append, [spliced, rest]))
              Err(e) => Err(e)
            }
          Err(e) => Err(e)
        }
      } else {
        // Preserve structure at deeper nesting
        match compile_quasiquote(inner, env, depth - 1) {
          Ok(inner_compiled) =>
            match compile_quasiquote(cdr, env, depth) {
              Ok(cdr_compiled) => {
                // Build (cons (unquote-splicing inner_compiled) cdr_compiled)
                let unquote_splicing_form = IRExpr::PrimOp(
                  PrimOpKind::Cons,
                  [
                    IRExpr::Const(IRConst::Symbol("unquote-splicing")),
                    IRExpr::PrimOp(
                      PrimOpKind::Cons,
                      [inner_compiled, IRExpr::Const(IRConst::Nil)]
                    )
                  ]
                )
                Ok(IRExpr::PrimOp(PrimOpKind::Cons, [unquote_splicing_form, cdr_compiled]))
              }
              Err(e) => Err(e)
            }
          Err(e) => Err(e)
        }
      }

    // Normal element: cons car with cdr
    _ =>
      match compile_quasiquote(car, env, depth) {
        Ok(car_compiled) =>
          match compile_quasiquote(cdr, env, depth) {
            Ok(cdr_compiled) =>
              Ok(IRExpr::PrimOp(PrimOpKind::Cons, [car_compiled, cdr_compiled]))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
  }
}
