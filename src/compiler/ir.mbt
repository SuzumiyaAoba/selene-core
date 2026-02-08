/// Intermediate representation (IR) type definition
///
/// Intermediate representation compiled from SExpr (AST).
/// Contains information on lexical addressing and tail call optimization.

/// Variable reference (lexical addressing)
pub(all) struct VarRef {
  /// Variable name (for debugging)
  name : String
  /// Lexical depth (0 = current frame, 1 = parent frame,...)
  depth : Int
  /// In-frame index
  index : Int
} derive(Show, Eq)

/// Constant value (value determined at compile time)
pub(all) enum IRConst {
  Nil
  Bool(Bool)
  Int(Int)
  Real(Double)
  Char(Char)
  String(String)
  Symbol(String)
  /// Complex data (quoted lists and vectors)
  Pair(IRConst, IRConst)
  Vector(Array[IRConst])
} derive(Show)

/// Primitive operation types
pub(all) enum PrimOpKind {
  // Arithmetic operations
  Add
  Sub
  Mul
  Div
  Quotient
  Remainder
  Modulo
  Abs
  Max
  Min
  Gcd
  Lcm

  // Relations
  NumEq
  Lt
  Gt
  Le
  Ge
  Eq
  Eqv
  Equal

  // Numeric predicate
  ZeroP
  PositiveP
  NegativeP
  OddP
  EvenP

  // Type predicate
  PairP
  NumberP
  IntegerP
  RealP
  BooleanP
  SymbolP
  NullP
  ProcedureP
  ListP
  StringP
  CharP
  VectorP
  PromiseP
  PortP

  // List operations
  Cons
  Car
  Cdr
  SetCar
  SetCdr
  List
  Length
  Append
  Reverse
  ListRef
  ListTail

  // Character manipulation
  CharEq
  CharLt
  CharGt
  CharLe
  CharGe
  CharAlphabeticP
  CharNumericP
  CharWhitespaceP
  CharUpperCaseP
  CharLowerCaseP
  CharUpcase
  CharDowncase
  CharToInteger
  IntegerToChar

  // String manipulation
  StringLength
  StringRef
  StringAppend
  StringEq
  StringLt
  StringGt
  StringLe
  StringGe
  MakeString
  Substring
  StringToList
  ListToString

  // Vector manipulation
  MakeVector
  Vector
  VectorLength
  VectorRef
  VectorSet
  VectorToList
  ListToVector

  // Mathematical Functions
  Floor
  Ceiling
  Truncate
  Round
  Sqrt
  Expt
  Sin
  Cos
  Tan
  Asin
  Acos
  Atan
  Exp
  Log

  // Conversion
  NumberToString
  StringToNumber
  SymbolToString
  StringToSymbol

  // Logical connective
  Not

  // Complex number
  MakeRectangular
  MakePolar
  RealPart
  ImagPart
  Magnitude
  Angle
  ComplexP

  // Set of rational numbers
  Numerator
  Denominator
  RationalP

  // Numerical Interpretation
  ExactP
  InexactP

  // I/O
  Display
  Newline
  Write
  Read

  // Port
  InputPortP
  OutputPortP
  OpenInputFile
  OpenOutputFile
  CloseInputPort
  CloseOutputPort
  ReadChar
  PeekChar
  WriteChar
  EofObjectP

  // Controlled
  Apply
  Map
  ForEach
  Filter
  FoldLeft
  FoldRight
  Force
  Values
  CallWithValues
  DynamicWind

  // Associations List
  Assq
  Assv
  Assoc

  // Membership
  Memq
  Memv
  Member

  // cXXr accessor
  Caar
  Cadr
  Cdar
  Cddr
  Caaar
  Caadr
  Cadar
  Caddr
  Cdaar
  Cdadr
  Cddar
  Cdddr
} derive(Show)

/// let binding
pub(all) struct LetBinding {
  /// variable name
  name : String
  /// initialization expression
  init : IRExpr
} derive(Show)

/// Lambda information
pub(all) struct LambdaInfo {
  /// Parameter name (for debugging)
  params : Array[String]
  /// Number of required parameters
  arity : Int
  /// Rest parameter name (for variadic functions)
  rest_param : String?
  /// function body
  body : IRExpr
  /// List of free variables (used for closure generation)
  free_vars : Array[VarRef]
  /// Index of parameter that requires boxing
  boxed_params : Array[Int]
  /// Local variable names that require boxing
  boxed_locals : Array[String]
  /// Indices of free_vars that require boxing
  boxed_free_vars : Array[Int]
} derive(Show)

/// intermediate representation expression
pub(all) enum IRExpr {
  /// constant
  Const(IRConst)
  /// local variable reference
  Var(VarRef)
  /// Global variable reference
  GlobalVar(String)
  /// Conditional branch: (if test then else)
  If(IRExpr, IRExpr, IRExpr)
  /// Serial execution: (begin expr ...)
  Begin(Array[IRExpr])
  /// lambda expression
  Lambda(LambdaInfo)
  /// Function application: (app func args...)
  App(IRExpr, Array[IRExpr])
  /// Tail call: (tail-app func args...)
  TailApp(IRExpr, Array[IRExpr])
  /// let binding: (let ((var init) ...) body)
  Let(Array[LetBinding], IRExpr)
  /// letrec binding: (letrec ((var init) ...) body)
  Letrec(Array[LetBinding], IRExpr)
  /// Assignment: (set! var value)
  Set(VarRef, IRExpr)
  /// Global assignment: (set! global-var value)
  GlobalSet(String, IRExpr)
  /// Primitive operations: (prim-op kind args...)
  PrimOp(PrimOpKind, Array[IRExpr])
  /// Capturing a continuation: (call/cc proc)
  CallCC(IRExpr)
  /// Quote: 'datum
  Quote(IRConst)
  /// Delayed evaluation: (delay expr)
  Delay(IRExpr)
  /// and special form: (and expr ...)
  And(Array[IRExpr])
  /// or special form: (or expr ...)
  Or(Array[IRExpr])
} derive(Show)

/// compilation error
pub(all) enum CompileError {
  /// unbound variable
  UnboundVariable(String)
  /// syntax error
  SyntaxError(String)
  /// Unsupported features
  Unsupported(String)
  /// Invalid syntax (macro-related)
  InvalidSyntax(String)
  /// Macro expansion error
  MacroError(String)
} derive(Show)

/// Convert IRConst to Value
pub fn ir_const_to_value(c : IRConst) -> Value {
  match c {
    IRConst::Nil => Value::Nil
    IRConst::Bool(b) => Value::Bool(b)
    IRConst::Int(n) => Value::Number(Number::Int(n))
    IRConst::Real(r) => Value::Number(Number::Real(r))
    IRConst::Char(c) => Value::Char(c)
    IRConst::String(s) => Value::String(s)
    IRConst::Symbol(s) => Value::Symbol(s)
    IRConst::Pair(car, cdr) =>
      make_pair(ir_const_to_value(car), ir_const_to_value(cdr))
    IRConst::Vector(items) => {
      let values : Array[Value] = []
      for item in items {
        values.push(ir_const_to_value(item))
      }
      Value::Vector(values)
    }
  }
}

/// Convert SExpr to IRConst (for quoted data)
pub fn sexpr_to_ir_const(sexpr : SExpr) -> IRConst {
  match sexpr {
    SExpr::Nil => IRConst::Nil
    SExpr::Bool(b) => IRConst::Bool(b)
    SExpr::Number(n) => IRConst::Int(n)
    SExpr::Char(c) => IRConst::Char(c)
    SExpr::String(s) => IRConst::String(s)
    SExpr::Symbol(s) => IRConst::Symbol(s)
    SExpr::Pair(car, cdr) =>
      IRConst::Pair(sexpr_to_ir_const(car), sexpr_to_ir_const(cdr))
    SExpr::Vector(items) => {
      let ir_items : Array[IRConst] = []
      for item in items {
        ir_items.push(sexpr_to_ir_const(item))
      }
      IRConst::Vector(ir_items)
    }
    SExpr::Quote(inner) => sexpr_to_ir_const(inner)
    SExpr::Quasiquote(inner) =>
      IRConst::Pair(IRConst::Symbol("quasiquote"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
    SExpr::Unquote(inner) =>
      IRConst::Pair(IRConst::Symbol("unquote"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
    SExpr::UnquoteSplicing(inner) =>
      IRConst::Pair(IRConst::Symbol("unquote-splicing"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
  }
}
