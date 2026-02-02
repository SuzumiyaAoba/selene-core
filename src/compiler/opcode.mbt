/// bytecode definition
///
/// Stack-based virtual machine instruction set

/// Bytecode value (value stored in constant pool)
pub(all) enum BCValue {
  Nil
  Bool(Bool)
  Int(Int)
  Real(Double)
  Char(Char)
  String(String)
  Symbol(String)
  /// Compiled procedures (closure templates)
  Closure(Int)  // Code chunk index in constant pool
} derive(Show)

/// bytecode instructions
pub(all) enum Opcode {
  /// Push constant onto stack
  Push(Int)  // constant pool index

  /// pop stack top
  Pop

  /// Load local variables (depth, index)
  LoadLocal(Int, Int)

  /// Store in local variable (depth, index)
  StoreLocal(Int, Int)

  /// Load global variable
  LoadGlobal(Int)  // name table index

  /// Store in global variable
  StoreGlobal(Int)  // name table index

  /// Create closure (chunk_idx, num_captures)
  MakeClosure(Int, Int)

  /// Create box (wrap stack top in box)
  MakeBox

  /// extract value from box
  BoxGet

  /// Update box value
  BoxSet

  /// Function call (number of arguments)
  Call(Int)

  /// Tail call (number of arguments)
  TailCall(Int)

  /// return from function
  Return

  /// unconditional jump
  Jump(Int)  // instruction offset

  /// Conditional jump (if false)
  JumpIfFalse(Int)  // instruction offset

  /// call primitive operation
  PrimCall(PrimOpKind, Int)  // Operation type, number of arguments

  /// capture continuation
  CaptureCC

  /// Program ends
  Halt

  /// Create a pair (pop two from the stack)
  MakePair

  /// Create list (pop n items from stack)
  MakeList(Int)

  /// Create vector (pop n pieces from stack)
  MakeVector(Int)

  /// Create promise (lazy evaluation)
  MakePromise(Int)  // code chunk index

  /// and for special formats: jump if false, otherwise pop and continue
  AndJump(Int)

  /// or for special formats: jump if true, otherwise pop and continue
  OrJump(Int)

  /// Duplicate stack top
  Dup

  /// For letrec: create uninitialized slot
  AllocateLocals(Int)

  /// For letrec: initialize slot
  InitLocal(Int, Int)  // depth, index
} derive(Show)

/// Code chunks (compiled procedures)
pub(all) struct CodeChunk {
  /// instruction string
  code : Array[Opcode]
  /// constant pool
  constants : Array[BCValue]
  /// global name table
  names : Array[String]
  /// Number of required parameters (-1 is top level)
  arity : Int
  /// Whether function has rest parameter
  has_rest_param : Bool
  /// number of free variables
  num_free_vars : Int
  /// Number of local variables
  num_locals : Int
  /// Debug information (optional)
  debug_name : String?
} derive(Show)

/// compiled module
pub(all) struct CompiledModule {
  /// main code chunk
  main : CodeChunk
  /// Child chunks (such as nested functions)
  chunks : Array[CodeChunk]
} derive(Show)

/// Create new code chunk
pub fn new_code_chunk() -> CodeChunk {
  {
    code: [],
    constants: [],
    names: [],
    arity: -1,
    has_rest_param: false,
    num_free_vars: 0,
    num_locals: 0,
    debug_name: None,
  }
}

/// code chunk builder
pub(all) struct CodeChunkBuilder {
  /// instruction string
  code : Array[Opcode]
  /// constant pool
  constants : Array[BCValue]
  /// Map for constant duplication check
  const_map : @hashmap.T[String, Int]
  /// global name table
  names : Array[String]
  /// Map for checking duplicate names
  name_map : @hashmap.T[String, Int]
  /// Number of required parameters
  mut arity : Int
  /// Whether function has rest parameter
  mut has_rest_param : Bool
  /// number of free variables
  mut num_free_vars : Int
  /// Number of local variables
  mut num_locals : Int
  /// debug name
  debug_name : String?
}

/// create new builder
pub fn new_builder(debug_name : String?) -> CodeChunkBuilder {
  {
    code: [],
    constants: [],
    const_map: @hashmap.new(),
    names: [],
    name_map: @hashmap.new(),
    arity: -1,
    has_rest_param: false,
    num_free_vars: 0,
    num_locals: 0,
    debug_name,
  }
}

/// add instruction
pub fn emit(self : CodeChunkBuilder, op : Opcode) -> Unit {
  self.code.push(op)
}

/// Get current instruction position
pub fn current_pos(self : CodeChunkBuilder) -> Int {
  self.code.length()
}

/// Update instructions at specific locations (for jump destination patching)
pub fn patch(self : CodeChunkBuilder, pos : Int, op : Opcode) -> Unit {
  self.code[pos] = op
}

/// Add constant and return constant pool index
pub fn add_const(self : CodeChunkBuilder, value : BCValue) -> Int {
  // Generate key for duplicate check
  let key = bc_value_to_key(value)
  match self.const_map.get(key) {
    Some(idx) => idx
    None => {
      let idx = self.constants.length()
      self.constants.push(value)
      self.const_map.set(key, idx)
      idx
    }
  }
}

/// Convert BCValue to key string
fn bc_value_to_key(value : BCValue) -> String {
  match value {
    BCValue::Nil => "nil"
    BCValue::Bool(b) => "bool:" + b.to_string()
    BCValue::Int(n) => "int:" + n.to_string()
    BCValue::Real(r) => "real:" + r.to_string()
    BCValue::Char(c) => "char:" + c.to_int().to_string()
    BCValue::String(s) => "string:" + s
    BCValue::Symbol(s) => "symbol:" + s
    BCValue::Closure(idx) => "closure:" + idx.to_string()
  }
}

/// Add global name and return name table index
pub fn add_name(self : CodeChunkBuilder, name : String) -> Int {
  match self.name_map.get(name) {
    Some(idx) => idx
    None => {
      let idx = self.names.length()
      self.names.push(name)
      self.name_map.set(name, idx)
      idx
    }
  }
}

/// Generate code chunks from builder
pub fn build(self : CodeChunkBuilder) -> CodeChunk {
  {
    code: self.code,
    constants: self.constants,
    names: self.names,
    arity: self.arity,
    has_rest_param: self.has_rest_param,
    num_free_vars: self.num_free_vars,
    num_locals: self.num_locals,
    debug_name: self.debug_name,
  }
}

/// Convert IRConst to BCValue
pub fn ir_const_to_bc_value(c : IRConst) -> BCValue {
  match c {
    IRConst::Nil => BCValue::Nil
    IRConst::Bool(b) => BCValue::Bool(b)
    IRConst::Int(n) => BCValue::Int(n)
    IRConst::Real(r) => BCValue::Real(r)
    IRConst::Char(c) => BCValue::Char(c)
    IRConst::String(s) => BCValue::String(s)
    IRConst::Symbol(s) => BCValue::Symbol(s)
    // Pair and Vector require separate processing
    IRConst::Pair(_, _) => BCValue::Nil  // TODO: Treat as a structure
    IRConst::Vector(_) => BCValue::Nil   // TODO: Treat as a structure
  }
}

/// Convert BCValue to Value
pub fn bc_value_to_value(v : BCValue) -> Value {
  match v {
    BCValue::Nil => Value::Nil
    BCValue::Bool(b) => Value::Bool(b)
    BCValue::Int(n) => Value::Number(Number::Int(n))
    BCValue::Real(r) => Value::Number(Number::Real(r))
    BCValue::Char(c) => Value::Char(c)
    BCValue::String(s) => Value::String(s)
    BCValue::Symbol(s) => Value::Symbol(s)
    BCValue::Closure(_) => Value::Nil  // Closures are handled separately in the VM
  }
}
