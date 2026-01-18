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

/// 配列からペア（improper list対応）を構築する。
/// 最後の要素が指定された場合、それをcdrとする。
fn list_from_array_with_tail(items : Array[SExpr], tail : SExpr) -> SExpr {
  let mut acc = tail
  let mut i = items.length()
  let _ = while i > 0 {
    i = i - 1
    acc = SExpr::Pair(items[i], acc)
  } else {
    ()
  }
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
          Token::Dot => {
            // improper list: (a b . c)
            i = i + 1
            let (tail_expr, next_i) = parse_expr(tokens, i)
            // RParen を期待
            if next_i < tokens.length() {
              match tokens[next_i] {
                Token::RParen => {
                  return (list_from_array_with_tail(items, tail_expr), next_i + 1)
                }
                _ => panic() // ドットの後の式の後にはRParenが必要
              }
            } else {
              panic() // ドットの後の式の後に何もない
            }
          }
          _ => {
            let (expr, next_i) = parse_expr(tokens, i)
            items.push(expr)
            i = next_i
          }
        }
      } else {
        ()
      }
      panic()
    }
    Token::RParen => panic()
    Token::Dot => panic() // リスト外でのドット
    Token::Boolean(b) => (SExpr::Bool(b), start + 1)
    Token::Identifier(name) => (SExpr::Symbol(name), start + 1)
    Token::Number(value) => (SExpr::Number(value), start + 1)
    Token::String(s) => (SExpr::String(s), start + 1)
    Token::Char(c) => (SExpr::Char(c), start + 1)
    Token::Quote => {
      let (expr, next_i) = parse_expr(tokens, start + 1)
      (SExpr::Quote(expr), next_i)
    }
    Token::Quasiquote => {
      let (expr, next_i) = parse_expr(tokens, start + 1)
      (SExpr::Quasiquote(expr), next_i)
    }
    Token::Unquote => {
      let (expr, next_i) = parse_expr(tokens, start + 1)
      (SExpr::Unquote(expr), next_i)
    }
    Token::UnquoteSplicing => {
      let (expr, next_i) = parse_expr(tokens, start + 1)
      (SExpr::UnquoteSplicing(expr), next_i)
    }
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
