/// Runtime values ​​(draft) of the Scheme evaluator.

/// Numeric type (R5RS numeric tower)
/// Int < Rational < Real < Complex
pub(all) enum Number {
  Int(Int)
  /// Rational numbers: numerator and denominator (always kept as irreducible fractions)
  Rational(Int, Int)
  Real(Double)
  /// Complex numbers: real and imaginary parts
  Complex(Double, Double)
} derive(Show)

/// Calculate the greatest common divisor
pub fn gcd_int(a : Int, b : Int) -> Int {
  let mut x = if a < 0 { -a } else { a }
  let mut y = if b < 0 { -b } else { b }
  while y != 0 {
    let temp = y
    y = x % y
    x = temp
  }
  x
}

/// Normalize rational numbers to irreducible fractions
pub fn normalize_rational(numer : Int, denom : Int) -> Number {
  if denom == 0 {
    // Divide-by-zero error (should actually be checked on the caller side)
    Number::Int(0)
  } else if numer == 0 {
    Number::Int(0)
  } else {
    let g = gcd_int(numer, denom)
    let n = numer / g
    let d = denom / g
    // If the denominator is negative, move the sign to the numerator
    let (n, d) = if d < 0 { (-n, -d) } else { (n, d) }
    if d == 1 {
      Number::Int(n)
    } else {
      Number::Rational(n, d)
    }
  }
}

/// A type that represents a continuation.
/// Used in CPS converted evaluators.
pub(all) struct Continuation {
  /// continuation identifier
  id : Int
} derive(Show)

/// Continuation counter (global)
let continuation_counter : Ref[Int] = { val: 0 }

/// Generate a new continuation ID.
pub fn new_continuation_id() -> Int {
  let id = continuation_counter.val
  continuation_counter.val = continuation_counter.val + 1
  id
}

/// VM closure (forward declaration)
pub(all) struct VMClosure {
  chunk_idx : Int
  captures : Array[Value]
} derive(Show)

/// VM continuation (forward declaration)
pub(all) struct VMContinuation {
  id : Int
  stack : Array[Value]
  call_stack : Array[VMCallFrame]
  return_chunk : Int
  return_ip : Int
} derive(Show)

/// VM call frame (forward declaration)
pub(all) struct VMCallFrame {
  return_chunk : Int
  return_ip : Int
  base_ptr : Int
  num_locals : Int
} derive(Show)

/// procedural expression.
pub(all) enum Procedure {
  Native(String)
  Closure(Array[String], SExpr, Env)
  Cont(Continuation)  // Continuation of first class
  VMClosure(VMClosure)  // VM closure
  VMCont(VMContinuation)  // VM continuation
} derive(Show)

/// A type representing a continuation call.
/// This value is thrown when the continuation is called.
pub(all) struct ContinuationCall {
  cont_id : Int
  value : Value
} derive(Show)

/// Continuous store (global)
/// Mapping from continuation ID to continuation state
struct ContinuationState {
  /// A callback that receives the value to return when the continuation is called
  /// (actually represents the “remaining” of the evaluation)
  env : Env
  /// Expression at the time the continuation was captured (for debugging)
  captured_at : String
}

let continuation_store : Array[(Int, ContinuationState)] = []

/// Save continuation.
pub fn store_continuation(id : Int, env : Env, captured_at : String) -> Unit {
  continuation_store.push((id, { env, captured_at }))
}

/// Get a continuation.
pub fn get_continuation(id : Int) -> ContinuationState? {
  for entry in continuation_store {
    if entry.0 == id {
      touch_continuation_state(entry.1)
      return Some(entry.1)
    }
  }
  None
}

fn touch_continuation_state(state : ContinuationState) -> Unit {
  let _ = state.env
  let _ = state.captured_at
}

/// Remove a continuation by id.
pub fn remove_continuation(id : Int) -> Unit {
  let survivors : Array[(Int, ContinuationState)] = []
  for entry in continuation_store {
    if entry.0 != id {
      survivors.push(entry)
    }
  }
  continuation_store.clear()
  for s in survivors {
    continuation_store.push(s)
  }
}

/// Clear all continuations and reset the counter.
pub fn clear_continuations() -> Unit {
  continuation_store.clear()
  continuation_counter.val = 0
}

/// A type that represents a promise (lazy evaluation).
pub(all) struct Promise {
  /// Has it been evaluated?
  forced : Ref[Bool]
  /// Deferred expression (if unevaluated) or result (if evaluated)
  /// Unrated: Left(expr, env), Evaluated: Right(value)
  content : Ref[PromiseContent]
} derive(Show)

/// Promise content
pub(all) enum PromiseContent {
  Delayed(SExpr, Env)
  Forced(Value)
} derive(Show)

/// Syntax rules (syntax-rules macro)
pub(all) struct SyntaxRules {
  /// Literal keywords (identifiers that match exactly in the pattern)
  literals : Array[String]
  /// List of pattern and template pairs
  rules : Array[SyntaxRule]
  /// Environment at macro definition (for hygienic macros)
  def_env : Env
  /// Rename map for hygienic macro expansion (original -> gensym)
  rename_map : Map[String, String]
} derive(Show)

/// individual syntax rules
pub(all) struct SyntaxRule {
  /// Pattern (macro call format)
  pattern : SExpr
  /// Template (expanded format)
  template : SExpr
} derive(Show)

/// Port direction
pub(all) enum PortDirection {
  Input
  Output
} derive(Show, Eq)

/// Type representing port (input/output)
pub(all) struct Port {
  /// Unique identifier for the port
  id : Int
  /// input/output
  direction : PortDirection
  /// open or not
  open : Ref[Bool]
  /// Port name (file name, etc.)
  name : String
} derive(Show)

/// Port counter (global)
let port_counter : Ref[Int] = { val: 0 }

/// Generate a new port ID
pub fn new_port_id() -> Int {
  let id = port_counter.val
  port_counter.val = port_counter.val + 1
  id
}

/// Summation type of values ​​handled by the evaluator.
pub(all) enum Value {
  Nil
  Bool(Bool)
  Number(Number)
  Char(Char)
  String(String)
  Symbol(String)
  Pair(Value, Value)
  Vector(Array[Value])
  Procedure(Procedure)
  Promise(Promise)
  /// Multivalued (used with call-with-values)
  MultipleValues(Array[Value])
  /// Syntax transformer (macro)
  Syntax(SyntaxRules)
  /// Port (input/output)
  Port(Port)
  /// Boxed values ​​(for reference capture)
  Box(Ref[Value])
} derive(Show)
