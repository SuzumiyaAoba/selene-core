/// Basic token types for the initial lexer phase.
pub enum Token {
  LParen
  RParen
  Identifier(String)
  Number(Int)
  Boolean(Bool)
} derive(Show, Eq)
