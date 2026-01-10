/// リーダ/パーサ段階の S 式表現。
pub(all) enum SExpr {
  Nil
  Symbol(String)
  Number(Int)
  Bool(Bool)
  Pair(SExpr, SExpr)
  Vector(Array[SExpr])
  Quote(SExpr)
  Quasiquote(SExpr)
  Unquote(SExpr)
  UnquoteSplicing(SExpr)
} derive(Show, Eq)

/// 2 要素のリストを作る。
pub fn list2(a : SExpr, b : SExpr) -> SExpr {
  SExpr::Pair(a, SExpr::Pair(b, SExpr::Nil))
}

/// シンボルを生成する。
pub fn sym(name : String) -> SExpr {
  SExpr::Symbol(name)
}
