/// リスト/識別子/整数に対応した最小 S 式パーサ。

/// 配列から連結リスト（Pair）を構築する。
fn list_from_array(items : Array[SExpr]) -> SExpr {
  let mut acc = SExpr::Nil
  let mut i = items.length()
  let _ = while i > 0 {
    i = i - 1
    acc = SExpr::Pair(items[i], acc)
  } else { () }
  acc
}

/// トークン列から 1 式を読み、次の位置を返す。
fn parse_expr(tokens : Array[Token], start : Int) -> (SExpr, Int) {
  if start >= tokens.length() {
    panic()
  }
  match tokens[start] {
    Token::LParen => {
      let items : Array[SExpr] = []
      let mut i = start + 1
      let _ = while i < tokens.length() {
        match tokens[i] {
          Token::RParen => {
            return (list_from_array(items), i + 1)
          }
          _ => {
            let (expr, next_i) = parse_expr(tokens, i)
            items.push(expr)
            i = next_i
          }
        }
      } else { () }
      panic()
    }
    Token::RParen => panic()
    Token::Boolean(b) => (SExpr::Bool(b), start + 1)
    Token::Identifier(name) => (SExpr::Symbol(name), start + 1)
    Token::Number(value) => (SExpr::Number(value), start + 1)
    Token::Boolean(b) => (SExpr::Bool(b), start + 1)
  }
}

/// トークン列を S 式列へ変換する。
pub fn parse_tokens(tokens : Array[Token]) -> Array[SExpr] {
  let exprs : Array[SExpr] = []
  let mut i = 0
  let len = tokens.length()
  let _ = while i < len {
    let (expr, next_i) = parse_expr(tokens, i)
    exprs.push(expr)
    i = next_i
  } else { () }
  exprs
}

/// 入力文字列を S 式列へ変換する。
pub fn parse(input : String) -> Array[SExpr] {
  parse_tokens(tokenize(input))
}

/// 入力全体が 1 式であることを前提にパースする。
pub fn parse_one(input : String) -> SExpr {
  let tokens = tokenize(input)
  if tokens.length() == 0 {
    panic()
  }
  let (expr, next_i) = parse_expr(tokens, 0)
  if next_i != tokens.length() {
    panic()
  }
  expr
}
