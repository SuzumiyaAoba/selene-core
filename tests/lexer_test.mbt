test "lex parens identifiers numbers" {
  let tokens = lex("(define x 42)")
  assert_eq(tokens.length(), 5)
  assert_eq(tokens[0].kind, LParen)
  assert_eq(tokens[1].kind, Identifier("define"))
  assert_eq(tokens[2].kind, Identifier("x"))
  assert_eq(tokens[3].kind, Number(42))
  assert_eq(tokens[4].kind, RParen)
}

test "lex comments and whitespace" {
  let tokens = lex("; comment\n(foo ; inline\n 123)\n")
  assert_eq(tokens.length(), 4)
  assert_eq(tokens[0].kind, LParen)
  assert_eq(tokens[1].kind, Identifier("foo"))
  assert_eq(tokens[2].kind, Number(123))
  assert_eq(tokens[3].kind, RParen)
}
