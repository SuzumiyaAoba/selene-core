/// S 式をスナップショット用の文字列に変換する。
fn sexpr_snapshot(expr : SExpr) -> String {
  match expr {
    SExpr::Nil => "Nil"
    SExpr::Bool(b) => "Bool(" + b.to_string() + ")"
    SExpr::Symbol(name) => "Symbol(" + name + ")"
    SExpr::Number(value) => "Number(" + value.to_string() + ")"
    SExpr::Bool(b) => if b { "Bool(true)" } else { "Bool(false)" }
    SExpr::Pair(left, right) =>
      "Pair(" + sexpr_snapshot(left) + ", " + sexpr_snapshot(right) + ")"
    SExpr::Vector(items) => {
      let builder = StringBuilder::new()
      builder.write_string("Vector([")
      let mut i = 0
      let len = items.length()
      let _ = while i < len {
        if i > 0 {
          builder.write_string(", ")
        }
        builder.write_string(sexpr_snapshot(items[i]))
        i = i + 1
      } else { () }
      builder.write_string("])")
      builder.to_string()
    }
    SExpr::Quote(inner) => "Quote(" + sexpr_snapshot(inner) + ")"
    SExpr::Quasiquote(inner) => "Quasiquote(" + sexpr_snapshot(inner) + ")"
    SExpr::Unquote(inner) => "Unquote(" + sexpr_snapshot(inner) + ")"
    SExpr::UnquoteSplicing(inner) =>
      "UnquoteSplicing(" + sexpr_snapshot(inner) + ")"
  }
}

/// パーサ結果のスナップショットを固定する。
test "parser snapshot" {
  let expr = parse_one("(define x 42)")
  inspect(
    sexpr_snapshot(expr),
    content="Pair(Symbol(define), Pair(Symbol(x), Pair(Number(42), Nil)))",
  )
}
