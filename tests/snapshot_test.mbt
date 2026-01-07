test "lexer snapshot json" {
  let tokens = tokenize("(define x 42)")
  let expected : Json = [
    "LParen",
    ["Identifier", "define"],
    ["Identifier", "x"],
    ["Number", 42],
    "RParen",
  ]
  assert_eq(tokens.to_json(), expected)
}

test "quote expansion snapshot json" {
  let expr = SExpr::Quote(SExpr::Symbol("x"))
  let expanded = expand_quote(expr)
  let expected : Json = [
    "Pair",
    ["Symbol", "quote"],
    ["Pair", ["Symbol", "x"], "Nil"],
  ]
  assert_eq(expanded.to_json(), expected)
}

test "parser snapshot json" {
  let expr = parse_one("(define x 42)")
  let expected : Json = [
    "Pair",
    ["Symbol", "define"],
    [
      "Pair",
      ["Symbol", "x"],
      ["Pair", ["Number", 42], "Nil"],
    ],
  ]
  assert_eq(expr.to_json(), expected)
}
