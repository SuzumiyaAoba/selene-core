/// Basic token types for the initial lexer phase.
pub enum Token {
  LParen
  RParen
  Identifier(String)
  Number(Int)
} derive(Show, Eq)
