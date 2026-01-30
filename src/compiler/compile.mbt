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

    // quote
    SExpr::Quote(inner) => Ok(IRExpr::Quote(sexpr_to_ir_const(inner)))

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
    SExpr::Quasiquote(_) =>
      Err(CompileError::Unsupported("quasiquote in compiler"))
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
    // special format
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

    // function application
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
      let params = match extract_params(params_expr) {
        Ok(p) => p
        Err(e) => return Err(e)
      }
      // Compile the body in the new environment
      let new_env = extend_compile_env(env, params.copy())
      // Compile body as begin (tail position)
      let body_ir = match compile_body(body_rest, new_env, true) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      // Collect free variables (depth remains the same)
      let free_vars = collect_free_vars(body_ir, params)

      // Set! Collect variables to be set!
      let set_vars = collect_set_vars(body_ir)
      // Determine which parameters require boxing
      let boxed_params : Array[Int] = []
      let mut i = 0
      while i < params.length() {
        if needs_boxing(params[i], free_vars, set_vars) {
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
        params,
        arity: params.length(),
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

/// Extract parameter list
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
        // Doesn't support varargs yet
        return Err(CompileError::Unsupported("rest parameter"))
      _ => return Err(CompileError::SyntaxError("lambda: invalid parameter"))
    }
  }
  Ok(names)
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
  if exprs.length() == 1 {
    return compile(exprs[0], env, tail)
  }
  // Treat multiple expressions as begin
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
      let ir = match compile(expr, env, false) {
        Ok(ir) => ir
        Err(e) => return Err(e)
      }
      Ok(IRExpr::Delay(ir))
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
      IRExpr::Lambda(_info) => {
        // Do not visit bodies of nested lambdas
        // The free_vars of that lambda has already been calculated, so
        // Does not affect outer lambda
        ()
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
