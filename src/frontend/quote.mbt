/// Expands the quoting syntactic sugar (' ` , ,@) into a list in canonical form.

/// Recursively convert Quote type nodes to (quote ...) format.
pub fn expand_quote(expr : SExpr) -> SExpr {
  match expr {
    SExpr::Quote(inner) => list2(sym("quote"), expand_quote(inner))
    SExpr::Quasiquote(inner) => list2(sym("quasiquote"), expand_quote(inner))
    SExpr::Unquote(inner) => list2(sym("unquote"), expand_quote(inner))
    SExpr::UnquoteSplicing(inner) => list2(sym("unquote-splicing"), expand_quote(inner))
    SExpr::Pair(left, right) => SExpr::Pair(expand_quote(left), expand_quote(right))
    SExpr::Vector(items) => {
      let mapped : Array[SExpr] = []
      for item in items {
        mapped.push(expand_quote(item))
      }
      SExpr::Vector(mapped)
    }
    _ => expr
  }
}
