/// Basic token types for the initial lexer phase.
pub enum Token {
  LParen
  RParen
  Identifier(String)
  Number(Int)
  Boolean(Bool)
  String(String)
  Char(Char)
  Quote           // '
  Quasiquote      // `
  Unquote         // ,
  UnquoteSplicing // ,@
} derive(Show, Eq)
