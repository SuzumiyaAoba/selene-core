/// 識別子/整数/括弧/コメントに対応した最小レキサ。

/// 空白文字かどうかを判定する。
fn is_whitespace(ch : Char) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

/// 数字文字を 0-9 に変換する（不正なら -1）。
fn digit_value(ch : Char) -> Int {
  match ch {
    '0' => 0
    '1' => 1
    '2' => 2
    '3' => 3
    '4' => 4
    '5' => 5
    '6' => 6
    '7' => 7
    '8' => 8
    '9' => 9
    _ => -1
  }
}

/// 数字かどうかを判定する。
fn is_digit(ch : Char) -> Bool {
  digit_value(ch) >= 0
}

/// 英字かどうかを判定する。
fn is_letter(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

/// 記号文字（識別子に使える記号）かどうかを判定する。
fn is_symbol(ch : Char) -> Bool {
  match ch {
    '!' | '$' | '%' | '&' | '*' | '/' | ':' | '<' | '=' | '>' | '?' | '^' | '_' | '~' | '+' | '-' => true
    _ => false
  }
}

/// 識別子の先頭として許される文字かどうかを判定する。
fn is_ident_initial(ch : Char) -> Bool {
  is_letter(ch) || is_symbol(ch)
}

/// 識別子の2文字目以降として許される文字かどうかを判定する。
fn is_ident_subsequent(ch : Char) -> Bool {
  is_ident_initial(ch) || is_digit(ch)
}

/// 文字列をトークン列へ分割する。
pub fn tokenize(input : String) -> Array[Token] {
  let chars : Array[Char] = input.iter().collect()
  let len = chars.length()
  let tokens : Array[Token] = []
  let mut i = 0
  let _ = while i < len {
    let ch = chars[i]
    if is_whitespace(ch) {
      i = i + 1
      continue
    }
    if ch == ';' {
      i = i + 1
      let _ = while i < len && chars[i] != '\n' {
        i = i + 1
      } else { () }
      continue
    }
    if ch == '(' {
      tokens.push(Token::LParen)
      i = i + 1
      continue
    }
    if ch == ')' {
      tokens.push(Token::RParen)
      i = i + 1
      continue
    }
    if ch == '#' {
      i = i + 1
      if i < len {
        match chars[i] {
          't' | 'T' => {
            tokens.push(Token::Boolean(true))
            i = i + 1
            continue
          }
          'f' | 'F' => {
            tokens.push(Token::Boolean(false))
            i = i + 1
            continue
          }
          '\\' => {
            // 文字リテラル #\x
            i = i + 1
            if i < len {
              let char_value = chars[i]
              // 特殊文字名のチェック
              if is_letter(char_value) {
                let builder = StringBuilder::new()
                let _ = while i < len && is_letter(chars[i]) {
                  builder.write_char(chars[i])
                  i = i + 1
                } else { () }
                let char_name = builder.to_string()
                let result_char = match char_name {
                  "space" => ' '
                  "newline" => '\n'
                  "tab" => '\t'
                  "return" => '\r'
                  _ => {
                    // 単一文字として扱う（最初の文字のみ）
                    let name_chars : Array[Char] = char_name.iter().collect()
                    if name_chars.length() == 1 {
                      name_chars[0]
                    } else {
                      panic()  // 未対応の文字名
                    }
                  }
                }
                tokens.push(Token::Char(result_char))
                continue
              } else {
                tokens.push(Token::Char(char_value))
                i = i + 1
                continue
              }
            } else {
              panic()  // #\ の後に何もない
            }
          }
          _ => panic()  // 未対応の # リテラル
        }
      } else {
        panic()  // # の後に何もない
      }
    }
    if ch == '"' {
      // 文字列リテラル
      i = i + 1
      let builder = StringBuilder::new()
      let _ = while i < len {
        let str_ch = chars[i]
        if str_ch == '"' {
          i = i + 1
          tokens.push(Token::String(builder.to_string()))
          break
        } else if str_ch == '\\' {
          // エスケープシーケンス
          i = i + 1
          if i < len {
            match chars[i] {
              '"' => builder.write_char('"')
              '\\' => builder.write_char('\\')
              'n' => builder.write_char('\n')
              't' => builder.write_char('\t')
              'r' => builder.write_char('\r')
              _ => {
                builder.write_char('\\')
                builder.write_char(chars[i])
              }
            }
            i = i + 1
          } else {
            panic()  // エスケープの後に何もない
          }
        } else {
          builder.write_char(str_ch)
          i = i + 1
        }
      } else { () }
      continue
    }
    if is_digit(ch) {
      let mut value = 0
      let _ = while i < len && is_digit(chars[i]) {
        value = value * 10 + digit_value(chars[i])
        i = i + 1
      } else { () }
      tokens.push(Token::Number(value))
      continue
    }
    if is_ident_initial(ch) {
      let builder = StringBuilder::new()
      let _ = while i < len && is_ident_subsequent(chars[i]) {
        builder.write_char(chars[i])
        i = i + 1
      } else { () }
      tokens.push(Token::Identifier(builder.to_string()))
      continue
    }
    panic()
  } else { () }
  tokens
}
