test "expand simple quote" {
  let expr = SExpr::Quote(SExpr::Symbol("x"))
  let expected = list2(sym("quote"), SExpr::Symbol("x"))
  assert_eq(expand_quote(expr), expected)
}

test "expand quasiquote with unquote" {
  let expr = SExpr::Quasiquote(
    SExpr::Pair(
      SExpr::Symbol("a"),
      SExpr::Pair(SExpr::Unquote(SExpr::Symbol("b")), SExpr::Nil)
    )
  )
  let expected = list2(
    sym("quasiquote"),
    SExpr::Pair(
      SExpr::Symbol("a"),
      SExpr::Pair(list2(sym("unquote"), SExpr::Symbol("b")), SExpr::Nil)
    )
  )
  assert_eq(expand_quote(expr), expected)
}

test "expand in vector" {
  let expr = SExpr::Vector([SExpr::UnquoteSplicing(SExpr::Symbol("xs"))])
  let expected = SExpr::Vector([
    list2(sym("unquote-splicing"), SExpr::Symbol("xs"))
  ])
  assert_eq(expand_quote(expr), expected)
}
