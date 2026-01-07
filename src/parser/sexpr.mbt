/// S-expression representation for reader/parser stages.
pub(all) enum SExpr {
  Nil
  Symbol(String)
  Number(Int)
  Pair(SExpr, SExpr)
  Vector(Array[SExpr])
  Quote(SExpr)
  Quasiquote(SExpr)
  Unquote(SExpr)
  UnquoteSplicing(SExpr)
} derive(Show, Eq)

pub fn list2(a : SExpr, b : SExpr) -> SExpr {
  SExpr::Pair(a, SExpr::Pair(b, SExpr::Nil))
}

pub fn sym(name : String) -> SExpr {
  SExpr::Symbol(name)
}
