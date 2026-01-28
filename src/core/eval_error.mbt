/// Evaluation errors.
pub(all) enum EvalError {
  UnboundVariable(String)
  InvalidSyntax(String)
  TypeError(String)
  ArityError(String)
  /// Indicates that a continuation has been called (escape continuation)
  ContinuationInvoked(Int, Value)
} derive(Show)
