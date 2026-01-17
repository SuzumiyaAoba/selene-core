/// 基本トークンの分割ができることを確認する。
test "lex parens identifiers numbers" {
  let tokens = tokenize("(define x 42)")
  assert_eq(tokens.length(), 5)
  assert_eq(token_snapshot(tokens[0]), "LParen")
  assert_eq(token_snapshot(tokens[1]), "Identifier(define)")
  assert_eq(token_snapshot(tokens[2]), "Identifier(x)")
  assert_eq(token_snapshot(tokens[3]), "Number(42)")
  assert_eq(token_snapshot(tokens[4]), "RParen")
}

/// コメント/空白が無視されることを確認する。
test "lex comments and whitespace" {
  let tokens = tokenize("; comment\n(foo ; inline\n 123)\n")
  assert_eq(tokens.length(), 4)
  assert_eq(token_snapshot(tokens[0]), "LParen")
  assert_eq(token_snapshot(tokens[1]), "Identifier(foo)")
  assert_eq(token_snapshot(tokens[2]), "Number(123)")
  assert_eq(token_snapshot(tokens[3]), "RParen")
}

/// トークンをスナップショット用の文字列に変換する。
fn token_snapshot(token : Token) -> String {
  match token {
    Token::LParen => "LParen"
    Token::RParen => "RParen"
    Token::Identifier(name) => "Identifier(" + name + ")"
    Token::Number(value) => "Number(" + value.to_string() + ")"
    Token::Boolean(b) => "Boolean(" + b.to_string() + ")"
    Token::String(s) => "String(" + s + ")"
    Token::Char(c) => "Char(" + c.to_string() + ")"
    Token::Quote => "Quote"
    Token::Quasiquote => "Quasiquote"
    Token::Unquote => "Unquote"
    Token::UnquoteSplicing => "UnquoteSplicing"
  }
}

/// トークン列をスナップショット用の文字列に変換する。
fn tokens_snapshot(tokens : Array[Token]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[")
  let mut i = 0
  let len = tokens.length()
  let _ = while i < len {
    if i > 0 {
      builder.write_string(", ")
    }
    builder.write_string(token_snapshot(tokens[i]))
    i = i + 1
  } else { () }
  builder.write_string("]")
  builder.to_string()
}

/// レキサ結果のスナップショットを固定する。
test "lexer snapshot" {
  let tokens = tokenize("(define x 42)")
  inspect(
    tokens_snapshot(tokens),
    content="[LParen, Identifier(define), Identifier(x), Number(42), RParen]",
  )
}
