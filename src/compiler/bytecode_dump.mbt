/// Bytecode Dump Tool
///
/// Display compiled compiled_mods in a human-readable format:
/// - Dump the entire compiled_mod
/// - Detailed view by chunk
/// - Disassembling orders
/// - View Constant Pool Name Table

/// Dump Options
pub(all) struct DumpOptions {
  /// Advanced Mode (Include Constant Pool, Name Table)
  verbose : Bool
  /// Display instruction address in hexadecimal
  hex_addresses : Bool
  /// Show constant values inline
  inline_constants : Bool
  /// Indent Width
  indent_width : Int
}

/// Default dump options
pub fn default_dump_options() -> DumpOptions {
  {
    verbose: true,
    hex_addresses: false,
    inline_constants: true,
    indent_width: 2,
  }
}

/// Concise dump options
pub fn compact_dump_options() -> DumpOptions {
  {
    verbose: false,
    hex_addresses: false,
    inline_constants: true,
    indent_width: 2,
  }
}

/// Dump Entire Module
pub fn dump_compiled_mod(compiled_mod : CompiledModule, options : DumpOptions) -> String {
  let mut result = "=".repeat(60) + "\n"
  result = result + "BYTECODE MODULE DUMP\n"
  result = result + "=".repeat(60) + "\n\n"

  // Main chunk
  result = result + "MAIN CHUNK:\n"
  result = result + "-".repeat(40) + "\n"
  result = result + dump_chunk(compiled_mod.main, -1, compiled_mod, options)
  result = result + "\n"

  // Child chunks
  if compiled_mod.chunks.length() > 0 {
    result = result + "CHILD CHUNKS (" + compiled_mod.chunks.length().to_string() + "):\n"
    result = result + "-".repeat(40) + "\n\n"

    let mut i = 0
    while i < compiled_mod.chunks.length() {
      let chunk = compiled_mod.chunks[i]
      result = result + "CHUNK #" + i.to_string()
      match chunk.debug_name {
        Some(name) => result = result + " (" + name + ")"
        None => ()
      }
      result = result + ":\n"
      result = result + dump_chunk(chunk, i, compiled_mod, options)
      result = result + "\n"
      i = i + 1
    }
  }

  result = result + "=".repeat(60) + "\n"
  result = result + "END OF DUMP\n"
  result = result + "=".repeat(60) + "\n"

  result
}

/// Dump Single Chunk
pub fn dump_chunk(
  chunk : CodeChunk,
  chunk_idx : Int,
  compiled_mod : CompiledModule,
  options : DumpOptions
) -> String {
  let indent = " ".repeat(options.indent_width)
  let mut result = ""

  // Basic Info
  result = result + indent + "Arity: " + chunk.arity.to_string() + "\n"
  result = result + indent + "Locals: " + chunk.num_locals.to_string() + "\n"
  result = result + indent + "Free vars: " + chunk.num_free_vars.to_string() + "\n"
  match chunk.debug_name {
    Some(name) => result = result + indent + "Name: " + name + "\n"
    None => ()
  }
  result = result + "\n"

  // Show Constant Pool and Name Table in Advanced Mode
  if options.verbose {
    result = result + dump_constants(chunk, options)
    result = result + dump_names(chunk, options)
  }

  // Code
  result = result + dump_code(chunk, chunk_idx, compiled_mod, options)

  result
}

/// Dump Constant Pool
fn dump_constants(chunk : CodeChunk, options : DumpOptions) -> String {
  if chunk.constants.length() == 0 {
    return ""
  }

  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Constants:\n"

  let mut i = 0
  while i < chunk.constants.length() {
    let const_val = chunk.constants[i]
    result = result + indent + indent + "[" + format_index(i, options) + "] " +
      dump_bc_value(const_val) + "\n"
    i = i + 1
  }
  result = result + "\n"

  result
}

/// Dump Name Table
fn dump_names(chunk : CodeChunk, options : DumpOptions) -> String {
  if chunk.names.length() == 0 {
    return ""
  }

  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Names:\n"

  let mut i = 0
  while i < chunk.names.length() {
    result = result + indent + indent + "[" + format_index(i, options) + "] " +
      chunk.names[i] + "\n"
    i = i + 1
  }
  result = result + "\n"

  result
}

/// Dump code (disassembly)
fn dump_code(
  chunk : CodeChunk,
  _chunk_idx : Int,
  _compiled_mod : CompiledModule,
  options : DumpOptions
) -> String {
  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Code:\n"

  let mut i = 0
  while i < chunk.code.length() {
    let opcode = chunk.code[i]
    result = result + indent + indent +
      format_address(i, options) + ": " +
      dump_opcode(opcode, chunk, options) + "\n"
    i = i + 1
  }

  result
}

/// Format Index
fn format_index(idx : Int, options : DumpOptions) -> String {
  if options.hex_addresses {
    "0x" + int_to_hex(idx)
  } else {
    idx.to_string()
  }
}

/// Format Address
fn format_address(addr : Int, options : DumpOptions) -> String {
  if options.hex_addresses {
    dump_pad_left("0x" + int_to_hex(addr), 8, ' ')
  } else {
    dump_pad_left(addr.to_string(), 4, ' ')
  }
}

/// Convert an integer to a hexadecimal string
fn int_to_hex(n : Int) -> String {
  if n == 0 {
    return "0"
  }

  let hex_chars = "0123456789ABCDEF"
  let chars = hex_chars.to_array()
  let mut result = ""
  let mut num = n

  while num > 0 {
    let digit = num % 16
    result = chars[digit].to_string() + result
    num = num / 16
  }

  result
}

/// Dump BCValue
fn dump_bc_value(value : BCValue) -> String {
  match value {
    BCValue::Nil => "nil"
    BCValue::Bool(true) => "#t"
    BCValue::Bool(false) => "#f"
    BCValue::Int(n) => "int(" + n.to_string() + ")"
    BCValue::Real(r) => "real(" + r.to_string() + ")"
    BCValue::Char(c) => "char(#\\" + c.to_string() + ")"
    BCValue::String(s) => "string(\"" + escape_string(s) + "\")"
    BCValue::Symbol(s) => "symbol(" + s + ")"
    BCValue::Closure(idx) => "closure(#" + idx.to_string() + ")"
  }
}

/// Escape String
fn escape_string(s : String) -> String {
  let mut result = ""
  let chars = s.to_array()
  for c in chars {
    if c == '\n' {
      result = result + "\\n"
    } else if c == '\t' {
      result = result + "\\t"
    } else if c == '\r' {
      result = result + "\\r"
    } else if c == '"' {
      result = result + "\\\""
    } else if c == '\\' {
      result = result + "\\\\"
    } else {
      result = result + c.to_string()
    }
  }
  result
}

/// Dump Opcode
fn dump_opcode(opcode : Opcode, chunk : CodeChunk, options : DumpOptions) -> String {
  match opcode {
    Opcode::Push(idx) => {
      let mut result = "PUSH " + idx.to_string()
      if options.inline_constants && idx < chunk.constants.length() {
        result = result + "  ; " + dump_bc_value(chunk.constants[idx])
      }
      result
    }

    Opcode::Pop => "POP"

    Opcode::LoadLocal(depth, index) =>
      "LOAD_LOCAL " + depth.to_string() + ", " + index.to_string()

    Opcode::StoreLocal(depth, index) =>
      "STORE_LOCAL " + depth.to_string() + ", " + index.to_string()

    Opcode::LoadGlobal(idx) => {
      let mut result = "LOAD_GLOBAL " + idx.to_string()
      if options.inline_constants && idx < chunk.names.length() {
        result = result + "  ; " + chunk.names[idx]
      }
      result
    }

    Opcode::StoreGlobal(idx) => {
      let mut result = "STORE_GLOBAL " + idx.to_string()
      if options.inline_constants && idx < chunk.names.length() {
        result = result + "  ; " + chunk.names[idx]
      }
      result
    }

    Opcode::MakeClosure(chunk_idx, num_captures) =>
      "MAKE_CLOSURE " + chunk_idx.to_string() + ", " + num_captures.to_string()

    Opcode::MakeBox => "MAKE_BOX"

    Opcode::BoxGet => "BOX_GET"

    Opcode::BoxSet => "BOX_SET"

    Opcode::Call(argc) => "CALL " + argc.to_string()

    Opcode::TailCall(argc) => "TAIL_CALL " + argc.to_string()

    Opcode::Return => "RETURN"

    Opcode::Jump(target) => "JUMP " + target.to_string()

    Opcode::JumpIfFalse(target) => "JUMP_IF_FALSE " + target.to_string()

    Opcode::PrimCall(kind, argc) =>
      "PRIM_CALL " + dump_primop_name(kind) + ", " + argc.to_string()

    Opcode::CaptureCC => "CAPTURE_CC"

    Opcode::Halt => "HALT"

    Opcode::MakePair => "MAKE_PAIR"

    Opcode::MakeList(n) => "MAKE_LIST " + n.to_string()

    Opcode::MakeVector(n) => "MAKE_VECTOR " + n.to_string()

    Opcode::MakePromise(chunk_idx) => "MAKE_PROMISE " + chunk_idx.to_string()

    Opcode::AndJump(target) => "AND_JUMP " + target.to_string()

    Opcode::OrJump(target) => "OR_JUMP " + target.to_string()

    Opcode::Dup => "DUP"

    Opcode::AllocateLocals(n) => "ALLOCATE_LOCALS " + n.to_string()

    Opcode::InitLocal(depth, index) =>
      "INIT_LOCAL " + depth.to_string() + ", " + index.to_string()
  }
}

/// Convert PrimOpKind to String
fn dump_primop_name(kind : PrimOpKind) -> String {
  match kind {
    // Arithmetic operations
    PrimOpKind::Add => "ADD"
    PrimOpKind::Sub => "SUB"
    PrimOpKind::Mul => "MUL"
    PrimOpKind::Div => "DIV"
    PrimOpKind::Quotient => "QUOTIENT"
    PrimOpKind::Remainder => "REMAINDER"
    PrimOpKind::Modulo => "MODULO"
    PrimOpKind::Abs => "ABS"
    PrimOpKind::Max => "MAX"
    PrimOpKind::Min => "MIN"
    PrimOpKind::Gcd => "GCD"
    PrimOpKind::Lcm => "LCM"
    // Relations
    PrimOpKind::NumEq => "NUM_EQ"
    PrimOpKind::Lt => "LT"
    PrimOpKind::Gt => "GT"
    PrimOpKind::Le => "LE"
    PrimOpKind::Ge => "GE"
    PrimOpKind::Eq => "EQ"
    PrimOpKind::Eqv => "EQV"
    PrimOpKind::Equal => "EQUAL"
    // Numeric predicate
    PrimOpKind::ZeroP => "ZERO_P"
    PrimOpKind::PositiveP => "POSITIVE_P"
    PrimOpKind::NegativeP => "NEGATIVE_P"
    PrimOpKind::OddP => "ODD_P"
    PrimOpKind::EvenP => "EVEN_P"
    // Type predicate
    PrimOpKind::PairP => "PAIR_P"
    PrimOpKind::NumberP => "NUMBER_P"
    PrimOpKind::IntegerP => "INTEGER_P"
    PrimOpKind::RealP => "REAL_P"
    PrimOpKind::BooleanP => "BOOLEAN_P"
    PrimOpKind::SymbolP => "SYMBOL_P"
    PrimOpKind::NullP => "NULL_P"
    PrimOpKind::ProcedureP => "PROCEDURE_P"
    PrimOpKind::ListP => "LIST_P"
    PrimOpKind::StringP => "STRING_P"
    PrimOpKind::CharP => "CHAR_P"
    PrimOpKind::VectorP => "VECTOR_P"
    PrimOpKind::PromiseP => "PROMISE_P"
    PrimOpKind::PortP => "PORT_P"
    // List operations
    PrimOpKind::Cons => "CONS"
    PrimOpKind::Car => "CAR"
    PrimOpKind::Cdr => "CDR"
    PrimOpKind::SetCar => "SET_CAR"
    PrimOpKind::SetCdr => "SET_CDR"
    PrimOpKind::List => "LIST"
    PrimOpKind::Length => "LENGTH"
    PrimOpKind::Append => "APPEND"
    PrimOpKind::Reverse => "REVERSE"
    PrimOpKind::ListRef => "LIST_REF"
    PrimOpKind::ListTail => "LIST_TAIL"
    // Character manipulation
    PrimOpKind::CharEq => "CHAR_EQ"
    PrimOpKind::CharLt => "CHAR_LT"
    PrimOpKind::CharGt => "CHAR_GT"
    PrimOpKind::CharLe => "CHAR_LE"
    PrimOpKind::CharGe => "CHAR_GE"
    PrimOpKind::CharAlphabeticP => "CHAR_ALPHABETIC_P"
    PrimOpKind::CharNumericP => "CHAR_NUMERIC_P"
    PrimOpKind::CharWhitespaceP => "CHAR_WHITESPACE_P"
    PrimOpKind::CharUpperCaseP => "CHAR_UPPER_CASE_P"
    PrimOpKind::CharLowerCaseP => "CHAR_LOWER_CASE_P"
    PrimOpKind::CharUpcase => "CHAR_UPCASE"
    PrimOpKind::CharDowncase => "CHAR_DOWNCASE"
    PrimOpKind::CharToInteger => "CHAR_TO_INTEGER"
    PrimOpKind::IntegerToChar => "INTEGER_TO_CHAR"
    // String manipulation
    PrimOpKind::StringLength => "STRING_LENGTH"
    PrimOpKind::StringRef => "STRING_REF"
    PrimOpKind::StringAppend => "STRING_APPEND"
    PrimOpKind::StringEq => "STRING_EQ"
    PrimOpKind::StringLt => "STRING_LT"
    PrimOpKind::StringGt => "STRING_GT"
    PrimOpKind::StringLe => "STRING_LE"
    PrimOpKind::StringGe => "STRING_GE"
    PrimOpKind::MakeString => "MAKE_STRING"
    PrimOpKind::Substring => "SUBSTRING"
    PrimOpKind::StringToList => "STRING_TO_LIST"
    PrimOpKind::ListToString => "LIST_TO_STRING"
    // Vector manipulation
    PrimOpKind::MakeVector => "MAKE_VECTOR"
    PrimOpKind::Vector => "VECTOR"
    PrimOpKind::VectorLength => "VECTOR_LENGTH"
    PrimOpKind::VectorRef => "VECTOR_REF"
    PrimOpKind::VectorSet => "VECTOR_SET"
    PrimOpKind::VectorToList => "VECTOR_TO_LIST"
    PrimOpKind::ListToVector => "LIST_TO_VECTOR"
    // Mathematical Functions
    PrimOpKind::Floor => "FLOOR"
    PrimOpKind::Ceiling => "CEILING"
    PrimOpKind::Truncate => "TRUNCATE"
    PrimOpKind::Round => "ROUND"
    PrimOpKind::Sqrt => "SQRT"
    PrimOpKind::Expt => "EXPT"
    PrimOpKind::Sin => "SIN"
    PrimOpKind::Cos => "COS"
    PrimOpKind::Tan => "TAN"
    PrimOpKind::Asin => "ASIN"
    PrimOpKind::Acos => "ACOS"
    PrimOpKind::Atan => "ATAN"
    PrimOpKind::Exp => "EXP"
    PrimOpKind::Log => "LOG"
    // Conversion
    PrimOpKind::NumberToString => "NUMBER_TO_STRING"
    PrimOpKind::StringToNumber => "STRING_TO_NUMBER"
    PrimOpKind::SymbolToString => "SYMBOL_TO_STRING"
    PrimOpKind::StringToSymbol => "STRING_TO_SYMBOL"
    // Logical connective
    PrimOpKind::Not => "NOT"
    // Complex number
    PrimOpKind::MakeRectangular => "MAKE_RECTANGULAR"
    PrimOpKind::MakePolar => "MAKE_POLAR"
    PrimOpKind::RealPart => "REAL_PART"
    PrimOpKind::ImagPart => "IMAG_PART"
    PrimOpKind::Magnitude => "MAGNITUDE"
    PrimOpKind::Angle => "ANGLE"
    PrimOpKind::ComplexP => "COMPLEX_P"
    // Set of rational numbers
    PrimOpKind::Numerator => "NUMERATOR"
    PrimOpKind::Denominator => "DENOMINATOR"
    PrimOpKind::RationalP => "RATIONAL_P"
    // Numerical Interpretation
    PrimOpKind::ExactP => "EXACT_P"
    PrimOpKind::InexactP => "INEXACT_P"
    // I/O
    PrimOpKind::Display => "DISPLAY"
    PrimOpKind::Newline => "NEWLINE"
    PrimOpKind::Write => "WRITE"
    PrimOpKind::Read => "READ"
    // Port
    PrimOpKind::InputPortP => "INPUT_PORT_P"
    PrimOpKind::OutputPortP => "OUTPUT_PORT_P"
    PrimOpKind::OpenInputFile => "OPEN_INPUT_FILE"
    PrimOpKind::OpenOutputFile => "OPEN_OUTPUT_FILE"
    PrimOpKind::CloseInputPort => "CLOSE_INPUT_PORT"
    PrimOpKind::CloseOutputPort => "CLOSE_OUTPUT_PORT"
    PrimOpKind::ReadChar => "READ_CHAR"
    PrimOpKind::PeekChar => "PEEK_CHAR"
    PrimOpKind::WriteChar => "WRITE_CHAR"
    PrimOpKind::EofObjectP => "EOF_OBJECT_P"
    // Controlled
    PrimOpKind::Apply => "APPLY"
    PrimOpKind::Map => "MAP"
    PrimOpKind::ForEach => "FOR_EACH"
    PrimOpKind::Filter => "FILTER"
    PrimOpKind::FoldLeft => "FOLD_LEFT"
    PrimOpKind::FoldRight => "FOLD_RIGHT"
    PrimOpKind::Force => "FORCE"
    PrimOpKind::Values => "VALUES"
    PrimOpKind::CallWithValues => "CALL_WITH_VALUES"
    PrimOpKind::DynamicWind => "DYNAMIC_WIND"
    // Associations List
    PrimOpKind::Assq => "ASSQ"
    PrimOpKind::Assv => "ASSV"
    PrimOpKind::Assoc => "ASSOC"
    // Membership
    PrimOpKind::Memq => "MEMQ"
    PrimOpKind::Memv => "MEMV"
    PrimOpKind::Member => "MEMBER"
    // cXXr accessor
    PrimOpKind::Caar => "CAAR"
    PrimOpKind::Cadr => "CADR"
    PrimOpKind::Cdar => "CDAR"
    PrimOpKind::Cddr => "CDDR"
    PrimOpKind::Caaar => "CAAAR"
    PrimOpKind::Caadr => "CAADR"
    PrimOpKind::Cadar => "CADAR"
    PrimOpKind::Caddr => "CADDR"
    PrimOpKind::Cdaar => "CDAAR"
    PrimOpKind::Cdadr => "CDADR"
    PrimOpKind::Cddar => "CDDAR"
    PrimOpKind::Cdddr => "CDDDR"
  }
}

/// Left padding of strings
fn dump_pad_left(s : String, width : Int, pad_char : Char) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let mut result = ""
  let mut i = 0
  while i < width - len {
    result = result + pad_char.to_string()
    i = i + 1
  }
  result + s
}

/// Compile and dump S-expression
pub fn compile_and_dump(source : String, options : DumpOptions) -> Result[String, String] {
  let expr = parse_one(source)
  match compile_to_module(expr) {
    Ok(compiled_mod) => Ok(dump_compiled_mod(compiled_mod, options))
    Err(e) => Err(e.to_string())
  }
}

/// Compile S Expression and dump with default options
pub fn compile_and_dump_default(source : String) -> Result[String, String] {
  compile_and_dump(source, default_dump_options())
}

/// Get compiled_mod statistics
pub fn dump_compiled_mod_stats(compiled_mod : CompiledModule) -> String {
  let mut result = "Module Statistics:\n"
  result = result + "-".repeat(30) + "\n"

  // Main Chunk Statistics
  result = result + "Main chunk:\n"
  result = result + "  Code size: " + compiled_mod.main.code.length().to_string() + " instructions\n"
  result = result + "  Constants: " + compiled_mod.main.constants.length().to_string() + "\n"
  result = result + "  Names: " + compiled_mod.main.names.length().to_string() + "\n"

  // Child Chunk Statistics
  result = result + "Child chunks: " + compiled_mod.chunks.length().to_string() + "\n"

  let mut total_code = compiled_mod.main.code.length()
  let mut total_constants = compiled_mod.main.constants.length()
  let mut total_names = compiled_mod.main.names.length()

  for chunk in compiled_mod.chunks {
    total_code = total_code + chunk.code.length()
    total_constants = total_constants + chunk.constants.length()
    total_names = total_names + chunk.names.length()
  }

  result = result + "\nTotals:\n"
  result = result + "  Total code: " + total_code.to_string() + " instructions\n"
  result = result + "  Total constants: " + total_constants.to_string() + "\n"
  result = result + "  Total names: " + total_names.to_string() + "\n"

  // Order type statistics
  result = result + "\nInstruction breakdown:\n"
  let instr_counts = count_instructions(compiled_mod)
  for entry in instr_counts {
    let (name, count) = entry
    if count > 0 {
      result = result + "  " + dump_pad_left(name, 20, ' ') + ": " + count.to_string() + "\n"
    }
  }

  result
}

/// Count Instructions in Module
fn count_instructions(compiled_mod : CompiledModule) -> Array[(String, Int)] {
  let counts : @hashmap.T[String, Int] = @hashmap.new()

  fn count_chunk(chunk : CodeChunk) {
    for opcode in chunk.code {
      let name = opcode_name(opcode)
      match counts.get(name) {
        Some(n) => counts.set(name, n + 1)
        None => counts.set(name, 1)
      }
    }
  }

  count_chunk(compiled_mod.main)
  for chunk in compiled_mod.chunks {
    count_chunk(chunk)
  }

  let result : Array[(String, Int)] = []
  counts.each(fn(name, count) { result.push((name, count)) })

  // Sort by Name
  sort_by_name(result)

  result
}

/// Get the name of the opcode
fn opcode_name(opcode : Opcode) -> String {
  match opcode {
    Opcode::Push(_) => "Push"
    Opcode::Pop => "Pop"
    Opcode::LoadLocal(_, _) => "LoadLocal"
    Opcode::StoreLocal(_, _) => "StoreLocal"
    Opcode::LoadGlobal(_) => "LoadGlobal"
    Opcode::StoreGlobal(_) => "StoreGlobal"
    Opcode::MakeClosure(_, _) => "MakeClosure"
    Opcode::MakeBox => "MakeBox"
    Opcode::BoxGet => "BoxGet"
    Opcode::BoxSet => "BoxSet"
    Opcode::Call(_) => "Call"
    Opcode::TailCall(_) => "TailCall"
    Opcode::Return => "Return"
    Opcode::Jump(_) => "Jump"
    Opcode::JumpIfFalse(_) => "JumpIfFalse"
    Opcode::PrimCall(_, _) => "PrimCall"
    Opcode::CaptureCC => "CaptureCC"
    Opcode::Halt => "Halt"
    Opcode::MakePair => "MakePair"
    Opcode::MakeList(_) => "MakeList"
    Opcode::MakeVector(_) => "MakeVector"
    Opcode::MakePromise(_) => "MakePromise"
    Opcode::AndJump(_) => "AndJump"
    Opcode::OrJump(_) => "OrJump"
    Opcode::Dup => "Dup"
    Opcode::AllocateLocals(_) => "AllocateLocals"
    Opcode::InitLocal(_, _) => "InitLocal"
  }
}

/// Sort by Name
fn sort_by_name(list : Array[(String, Int)]) -> Unit {
  let n = list.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if list[j].0 > list[j + 1].0 {
        let temp = list[j]
        list[j] = list[j + 1]
        list[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
}
