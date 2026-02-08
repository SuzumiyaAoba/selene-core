/// stack-based virtual machine
///
/// Implementing a VM to run bytecode
///
/// Type definition:
/// - VMClosure, VMContinuation, VMCallFrame are defined in value.mbt
/// - VMClosure and VMCont have been added to Procedure enum.

/// Active VM context for native builtins to call VMClosures.
/// Set before calling native builtins, cleared after.
let active_vm_module : Ref[CompiledModule?] = Ref::new(None)

let active_vm_globals : Ref[@hashmap.T[String, Value]?] = Ref::new(None)

/// Call a VMClosure from outside the VM (used by native builtins like map).
/// Creates a mini VM to execute the closure and returns the result.
pub fn vm_apply_closure(
  closure : VMClosure,
  args : Array[Value]
) -> Result[Value, EvalError] {
  let module = match active_vm_module.val {
    Some(m) => m
    None =>
      return Err(
        EvalError::TypeError(
          "cannot call VM closure outside of VM execution context",
        ),
      )
  }
  let globals = match active_vm_globals.val {
    Some(g) => g
    None =>
      return Err(
        EvalError::TypeError(
          "cannot call VM closure: no globals context",
        ),
      )
  }
  let target_chunk = module.chunks[closure.chunk_idx]

  // Arity check
  if target_chunk.has_rest_param {
    if target_chunk.arity >= 0 && args.length() < target_chunk.arity {
      return Err(EvalError::ArityError("VM closure arity mismatch (too few arguments)"))
    }
  } else {
    if target_chunk.arity >= 0 && args.length() != target_chunk.arity {
      return Err(EvalError::ArityError("VM closure arity mismatch"))
    }
  }

  // Prepare actual args (collect rest into list if variadic)
  let actual_args : Array[Value] = []
  if target_chunk.has_rest_param {
    let mut i = 0
    while i < target_chunk.arity {
      actual_args.push(args[i])
      i = i + 1
    }
    let mut rest_list : Value = Value::Nil
    let mut j = args.length() - 1
    while j >= target_chunk.arity {
      rest_list = make_pair(args[j], rest_list)
      j = j - 1
    }
    actual_args.push(rest_list)
  } else {
    for arg in args {
      actual_args.push(arg)
    }
  }

  // Create a mini compiled module with just a call-and-return wrapper
  // We build a small main chunk that calls the closure
  let main_code : Array[Opcode] = []

  // Push closure captures
  for capture in closure.captures {
    let idx = main_code.length()
    // We need to push capture values onto the stack, so use Push with constants
    // But we can't easily add constants. Instead, we'll set up the VM state directly.
    let _ = idx
  }

  // Rather than building bytecode, set up VM state directly
  let vm = new_vm_state_with_globals(module, globals)

  // Push captures and args onto the stack
  for capture in closure.captures {
    vm_push(vm, capture)
  }
  for arg in actual_args {
    vm_push(vm, arg)
  }

  // Set up call frame
  let frame : VMCallFrame = {
    return_chunk: -1,
    return_ip: module.main.code.length(),
    base_ptr: 0,
    num_locals: closure.captures.length() + actual_args.length(),
  }
  vm.call_stack.push(frame)

  // Jump to closure's chunk
  vm.current_chunk = closure.chunk_idx
  vm.ip = 0

  // Run the VM
  match vm_run_from_current(vm) {
    Ok(value) => Ok(value)
    Err(e) => Err(EvalError::TypeError(e.to_string()))
  }
}

/// Run VM from current state (without pushing initial frame)
fn vm_run_from_current(vm : VMState) -> Result[Value, VMError] {
  let mut step_count = 0
  let gc_check_interval = 1000

  while true {
    match vm_step(vm) {
      Ok(true) => {
        step_count = step_count + 1
        if step_count % gc_check_interval == 0 {
          let _ = gc_check_and_run(vm)
        }
        continue
      }
      Ok(false) => break
      Err(e) => return Err(e)
    }
  }
  if vm.stack.length() > 0 {
    Ok(vm.stack[vm.stack.length() - 1])
  } else {
    Ok(Value::Nil)
  }
}

/// VM errors
pub(all) enum VMError {
  StackUnderflow
  InvalidInstruction
  TypeError(String)
  ArityError(String)
  UnboundVariable(String)
  DivisionByZero
  IndexOutOfBounds
  NotAProcedure
  InvalidContinuation
  RuntimeError(String)
} derive(Show)

/// VM promise (lazy evaluation)
pub(all) struct VMPromise {
  /// Has it been evaluated?
  mut forced : Bool
  /// Code chunk index (if unevaluated)
  chunk_idx : Int
  /// Evaluated value
  mut value : Value
}

/// VM state
pub(all) struct VMState {
  /// value stack
  stack : Array[Value]
  /// call stack
  call_stack : Array[VMCallFrame]
  /// Current code chunk index (-1 is main)
  mut current_chunk : Int
  /// instruction pointer
  mut ip : Int
  /// global environment
  globals : @hashmap.T[String, Value]
  /// compiled module
  compiled_module : CompiledModule
  /// continuation counter
  mut cont_counter : Int
}

/// Create new VM state
pub fn new_vm_state(compiled_module : CompiledModule) -> VMState {
  let globals = create_initial_globals()
  {
    stack: [],
    call_stack: [],
    current_chunk: -1,
    ip: 0,
    globals,
    compiled_module,
    cont_counter: 0,
  }
}

/// Create VM state using external global environment
pub fn new_vm_state_with_globals(
  compiled_module : CompiledModule,
  globals : @hashmap.T[String, Value]
) -> VMState {
  {
    stack: [],
    call_stack: [],
    current_chunk: -1,
    ip: 0,
    globals,
    compiled_module,
    cont_counter: 0,
  }
}

/// Create initial global environment
pub fn create_initial_globals() -> @hashmap.T[String, Value] {
  let globals : @hashmap.T[String, Value] = @hashmap.new()
  globals.set("+", Value::Procedure(Procedure::Native("+")))
  globals.set("-", Value::Procedure(Procedure::Native("-")))
  globals.set("*", Value::Procedure(Procedure::Native("*")))
  globals.set("/", Value::Procedure(Procedure::Native("/")))
  globals.set("cons", Value::Procedure(Procedure::Native("cons")))
  globals.set("car", Value::Procedure(Procedure::Native("car")))
  globals.set("cdr", Value::Procedure(Procedure::Native("cdr")))
  globals.set("null?", Value::Procedure(Procedure::Native("null?")))
  globals.set("pair?", Value::Procedure(Procedure::Native("pair?")))
  globals.set("list", Value::Procedure(Procedure::Native("list")))
  globals.set("=", Value::Procedure(Procedure::Native("=")))
  globals.set("<", Value::Procedure(Procedure::Native("<")))
  globals.set(">", Value::Procedure(Procedure::Native(">")))
  globals.set("<=", Value::Procedure(Procedure::Native("<=")))
  globals.set(">=", Value::Procedure(Procedure::Native(">=")))
  globals.set("eq?", Value::Procedure(Procedure::Native("eq?")))
  globals.set("eqv?", Value::Procedure(Procedure::Native("eqv?")))
  globals.set("equal?", Value::Procedure(Procedure::Native("equal?")))
  globals.set("not", Value::Procedure(Procedure::Native("not")))
  globals.set("display", Value::Procedure(Procedure::Native("display")))
  globals.set("newline", Value::Procedure(Procedure::Native("newline")))
  globals
}

/// Get current code chunk
fn get_current_chunk(vm : VMState) -> CodeChunk {
  if vm.current_chunk < 0 {
    vm.compiled_module.main
  } else {
    vm.compiled_module.chunks[vm.current_chunk]
  }
}

/// pop from stack
fn vm_pop(vm : VMState) -> Result[Value, VMError] {
  if vm.stack.length() == 0 {
    Err(VMError::StackUnderflow)
  } else {
    Ok(vm.stack.pop().unwrap())
  }
}

/// push onto stack
fn vm_push(vm : VMState, value : Value) -> Unit {
  vm.stack.push(value)
}

/// Get top of stack (don't pop)
fn vm_peek(vm : VMState) -> Result[Value, VMError] {
  if vm.stack.length() == 0 {
    Err(VMError::StackUnderflow)
  } else {
    Ok(vm.stack[vm.stack.length() - 1])
  }
}

/// get local variable
fn vm_get_local(vm : VMState, depth : Int, index : Int) -> Result[Value, VMError] {
  let frame_idx = vm.call_stack.length() - 1 - depth
  if frame_idx < 0 {
    return Err(VMError::RuntimeError("invalid frame depth: depth=" + depth.to_string() + " index=" + index.to_string() + " call_stack.len=" + vm.call_stack.length().to_string()))
  }
  let frame = vm.call_stack[frame_idx]
  let stack_idx = frame.base_ptr + index
  if stack_idx >= vm.stack.length() {
    return Err(VMError::IndexOutOfBounds)
  }
  Ok(vm.stack[stack_idx])
}

/// Set local variable
fn vm_set_local(
  vm : VMState,
  depth : Int,
  index : Int,
  value : Value
) -> Result[Unit, VMError] {
  let frame_idx = vm.call_stack.length() - 1 - depth
  if frame_idx < 0 {
    return Err(VMError::RuntimeError("set_local: invalid frame depth: depth=" + depth.to_string() + " index=" + index.to_string() + " call_stack.len=" + vm.call_stack.length().to_string()))
  }
  let frame = vm.call_stack[frame_idx]
  let stack_idx = frame.base_ptr + index
  if stack_idx >= vm.stack.length() {
    return Err(VMError::IndexOutOfBounds)
  }
  vm.stack[stack_idx] = value
  Ok(())
}

/// Convert PrimOpKind to builtin function name (for delegation to apply_builtin)
fn primop_to_builtin_name(kind : PrimOpKind) -> String {
  match kind {
    PrimOpKind::Add => "+"
    PrimOpKind::Sub => "-"
    PrimOpKind::Mul => "*"
    PrimOpKind::Div => "/"
    PrimOpKind::Quotient => "quotient"
    PrimOpKind::Remainder => "remainder"
    PrimOpKind::Modulo => "modulo"
    PrimOpKind::Abs => "abs"
    PrimOpKind::Max => "max"
    PrimOpKind::Min => "min"
    PrimOpKind::Gcd => "gcd"
    PrimOpKind::Lcm => "lcm"
    PrimOpKind::NumEq => "="
    PrimOpKind::Lt => "<"
    PrimOpKind::Gt => ">"
    PrimOpKind::Le => "<="
    PrimOpKind::Ge => ">="
    PrimOpKind::Eq => "eq?"
    PrimOpKind::Eqv => "eqv?"
    PrimOpKind::Equal => "equal?"
    PrimOpKind::ZeroP => "zero?"
    PrimOpKind::PositiveP => "positive?"
    PrimOpKind::NegativeP => "negative?"
    PrimOpKind::OddP => "odd?"
    PrimOpKind::EvenP => "even?"
    PrimOpKind::PairP => "pair?"
    PrimOpKind::NumberP => "number?"
    PrimOpKind::IntegerP => "integer?"
    PrimOpKind::RealP => "real?"
    PrimOpKind::BooleanP => "boolean?"
    PrimOpKind::SymbolP => "symbol?"
    PrimOpKind::NullP => "null?"
    PrimOpKind::ProcedureP => "procedure?"
    PrimOpKind::ListP => "list?"
    PrimOpKind::StringP => "string?"
    PrimOpKind::CharP => "char?"
    PrimOpKind::VectorP => "vector?"
    PrimOpKind::PromiseP => "promise?"
    PrimOpKind::PortP => "port?"
    PrimOpKind::Cons => "cons"
    PrimOpKind::Car => "car"
    PrimOpKind::Cdr => "cdr"
    PrimOpKind::SetCar => "set-car!"
    PrimOpKind::SetCdr => "set-cdr!"
    PrimOpKind::List => "list"
    PrimOpKind::Length => "length"
    PrimOpKind::Append => "append"
    PrimOpKind::Reverse => "reverse"
    PrimOpKind::ListRef => "list-ref"
    PrimOpKind::ListTail => "list-tail"
    PrimOpKind::Not => "not"
    PrimOpKind::Apply => "apply"
    PrimOpKind::Map => "map"
    PrimOpKind::ForEach => "for-each"
    PrimOpKind::Filter => "filter"
    PrimOpKind::FoldLeft => "fold-left"
    PrimOpKind::FoldRight => "fold-right"
    PrimOpKind::Force => "force"
    PrimOpKind::Values => "values"
    PrimOpKind::CallWithValues => "call-with-values"
    PrimOpKind::DynamicWind => "dynamic-wind"
    PrimOpKind::Display => "display"
    PrimOpKind::Newline => "newline"
    PrimOpKind::Write => "write"
    PrimOpKind::Read => "read"
    PrimOpKind::CharEq => "char=?"
    PrimOpKind::CharLt => "char<?"
    PrimOpKind::CharGt => "char>?"
    PrimOpKind::CharLe => "char<=?"
    PrimOpKind::CharGe => "char>=?"
    PrimOpKind::CharAlphabeticP => "char-alphabetic?"
    PrimOpKind::CharNumericP => "char-numeric?"
    PrimOpKind::CharWhitespaceP => "char-whitespace?"
    PrimOpKind::CharUpperCaseP => "char-upper-case?"
    PrimOpKind::CharLowerCaseP => "char-lower-case?"
    PrimOpKind::CharUpcase => "char-upcase"
    PrimOpKind::CharDowncase => "char-downcase"
    PrimOpKind::CharToInteger => "char->integer"
    PrimOpKind::IntegerToChar => "integer->char"
    PrimOpKind::StringLength => "string-length"
    PrimOpKind::StringRef => "string-ref"
    PrimOpKind::StringAppend => "string-append"
    PrimOpKind::StringEq => "string=?"
    PrimOpKind::StringLt => "string<?"
    PrimOpKind::StringGt => "string>?"
    PrimOpKind::StringLe => "string<=?"
    PrimOpKind::StringGe => "string>=?"
    PrimOpKind::MakeString => "make-string"
    PrimOpKind::Substring => "substring"
    PrimOpKind::StringToList => "string->list"
    PrimOpKind::ListToString => "list->string"
    PrimOpKind::MakeVector => "make-vector"
    PrimOpKind::Vector => "vector"
    PrimOpKind::VectorLength => "vector-length"
    PrimOpKind::VectorRef => "vector-ref"
    PrimOpKind::VectorSet => "vector-set!"
    PrimOpKind::VectorToList => "vector->list"
    PrimOpKind::ListToVector => "list->vector"
    PrimOpKind::Floor => "floor"
    PrimOpKind::Ceiling => "ceiling"
    PrimOpKind::Truncate => "truncate"
    PrimOpKind::Round => "round"
    PrimOpKind::Sqrt => "sqrt"
    PrimOpKind::Expt => "expt"
    PrimOpKind::Sin => "sin"
    PrimOpKind::Cos => "cos"
    PrimOpKind::Tan => "tan"
    PrimOpKind::Asin => "asin"
    PrimOpKind::Acos => "acos"
    PrimOpKind::Atan => "atan"
    PrimOpKind::Exp => "exp"
    PrimOpKind::Log => "log"
    PrimOpKind::NumberToString => "number->string"
    PrimOpKind::StringToNumber => "string->number"
    PrimOpKind::SymbolToString => "symbol->string"
    PrimOpKind::StringToSymbol => "string->symbol"
    PrimOpKind::MakeRectangular => "make-rectangular"
    PrimOpKind::MakePolar => "make-polar"
    PrimOpKind::RealPart => "real-part"
    PrimOpKind::ImagPart => "imag-part"
    PrimOpKind::Magnitude => "magnitude"
    PrimOpKind::Angle => "angle"
    PrimOpKind::ComplexP => "complex?"
    PrimOpKind::Numerator => "numerator"
    PrimOpKind::Denominator => "denominator"
    PrimOpKind::RationalP => "rational?"
    PrimOpKind::ExactP => "exact?"
    PrimOpKind::InexactP => "inexact?"
    PrimOpKind::InputPortP => "input-port?"
    PrimOpKind::OutputPortP => "output-port?"
    PrimOpKind::OpenInputFile => "open-input-file"
    PrimOpKind::OpenOutputFile => "open-output-file"
    PrimOpKind::CloseInputPort => "close-input-port"
    PrimOpKind::CloseOutputPort => "close-output-port"
    PrimOpKind::ReadChar => "read-char"
    PrimOpKind::PeekChar => "peek-char"
    PrimOpKind::WriteChar => "write-char"
    PrimOpKind::EofObjectP => "eof-object?"
    PrimOpKind::Assq => "assq"
    PrimOpKind::Assv => "assv"
    PrimOpKind::Assoc => "assoc"
    PrimOpKind::Memq => "memq"
    PrimOpKind::Memv => "memv"
    PrimOpKind::Member => "member"
    PrimOpKind::Caar => "caar"
    PrimOpKind::Cadr => "cadr"
    PrimOpKind::Cdar => "cdar"
    PrimOpKind::Cddr => "cddr"
    PrimOpKind::Caaar => "caaar"
    PrimOpKind::Caadr => "caadr"
    PrimOpKind::Cadar => "cadar"
    PrimOpKind::Caddr => "caddr"
    PrimOpKind::Cdaar => "cdaar"
    PrimOpKind::Cdadr => "cdadr"
    PrimOpKind::Cddar => "cddar"
    PrimOpKind::Cdddr => "cdddr"
    // String comparison (case-insensitive)
    _ => kind.to_string()
  }
}

/// Perform primitive operations
fn vm_exec_primop(
  vm : VMState,
  kind : PrimOpKind,
  argc : Int
) -> Result[Value, VMError] {
  let args : Array[Value] = []
  let mut i = 0
  while i < argc {
    match vm_pop(vm) {
      Ok(v) => args.push(v)
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  args.rev_in_place()

  match kind {
    PrimOpKind::Add => vm_exec_add(args)
    PrimOpKind::Sub => vm_exec_sub(args)
    PrimOpKind::Mul => vm_exec_mul(args)
    PrimOpKind::Div => vm_exec_div(args)
    PrimOpKind::NumEq => vm_exec_num_eq(args)
    PrimOpKind::Lt => vm_exec_lt(args)
    PrimOpKind::Gt => vm_exec_gt(args)
    PrimOpKind::Le => vm_exec_le(args)
    PrimOpKind::Ge => vm_exec_ge(args)
    PrimOpKind::Cons => vm_exec_cons(args)
    PrimOpKind::Car => vm_exec_car(args)
    PrimOpKind::Cdr => vm_exec_cdr(args)
    PrimOpKind::NullP => vm_exec_null_p(args)
    PrimOpKind::PairP => vm_exec_pair_p(args)
    PrimOpKind::Not => vm_exec_not(args)
    PrimOpKind::List => vm_exec_list(args)
    PrimOpKind::Length => vm_exec_length(args)
    PrimOpKind::Append => vm_exec_append(args)
    PrimOpKind::Eq => vm_exec_eq_p(args)
    PrimOpKind::Eqv => vm_exec_eqv_p(args)
    PrimOpKind::Equal => vm_exec_equal_p(args)
    PrimOpKind::ZeroP => vm_exec_zero_p(args)
    PrimOpKind::PositiveP => vm_exec_positive_p(args)
    PrimOpKind::NegativeP => vm_exec_negative_p(args)
    PrimOpKind::NumberP => vm_exec_number_p(args)
    PrimOpKind::BooleanP => vm_exec_boolean_p(args)
    PrimOpKind::SymbolP => vm_exec_symbol_p(args)
    PrimOpKind::StringP => vm_exec_string_p(args)
    PrimOpKind::ProcedureP => vm_exec_procedure_p(args)
    PrimOpKind::SymbolToString => vm_exec_symbol_to_string(args)
    PrimOpKind::StringToSymbol => vm_exec_string_to_symbol(args)
    PrimOpKind::Caar => vm_exec_caar(args)
    PrimOpKind::Cadr => vm_exec_cadr(args)
    PrimOpKind::Cdar => vm_exec_cdar(args)
    PrimOpKind::Cddr => vm_exec_cddr(args)
    PrimOpKind::Caaar => vm_exec_caaar(args)
    PrimOpKind::Caadr => vm_exec_caadr(args)
    PrimOpKind::Cadar => vm_exec_cadar(args)
    PrimOpKind::Caddr => vm_exec_caddr(args)
    PrimOpKind::Cdaar => vm_exec_cdaar(args)
    PrimOpKind::Cdadr => vm_exec_cdadr(args)
    PrimOpKind::Cddar => vm_exec_cddar(args)
    PrimOpKind::Cdddr => vm_exec_cdddr(args)
    _ => {
      // Higher-order primitives: delegate to apply_builtin with active VM context
      let prev_module = active_vm_module.val
      let prev_globals = active_vm_globals.val
      active_vm_module.val = Some(vm.compiled_module)
      active_vm_globals.val = Some(vm.globals)
      let name = primop_to_builtin_name(kind)
      let result = match apply_builtin(name, args) {
        Ok(v) => Ok(v)
        Err(e) => Err(VMError::RuntimeError(e.to_string()))
      }
      active_vm_module.val = prev_module
      active_vm_globals.val = prev_globals
      result
    }
  }
}

/// addition
fn vm_exec_add(args : Array[Value]) -> Result[Value, VMError] {
  let mut result = 0
  for arg in args {
    match arg {
      Value::Number(Number::Int(n)) => result = result + n
      _ => return Err(VMError::TypeError("+ requires numbers"))
    }
  }
  Ok(Value::Number(Number::Int(result)))
}

/// subtraction
fn vm_exec_sub(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() == 0 {
    return Err(VMError::ArityError("- requires at least 1 argument"))
  }
  if args.length() == 1 {
    match args[0] {
      Value::Number(Number::Int(n)) => return Ok(Value::Number(Number::Int(-n)))
      _ => return Err(VMError::TypeError("- requires numbers"))
    }
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("- requires numbers"))
  }
  let mut result = first
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => result = result - n
      _ => return Err(VMError::TypeError("- requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Number(Number::Int(result)))
}

/// multiplication
fn vm_exec_mul(args : Array[Value]) -> Result[Value, VMError] {
  let mut result = 1
  for arg in args {
    match arg {
      Value::Number(Number::Int(n)) => result = result * n
      _ => return Err(VMError::TypeError("* requires numbers"))
    }
  }
  Ok(Value::Number(Number::Int(result)))
}

/// division
fn vm_exec_div(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Err(VMError::ArityError("/ requires at least 2 arguments"))
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("/ requires numbers"))
  }
  let mut result = first
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if n == 0 {
          return Err(VMError::DivisionByZero)
        }
        result = result / n
      }
      _ => return Err(VMError::TypeError("/ requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Number(Number::Int(result)))
}

/// Numerical equivalent
fn vm_exec_num_eq(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) =>
        if n != first {
          return Ok(Value::Bool(false))
        }
      _ => return Err(VMError::TypeError("= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// Smaller
fn vm_exec_lt(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("< requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev >= n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("< requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// big
fn vm_exec_gt(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("> requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev <= n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("> requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// below
fn vm_exec_le(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("<= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev > n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("<= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// That's all
fn vm_exec_ge(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError(">= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev < n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError(">= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// cons
fn vm_exec_cons(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("cons requires 2 arguments"))
  }
  gc_track_pair()
  Ok(make_pair(args[0], args[1]))
}

/// car
fn vm_exec_car(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("car requires 1 argument"))
  }
  match args[0] {
    Value::Pair(car, _, _) => Ok(car)
    _ => Err(VMError::TypeError("car requires a pair"))
  }
}

/// cdr
fn vm_exec_cdr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, cdr, _) => Ok(cdr)
    _ => Err(VMError::TypeError("cdr requires a pair"))
  }
}

/// caar
fn vm_exec_caar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("caar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(caar, _, _), _, _) => Ok(caar)
    _ => Err(VMError::TypeError("caar requires nested pair"))
  }
}

/// cadr
fn vm_exec_cadr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cadr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(cadr, _, _), _) => Ok(cadr)
    _ => Err(VMError::TypeError("cadr requires pair with cdr being pair"))
  }
}

/// cdar
fn vm_exec_cdar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, cdar, _), _, _) => Ok(cdar)
    _ => Err(VMError::TypeError("cdar requires pair with car being pair"))
  }
}

/// cddr
fn vm_exec_cddr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cddr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, cddr, _), _) => Ok(cddr)
    _ => Err(VMError::TypeError("cddr requires pair with cdr being pair"))
  }
}

/// caaar
fn vm_exec_caaar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("caaar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(caaar, _, _), _, _), _, _) => Ok(caaar)
    _ => Err(VMError::TypeError("caaar requires deeply nested pair"))
  }
}

/// caadr
fn vm_exec_caadr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("caadr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(caadr, _, _), _, _), _) => Ok(caadr)
    _ => Err(VMError::TypeError("caadr requires deeply nested pair"))
  }
}

/// cadar
fn vm_exec_cadar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cadar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(cadar, _, _), _), _, _) => Ok(cadar)
    _ => Err(VMError::TypeError("cadar requires deeply nested pair"))
  }
}

/// caddr
fn vm_exec_caddr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("caddr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(caddr, _, _), _), _) => Ok(caddr)
    _ => Err(VMError::TypeError("caddr requires list with at least 3 elements"))
  }
}

/// cdaar
fn vm_exec_cdaar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdaar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(Value::Pair(_, cdaar, _), _, _), _, _) => Ok(cdaar)
    _ => Err(VMError::TypeError("cdaar requires deeply nested pair"))
  }
}

/// cdadr
fn vm_exec_cdadr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdadr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(Value::Pair(_, cdadr, _), _, _), _) => Ok(cdadr)
    _ => Err(VMError::TypeError("cdadr requires deeply nested pair"))
  }
}

/// cddar
fn vm_exec_cddar(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cddar requires 1 argument"))
  }
  match args[0] {
    Value::Pair(Value::Pair(_, Value::Pair(_, cddar, _), _), _, _) => Ok(cddar)
    _ => Err(VMError::TypeError("cddar requires deeply nested pair"))
  }
}

/// cdddr
fn vm_exec_cdddr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdddr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, Value::Pair(_, Value::Pair(_, cdddr, _), _), _) => Ok(cdddr)
    _ => Err(VMError::TypeError("cdddr requires list with at least 3 elements"))
  }
}

/// null?
fn vm_exec_null_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("null? requires 1 argument"))
  }
  match args[0] {
    Value::Nil => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// pair?
fn vm_exec_pair_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("pair? requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, _, _) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// not
fn vm_exec_not(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("not requires 1 argument"))
  }
  match args[0] {
    Value::Bool(false) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// list
fn vm_exec_list(args : Array[Value]) -> Result[Value, VMError] {
  let mut result : Value = Value::Nil
  let mut i = args.length() - 1
  while i >= 0 {
    result = make_pair(args[i], result)
    gc_track_pair()
    i = i - 1
  }
  Ok(result)
}

/// length
fn vm_exec_length(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("length requires 1 argument"))
  }
  let mut count = 0
  let mut current = args[0]
  while true {
    match current {
      Value::Nil => return Ok(Value::Number(Number::Int(count)))
      Value::Pair(_, cdr, _) => {
        count = count + 1
        current = cdr
      }
      _ => return Err(VMError::TypeError("length requires a list"))
    }
  }
  Ok(Value::Number(Number::Int(count)))
}

/// append
fn vm_exec_append(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() == 0 {
    return Ok(Value::Nil)
  }
  if args.length() == 1 {
    return Ok(args[0])
  }

  let lists : Array[Value] = []
  let mut i = 0
  let len = args.length() - 1
  let _ = while i < len {
    lists.push(args[i])
    i = i + 1
  } else {
    ()
  }

  let mut result = args[args.length() - 1]

  let mut j = lists.length()
  let _ = while j > 0 {
    j = j - 1
    result = match vm_append_two_lists(lists[j], result) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  } else {
    ()
  }

  Ok(result)
}

fn vm_append_two_lists(list1 : Value, list2 : Value) -> Result[Value, VMError] {
  match list1 {
    Value::Nil => Ok(list2)
    Value::Pair(car, cdr, _) => {
      let rest = match vm_append_two_lists(cdr, list2) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      gc_track_pair()
      Ok(make_pair(car, rest))
    }
    _ => Err(VMError::TypeError("append: arguments must be lists"))
  }
}

/// Value identity check (simplified version)
fn vm_values_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::Pair(_, _, id1), Value::Pair(_, _, id2)) => id1 == id2
    (Value::Procedure(Procedure::VMCont(a)), Value::Procedure(Procedure::VMCont(b))) =>
      a.id == b.id
    _ => false
  }
}

/// Value equality check (recursive)
fn vm_values_equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::String(x), Value::String(y)) => x == y
    (Value::Pair(car1, cdr1, _), Value::Pair(car2, cdr2, _)) =>
      vm_values_equal(car1, car2) && vm_values_equal(cdr1, cdr2)
    _ => false
  }
}

/// eq?
fn vm_exec_eq_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("eq? requires 2 arguments"))
  }
  Ok(Value::Bool(vm_values_eq(args[0], args[1])))
}

/// eqv?
fn vm_exec_eqv_p(args : Array[Value]) -> Result[Value, VMError] {
  vm_exec_eq_p(args)
}

/// equal?
fn vm_exec_equal_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("equal? requires 2 arguments"))
  }
  Ok(Value::Bool(vm_values_equal(args[0], args[1])))
}

/// zero?
fn vm_exec_zero_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("zero? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n == 0))
    _ => Err(VMError::TypeError("zero? requires a number"))
  }
}

/// positive?
fn vm_exec_positive_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("positive? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n > 0))
    _ => Err(VMError::TypeError("positive? requires a number"))
  }
}

/// negative?
fn vm_exec_negative_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("negative? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n < 0))
    _ => Err(VMError::TypeError("negative? requires a number"))
  }
}

/// number?
fn vm_exec_number_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("number? requires 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// boolean?
fn vm_exec_boolean_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("boolean? requires 1 argument"))
  }
  match args[0] {
    Value::Bool(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// symbol?
fn vm_exec_symbol_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("symbol? requires 1 argument"))
  }
  match args[0] {
    Value::Symbol(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// symbol->string
fn vm_exec_symbol_to_string(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("symbol->string requires 1 argument"))
  }
  match args[0] {
    Value::Symbol(name) => Ok(Value::String(name))
    _ => Err(VMError::TypeError("symbol->string requires a symbol"))
  }
}

/// string->symbol
fn vm_exec_string_to_symbol(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("string->symbol requires 1 argument"))
  }
  match args[0] {
    Value::String(name) => Ok(Value::Symbol(name))
    _ => Err(VMError::TypeError("string->symbol requires a string"))
  }
}

/// string?
fn vm_exec_string_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("string? requires 1 argument"))
  }
  match args[0] {
    Value::String(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// procedure?
fn vm_exec_procedure_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("procedure? requires 1 argument"))
  }
  match args[0] {
    Value::Procedure(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// Check if value is true (all are true except #f in Scheme)
fn vm_is_truthy(value : Value) -> Bool {
  match value {
    Value::Bool(false) => false
    _ => true
  }
}

/// call a function
fn vm_call_function(
  vm : VMState,
  func : Value,
  args : Array[Value],
  is_tail : Bool
) -> Result[Unit, VMError] {
  match func {
    Value::Procedure(Procedure::VMClosure(closure)) => {
      let target_chunk = vm.compiled_module.chunks[closure.chunk_idx]

      // Arity check
      if target_chunk.has_rest_param {
        // Variadic: need at least 'arity' arguments
        if target_chunk.arity >= 0 && args.length() < target_chunk.arity {
          return Err(VMError::ArityError("closure arity mismatch (too few arguments)"))
        }
      } else {
        // Fixed arity: need exactly 'arity' arguments
        if target_chunk.arity >= 0 && args.length() != target_chunk.arity {
          return Err(VMError::ArityError("closure arity mismatch"))
        }
      }

      // Prepare actual args (collect rest into list if variadic)
      let actual_args : Array[Value] = []
      if target_chunk.has_rest_param {
        // Push required args
        let mut i = 0
        while i < target_chunk.arity {
          actual_args.push(args[i])
          i = i + 1
        }
        // Collect remaining args into a list
        let mut rest_list : Value = Value::Nil
        let mut j = args.length() - 1
        while j >= target_chunk.arity {
          rest_list = make_pair(args[j], rest_list)
          j = j - 1
        }
        actual_args.push(rest_list)
      } else {
        for arg in args {
          actual_args.push(arg)
        }
      }

      if is_tail && vm.call_stack.length() > 0 {
        let frame = vm.call_stack[vm.call_stack.length() - 1]
        while vm.stack.length() > frame.base_ptr {
          let _ = vm.stack.pop()
        }
        // push capture value
        for capture in closure.captures {
          vm_push(vm, capture)
        }
        // push argument
        for arg in actual_args {
          vm_push(vm, arg)
        }
        vm.current_chunk = closure.chunk_idx
        vm.ip = 0
      } else {
        let frame : VMCallFrame = {
          return_chunk: vm.current_chunk,
          return_ip: vm.ip,
          base_ptr: vm.stack.length(),
          num_locals: closure.captures.length() + actual_args.length(),
        }
        vm.call_stack.push(frame)
        // push capture value
        for capture in closure.captures {
          vm_push(vm, capture)
        }
        // push argument
        for arg in actual_args {
          vm_push(vm, arg)
        }
        vm.current_chunk = closure.chunk_idx
        vm.ip = 0
      }
      Ok(())
    }
    Value::Procedure(Procedure::Native(name)) => {
      // Set active VM context so native builtins (like map) can call VMClosures
      let prev_module = active_vm_module.val
      let prev_globals = active_vm_globals.val
      active_vm_module.val = Some(vm.compiled_module)
      active_vm_globals.val = Some(vm.globals)
      let result = apply_builtin(name, args)
      active_vm_module.val = prev_module
      active_vm_globals.val = prev_globals
      match result {
        Ok(v) => {
          vm_push(vm, v)
          Ok(())
        }
        Err(e) => Err(VMError::RuntimeError(e.to_string()))
      }
    }
    Value::Procedure(Procedure::VMCont(cont)) => {
      if args.length() != 1 {
        return Err(VMError::ArityError("continuation requires 1 argument"))
      }
      vm.stack.clear()
      for v in cont.stack {
        vm.stack.push(v)
      }
      vm.call_stack.clear()
      for f in cont.call_stack {
        vm.call_stack.push(f)
      }
      vm_push(vm, args[0])
      vm.current_chunk = cont.return_chunk
      vm.ip = cont.return_ip
      Ok(())
    }
    _ => Err(VMError::NotAProcedure)
  }
}

/// Execute 1 instruction
pub fn vm_step(vm : VMState) -> Result[Bool, VMError] {
  let chunk = get_current_chunk(vm)
  if vm.ip >= chunk.code.length() {
    return Ok(false)
  }

  let instr = chunk.code[vm.ip]
  vm.ip = vm.ip + 1

  match instr {
    Opcode::Push(idx) => {
      let bc_val = chunk.constants[idx]
      let value = bc_value_to_value(bc_val)
      vm_push(vm, value)
      Ok(true)
    }

    Opcode::Pop => {
      match vm_pop(vm) {
        Ok(_) => Ok(true)
        Err(e) => Err(e)
      }
    }

    Opcode::LoadLocal(depth, index) => {
      match vm_get_local(vm, depth, index) {
        Ok(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::StoreLocal(depth, index) => {
      match vm_pop(vm) {
        Ok(value) =>
          match vm_set_local(vm, depth, index, value) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::LoadGlobal(idx) => {
      let name = chunk.names[idx]
      match vm.globals.get(name) {
        Some(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        None => Err(VMError::UnboundVariable(name))
      }
    }

    Opcode::StoreGlobal(idx) => {
      let name = chunk.names[idx]
      match vm_pop(vm) {
        Ok(value) => {
          vm.globals.set(name, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::MakeClosure(chunk_idx, num_captures) => {
      let captures : Array[Value] = []
      let mut i = 0
      while i < num_captures {
        match vm_pop(vm) {
          Ok(v) => captures.push(v)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      captures.rev_in_place()  // restore correct order
      let closure : VMClosure = { chunk_idx, captures }
      vm_push(vm, Value::Procedure(Procedure::VMClosure(closure)))
      gc_track_closure()
      Ok(true)
    }

    Opcode::MakeBox => {
      match vm_pop(vm) {
        Ok(val) => {
          vm_push(vm, make_box(val))
          gc_track_box()
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::BoxGet => {
      match vm_pop(vm) {
        Ok(Value::Box(cell)) => {
          vm_push(vm, cell.val)
          Ok(true)
        }
        Ok(_) => Err(VMError::TypeError("BoxGet expects Box"))
        Err(e) => Err(e)
      }
    }

    Opcode::BoxSet => {
      match vm_pop(vm) {
        Ok(new_val) => {
          match vm_pop(vm) {
            Ok(Value::Box(cell)) => {
              cell.val = new_val
              // set! returns unspecified (here nil)
              vm_push(vm, Value::Nil)
              Ok(true)
            }
            Ok(_) => Err(VMError::TypeError("BoxSet expects Box"))
            Err(e) => Err(e)
          }
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Call(argc) => {
      let args : Array[Value] = []
      let mut i = 0
      while i < argc {
        match vm_pop(vm) {
          Ok(v) => args.push(v)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      args.rev_in_place()
      match vm_pop(vm) {
        Ok(func) =>
          match vm_call_function(vm, func, args, false) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::TailCall(argc) => {
      let args : Array[Value] = []
      let mut i = 0
      while i < argc {
        match vm_pop(vm) {
          Ok(v) => args.push(v)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      args.rev_in_place()
      match vm_pop(vm) {
        Ok(func) =>
          match vm_call_function(vm, func, args, true) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::Return => {
      match vm_pop(vm) {
        Ok(result) => {
          if vm.call_stack.length() == 0 {
            vm_push(vm, result)
            return Ok(false)
          }
          let frame = vm.call_stack.pop().unwrap()
          while vm.stack.length() > frame.base_ptr {
            let _ = vm.stack.pop()
          }
          vm_push(vm, result)
          vm.current_chunk = frame.return_chunk
          vm.ip = frame.return_ip
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Jump(target) => {
      vm.ip = target
      Ok(true)
    }

    Opcode::JumpIfFalse(target) => {
      match vm_pop(vm) {
        Ok(value) => {
          if not(vm_is_truthy(value)) {
            vm.ip = target
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::PrimCall(kind, argc) => {
      match vm_exec_primop(vm, kind, argc) {
        Ok(result) => {
          vm_push(vm, result)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::CaptureCC => {
      match vm_pop(vm) {
        Ok(proc) => {
          let cont_id = vm.cont_counter
          vm.cont_counter = vm.cont_counter + 1
          let stack_copy : Array[Value] = []
          for v in vm.stack {
            stack_copy.push(v)
          }
          let call_stack_copy : Array[VMCallFrame] = []
          for f in vm.call_stack {
            call_stack_copy.push(f)
          }
          let cont : VMContinuation = {
            id: cont_id,
            stack: stack_copy,
            call_stack: call_stack_copy,
            return_chunk: vm.current_chunk,
            return_ip: vm.ip,
          }
          gc_register_continuation(cont_id)
          let cont_value = Value::Procedure(Procedure::VMCont(cont))
          match vm_call_function(vm, proc, [cont_value], false) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Halt => Ok(false)

    Opcode::MakePair => {
      match vm_pop(vm) {
        Ok(cdr) =>
          match vm_pop(vm) {
            Ok(car) => {
              vm_push(vm, make_pair(car, cdr))
              gc_track_pair()
              Ok(true)
            }
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::MakeList(n) => {
      let mut result : Value = Value::Nil
      let mut i = 0
      while i < n {
        match vm_pop(vm) {
          Ok(elem) => result = make_pair(elem, result)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      vm_push(vm, result)
      Ok(true)
    }

    Opcode::MakeVector(n) => {
      let items : Array[Value] = []
      let mut i = 0
      while i < n {
        match vm_pop(vm) {
          Ok(elem) => items.push(elem)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      items.rev_in_place()
      vm_push(vm, Value::Vector(items))
      gc_track_vector()
      Ok(true)
    }

    Opcode::MakePromise(_) => {
      vm_push(vm, Value::Nil)
      Ok(true)
    }

    Opcode::AndJump(target) => {
      match vm_peek(vm) {
        Ok(value) => {
          if not(vm_is_truthy(value)) {
            vm.ip = target
          } else {
            let _ = vm_pop(vm)
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::OrJump(target) => {
      match vm_peek(vm) {
        Ok(value) => {
          if vm_is_truthy(value) {
            vm.ip = target
          } else {
            let _ = vm_pop(vm)
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Dup => {
      match vm_peek(vm) {
        Ok(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::AllocateLocals(n) => {
      let mut i = 0
      while i < n {
        vm_push(vm, Value::Nil)
        i = i + 1
      }
      Ok(true)
    }

    Opcode::InitLocal(depth, index) => {
      match vm_pop(vm) {
        Ok(value) =>
          match vm_set_local(vm, depth, index, value) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }
  }
}

/// Run the VM
pub fn vm_run(vm : VMState) -> Result[Value, VMError] {
  // Create a dummy frame for the top level
  // return_ip is set to past the end of code so that after a tail call returns,
  // execution will halt correctly (vm_step will see ip >= code.length())
  let initial_frame : VMCallFrame = {
    return_chunk: -1,
    return_ip: vm.compiled_module.main.code.length(),
    base_ptr: 0,
    num_locals: 0,
  }
  vm.call_stack.push(initial_frame)

  let mut step_count = 0
  let gc_check_interval = 1000  // GC check every 1000 steps

  while true {
    match vm_step(vm) {
      Ok(true) => {
        step_count = step_count + 1
        // Regular GC check
        if step_count % gc_check_interval == 0 {
          let _ = gc_check_and_run(vm)
        }
        continue
      }
      Ok(false) => break
      Err(e) => return Err(e)
    }
  }
  if vm.stack.length() > 0 {
    Ok(vm.stack[vm.stack.length() - 1])
  } else {
    Ok(Value::Nil)
  }
}

/// Run compiled module
pub fn vm_run_module(compiled_module : CompiledModule) -> Result[Value, VMError] {
  let vm = new_vm_state(compiled_module)
  vm_run(vm)
}

/// Execute S-expression in VM
pub fn vm_eval(expr : SExpr) -> Result[Value, String] {
  match compile_to_module(expr) {
    Ok(compiled_module) =>
      match vm_run_module(compiled_module) {
        Ok(v) => Ok(v)
        Err(e) => Err(e.to_string())
      }
    Err(e) => Err(e.to_string())
  }
}
