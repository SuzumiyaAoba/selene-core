/// A minimal S-expression parser for lists/identifiers/integers.

/// Construct a linked list (Pair) from an array.
fn list_from_array(items : Array[SExpr]) -> SExpr {
  let mut acc = SExpr::Nil
  let mut i = items.length()
  let _ = while i > 0 {
    i = i - 1
    acc = SExpr::Pair(items[i], acc)
  } else { () }
  acc
}

/// Constructs a pair (compatible with improved list) from an array.
/// If the last element is specified, use it as cdr.
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

/// Reads one expression from the token sequence and returns the next position.
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
            // Looking forward to RParen
            if next_i < tokens.length() {
              match tokens[next_i] {
                Token::RParen => {
                  return (list_from_array_with_tail(items, tail_expr), next_i + 1)
                }
                _ => panic() // Requires RParen after expression after dot
              }
            } else {
              panic() // Nothing after the expression after the dot
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
    Token::Dot => panic() // dot outside list
    Token::Boolean(b) => (SExpr::Bool(b), start + 1)
    Token::Identifier(name) => (SExpr::Symbol(name), start + 1)
    Token::Number(value) => (SExpr::Number(value), start + 1)
    Token::Real(value) => (SExpr::Real(value), start + 1)
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

/// Convert a token sequence to an S-expression sequence.
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

/// Convert input string to S-expression string.
pub fn parse(input : String) -> Array[SExpr] {
  parse_tokens(tokenize(input))
}

/// Parses on the assumption that the entire input is one expression.
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
