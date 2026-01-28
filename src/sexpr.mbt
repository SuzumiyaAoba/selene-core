/// S-expression representation of the reader/parser stage.
pub(all) enum SExpr {
  Nil
  Bool(Bool)
  Symbol(String)
  Number(Int)
  Char(Char)
  String(String)
  Pair(SExpr, SExpr)
  Vector(Array[SExpr])
  Quote(SExpr)
  Quasiquote(SExpr)
  Unquote(SExpr)
  UnquoteSplicing(SExpr)
} derive(Show, Eq)

/// Create a list of 2 elements.
pub fn list2(a : SExpr, b : SExpr) -> SExpr {
  SExpr::Pair(a, SExpr::Pair(b, SExpr::Nil))
}

/// Generate symbols.
pub fn sym(name : String) -> SExpr {
  SExpr::Symbol(name)
}
