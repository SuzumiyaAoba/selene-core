/// A minimal lexer that supports identifiers/integers/parentheses/comments.

/// Determine whether it is a blank character.
fn is_whitespace(ch : Char) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

/// Convert numeric characters to 0-9 (-1 if invalid).
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

/// Determine whether it is a number.
fn is_digit(ch : Char) -> Bool {
  digit_value(ch) >= 0
}

/// Determine whether it is an alphabetic character.
fn is_letter(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

/// Determine whether it is a symbol character (a symbol that can be used as an identifier).
fn is_symbol(ch : Char) -> Bool {
  match ch {
    '!' | '$' | '%' | '&' | '*' | '/' | ':' | '<' | '=' | '>' | '?' | '^' | '_' | '~' | '+' | '-' => true
    _ => false
  }
}

/// Determines whether the character is allowed as the first character of an identifier.
fn is_ident_initial(ch : Char) -> Bool {
  is_letter(ch) || is_symbol(ch)
}

/// Determine whether the second character and subsequent characters in the identifier are allowed.
fn is_ident_subsequent(ch : Char) -> Bool {
  is_ident_initial(ch) || is_digit(ch)
}

/// Split a string into a string of tokens.
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
    // Quote token
    if ch == '\'' {
      tokens.push(Token::Quote)
      i = i + 1
      continue
    }
    if ch == '`' {
      tokens.push(Token::Quasiquote)
      i = i + 1
      continue
    }
    if ch == ',' {
      i = i + 1
      if i < len && chars[i] == '@' {
        tokens.push(Token::UnquoteSplicing)
        i = i + 1
      } else {
        tokens.push(Token::Unquote)
      }
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
            // character literal #\x
            i = i + 1
            if i < len {
              let char_value = chars[i]
              // Check for special character names
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
                    // Treat as a single character (first character only)
                    let name_chars : Array[Char] = char_name.iter().collect()
                    if name_chars.length() == 1 {
                      name_chars[0]
                    } else {
                      panic()  // Unsupported character name
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
              panic()  // Nothing after #\
            }
          }
          _ => panic()  // Unsupported # literal
        }
      } else {
        panic()  // nothing after #
      }
    }
    if ch == '"' {
      // string literal
      i = i + 1
      let builder = StringBuilder::new()
      let _ = while i < len {
        let str_ch = chars[i]
        if str_ch == '"' {
          i = i + 1
          tokens.push(Token::String(builder.to_string()))
          break
        } else if str_ch == '\\' {
          // escape sequence
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
            panic()  // nothing after escape
          }
        } else {
          builder.write_char(str_ch)
          i = i + 1
        }
      } else { () }
      continue
    }
    // Dot handling (improper list or ellipsis)
    if ch == '.' {
      // ...(ellipsis) check
      if i + 2 < len && chars[i + 1] == '.' && chars[i + 2] == '.' {
        tokens.push(Token::Identifier("..."))
        i = i + 3
        continue
      } else {
        // single dot (improper list)
        tokens.push(Token::Dot)
        i = i + 1
        continue
      }
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
