/// Macro expansion for bytecode compiler
///
/// This module expands macros before compilation, transforming
/// macro calls into their expanded forms.

/// Result of expanding a top-level expression
pub(all) struct ExpandResult {
  /// The expanded expression (or Void for pure define-syntax)
  expr : SExpr?
  /// Whether the macro environment was updated
  env_updated : Bool
}

/// Expand a top-level expression
/// Handles define-syntax and returns the expanded expression
pub fn expand_toplevel(
  expr : SExpr,
  macro_env : MacroEnv
) -> Result[ExpandResult, CompileError] {
  // Check if it's a define-syntax
  match expr {
    SExpr::Pair(SExpr::Symbol("define-syntax"), rest) => {
      // (define-syntax name (syntax-rules ...))
      match rest {
        SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(syntax_rules_expr, SExpr::Nil)) => {
          match parse_syntax_rules(syntax_rules_expr) {
            Ok(rules) => {
              define_macro(macro_env, name, rules)
              Ok({ expr: None, env_updated: true })
            }
            Err(e) => Err(e)
          }
        }
        _ =>
          Err(
            CompileError::InvalidSyntax(
              "define-syntax: expected (define-syntax name (syntax-rules ...))",
            ),
          )
      }
    }
    _ => {
      // Not a define-syntax, expand the expression
      match expand_expr(expr, macro_env) {
        Ok(expanded) => Ok({ expr: Some(expanded), env_updated: false })
        Err(e) => Err(e)
      }
    }
  }
}

/// Recursively expand all macros in an expression
pub fn expand_expr(expr : SExpr, macro_env : MacroEnv) -> Result[SExpr, CompileError] {
  match expr {
    // Atomic values: return as-is
    SExpr::Number(_)
    | SExpr::Bool(_)
    | SExpr::String(_)
    | SExpr::Char(_)
    | SExpr::Symbol(_)
    | SExpr::Nil => Ok(expr)
    // Quote forms: don't expand inside
    SExpr::Quote(_) => Ok(expr)
    SExpr::Quasiquote(_) => Ok(expr) // TODO: handle unquote inside
    SExpr::Unquote(_) => Ok(expr)
    SExpr::UnquoteSplicing(_) => Ok(expr)
    // Vector: expand each element
    SExpr::Vector(elements) => {
      let expanded_elements : Array[SExpr] = []
      for elem in elements {
        match expand_expr(elem, macro_env) {
          Ok(expanded) => expanded_elements.push(expanded)
          Err(e) => return Err(e)
        }
      }
      Ok(SExpr::Vector(expanded_elements))
    }
    // List: check for special forms and macro calls
    SExpr::Pair(car, cdr) =>
      match car {
        SExpr::Symbol(name) => {
          // Check if it's a special form that shouldn't be expanded in certain ways
          match name {
            "quote" => Ok(expr) // Don't expand inside quote
            "quasiquote" => Ok(expr) // Don't expand inside quasiquote (for now)
            "let-syntax" => expand_let_syntax(cdr, macro_env, false)
            "letrec-syntax" => expand_let_syntax(cdr, macro_env, true)
            _ =>
              // Check if it's a macro call
              match lookup_macro(macro_env, name) {
                Some(rules) => {
                  // Expand the macro
                  match expand_macro(rules, expr) {
                    Ok(expanded) =>
                      // Recursively expand the result
                      expand_expr(expanded, macro_env)
                    Err(e) => Err(CompileError::MacroError(e))
                  }
                }
                None =>
                  // Not a macro, expand children
                  expand_list(expr, macro_env)
              }
          }
        }
        _ =>
          // First element is not a symbol, expand all children
          expand_list(expr, macro_env)
      }
  }
}

/// Expand all elements of a list
fn expand_list(expr : SExpr, macro_env : MacroEnv) -> Result[SExpr, CompileError] {
  match expr {
    SExpr::Nil => Ok(SExpr::Nil)
    SExpr::Pair(car, cdr) => {
      match expand_expr(car, macro_env) {
        Ok(expanded_car) =>
          match expand_list(cdr, macro_env) {
            Ok(expanded_cdr) => Ok(SExpr::Pair(expanded_car, expanded_cdr))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }
    _ =>
      // Improper list tail
      expand_expr(expr, macro_env)
  }
}

/// Expand let-syntax or letrec-syntax
/// (let-syntax ((name (syntax-rules ...)) ...) body ...)
fn expand_let_syntax(
  args : SExpr,
  parent_env : MacroEnv,
  recursive : Bool
) -> Result[SExpr, CompileError] {
  let _ = recursive // unused for now
  match args {
    SExpr::Pair(bindings, body) => {
      // Create new macro environment
      let local_env = extend_macro_env(parent_env)

      // Parse and register bindings
      let mut current = bindings
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(binding, rest) => {
            match binding {
              SExpr::Pair(
                SExpr::Symbol(name),
                SExpr::Pair(syntax_rules_expr, SExpr::Nil)
              ) => {
                match parse_syntax_rules(syntax_rules_expr) {
                  Ok(rules) => {
                    define_macro(local_env, name, rules)
                    current = rest
                  }
                  Err(e) => return Err(e)
                }
              }
              _ =>
                return Err(
                  CompileError::InvalidSyntax(
                    "let-syntax: binding must be (name (syntax-rules ...))",
                  ),
                )
            }
          }
          _ =>
            return Err(
              CompileError::InvalidSyntax("let-syntax: bindings must be a list"),
            )
        }
      } else {
        ()
      }

      // Expand body with the new environment
      expand_body(body, local_env)
    }
    _ =>
      Err(
        CompileError::InvalidSyntax(
          "let-syntax: expected (let-syntax ((name transformer) ...) body ...)",
        ),
      )
  }
}

/// Expand body (sequence of expressions) and wrap in begin if multiple
fn expand_body(body : SExpr, macro_env : MacroEnv) -> Result[SExpr, CompileError] {
  match body {
    SExpr::Nil =>
      Err(CompileError::InvalidSyntax("let-syntax: body cannot be empty"))
    SExpr::Pair(first, SExpr::Nil) =>
      // Single expression
      expand_expr(first, macro_env)
    SExpr::Pair(_, _) => {
      // Multiple expressions - expand each and wrap in begin
      match expand_list(body, macro_env) {
        Ok(expanded) => Ok(SExpr::Pair(SExpr::Symbol("begin"), expanded))
        Err(e) => Err(e)
      }
    }
    _ => Err(CompileError::InvalidSyntax("let-syntax: invalid body"))
  }
}

/// Parse syntax-rules expression at compile time
/// (syntax-rules (literals...) (pattern template) ...)
pub fn parse_syntax_rules(expr : SExpr) -> Result[SyntaxRules, CompileError] {
  match expr {
    SExpr::Pair(SExpr::Symbol("syntax-rules"), args) => {
      // Get (literals...)
      let (literals_sexpr, rest) = match args {
        SExpr::Pair(lits, r) => (lits, r)
        _ =>
          return Err(
            CompileError::InvalidSyntax("syntax-rules: expected literals list"),
          )
      }

      // Extract literal keywords
      let literals : Array[String] = []
      let mut current = literals_sexpr
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(car, cdr) => {
            match car {
              SExpr::Symbol(name) => literals.push(name)
              _ =>
                return Err(
                  CompileError::InvalidSyntax(
                    "syntax-rules: literals must be identifiers",
                  ),
                )
            }
            current = cdr
          }
          _ =>
            return Err(
              CompileError::InvalidSyntax("syntax-rules: invalid literals list"),
            )
        }
      } else {
        ()
      }

      // Extract rules
      let rules : Array[SyntaxRule] = []
      current = rest
      let _ = while true {
        match current {
          SExpr::Nil => break
          SExpr::Pair(rule_sexpr, cdr) => {
            // Each rule is of the form (pattern template)
            match rule_sexpr {
              SExpr::Pair(pattern, SExpr::Pair(template, SExpr::Nil)) =>
                rules.push({ pattern, template })
              _ =>
                return Err(
                  CompileError::InvalidSyntax(
                    "syntax-rules: rule must be (pattern template)",
                  ),
                )
            }
            current = cdr
          }
          _ =>
            return Err(
              CompileError::InvalidSyntax("syntax-rules: invalid rules list"),
            )
        }
      } else {
        ()
      }

      // Create SyntaxRules with empty def_env
      // Note: Full hygienic macros would need proper environment handling
      Ok({ literals, rules, def_env: empty_env() })
    }
    _ =>
      Err(
        CompileError::InvalidSyntax(
          "Expected (syntax-rules (literals...) (pattern template) ...)",
        ),
      )
  }
}
