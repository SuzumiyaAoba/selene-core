///|
/// Basic token types for the initial lexer phase.
pub enum Token {
  LParen
  RParen
  Identifier(String)
  Number(Int)
  Real(Double)
  Boolean(Bool)
  String(String)
  Char(Char)
  Quote // '
  Quasiquote // `
  Unquote // ,
  UnquoteSplicing // ,@
  Dot // . (improper list notation)
} derive(Show, Eq)
