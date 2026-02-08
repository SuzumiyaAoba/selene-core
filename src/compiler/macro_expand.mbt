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
            // Body forms: scan for internal defines that shadow macros
            "let" | "let*" | "letrec" | "lambda" =>
              expand_body_form(name, cdr, macro_env)
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

/// Global counter for generating unique hygienic names
let hyg_counter : Ref[Int] = Ref::new(0)

/// Generate a unique hygienic name
fn gensym(prefix : String) -> String {
  hyg_counter.val = hyg_counter.val + 1
  prefix + "__hyg_" + hyg_counter.val.to_string()
}

/// Check if a name is a special form (should not be renamed)
fn is_special_form(name : String) -> Bool {
  match name {
    "if" | "lambda" | "define" | "set!" | "begin" | "and" | "or" | "let"
    | "let*" | "letrec" | "cond" | "case" | "do" | "delay" | "define-syntax"
    | "let-syntax" | "letrec-syntax" | "syntax-rules" | "load" | "quote"
    | "quasiquote" | "unquote" | "unquote-splicing" => true
    _ => false
  }
}

/// Collect free variables from a template (symbols that are not pattern variables,
/// literals, or special forms)
fn collect_template_free_vars(
  template : SExpr,
  pattern_vars : Array[String],
  literals : Array[String],
  free_vars : Array[String]
) -> Unit {
  match template {
    SExpr::Symbol(name) =>
      if not(pattern_vars.contains(name)) && not(literals.contains(name)) && not(
        is_special_form(name),
      ) && name != "_" && name != "..." && not(free_vars.contains(name)) {
        free_vars.push(name)
      }
    SExpr::Pair(car, cdr) => {
      collect_template_free_vars(car, pattern_vars, literals, free_vars)
      collect_template_free_vars(cdr, pattern_vars, literals, free_vars)
    }
    _ => ()
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

      // First pass: parse all bindings and collect free variables
      let all_rules : Array[(String, SyntaxRules)] = []
      let all_free_vars : Array[String] = []
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
                    // Collect free vars from each rule's template
                    for rule in rules.rules {
                      let pattern_vars = collect_pattern_variables(
                        rule.pattern, rules.literals,
                      )
                      collect_template_free_vars(
                        rule.template, pattern_vars, rules.literals,
                        all_free_vars,
                      )
                    }
                    all_rules.push((name, rules))
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

      // Build rename map for hygienic expansion
      let rename_map : Map[String, String] = Map::new()
      for var in all_free_vars {
        rename_map.set(var, gensym(var))
      }

      // Register macros with the rename map
      for pair in all_rules {
        let (name, rules) = pair
        let hygienic_rules : SyntaxRules = {
          literals: rules.literals,
          rules: rules.rules,
          def_env: rules.def_env,
          rename_map,
        }
        define_macro(local_env, name, hygienic_rules)
      }

      // Expand body with the new environment
      let expanded_body = match expand_body(body, local_env) {
        Ok(e) => e
        Err(e) => return Err(e)
      }

      // Wrap in let bindings if there are any renames
      if rename_map.size() == 0 {
        Ok(expanded_body)
      } else {
        // Build (let ((gensym1 orig1) ...) expanded_body)
        let mut let_bindings : SExpr = SExpr::Nil
        rename_map.each(
          fn(orig, gensym_name) {
            let binding = SExpr::Pair(
              SExpr::Symbol(gensym_name),
              SExpr::Pair(SExpr::Symbol(orig), SExpr::Nil),
            )
            let_bindings = SExpr::Pair(binding, let_bindings)
          },
        )
        Ok(
          SExpr::Pair(
            SExpr::Symbol("let"),
            SExpr::Pair(let_bindings, SExpr::Pair(expanded_body, SExpr::Nil)),
          ),
        )
      }
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

/// Expand a body-containing form (let, let*, letrec, lambda).
/// Scans the body for internal defines that shadow macros, and if found,
/// expands with a masked macro environment.
fn expand_body_form(
  form_name : String,
  args : SExpr,
  macro_env : MacroEnv
) -> Result[SExpr, CompileError] {
  let form = SExpr::Pair(SExpr::Symbol(form_name), args)
  // Extract body from the form
  let body = extract_form_body(form_name, args)
  match body {
    Some(b) => {
      let define_names = collect_body_define_names(b)
      let mut has_shadow = false
      for name in define_names {
        if is_macro(macro_env, name) {
          has_shadow = true
          break
        }
      }
      if has_shadow {
        let masked_env = extend_macro_env(macro_env)
        for name in define_names {
          if is_macro(macro_env, name) {
            shadow_macro(masked_env, name)
          }
        }
        expand_list(form, masked_env)
      } else {
        expand_list(form, macro_env)
      }
    }
    None => expand_list(form, macro_env)
  }
}

/// Extract the body portion from a body-containing form.
/// Returns the body as an SExpr list (Pair chain), or None if structure is invalid.
fn extract_form_body(form_name : String, args : SExpr) -> SExpr? {
  match form_name {
    "let" =>
      match args {
        SExpr::Pair(first, rest) =>
          match first {
            // Named let: (let name ((bindings) ...) body ...)
            SExpr::Symbol(_) =>
              match rest {
                SExpr::Pair(_, body) => Some(body)
                _ => None
              }
            // Regular let: (let ((bindings) ...) body ...)
            _ => Some(rest)
          }
        _ => None
      }
    "let*" | "letrec" =>
      match args {
        SExpr::Pair(_, body) => Some(body)
        _ => None
      }
    "lambda" =>
      match args {
        SExpr::Pair(_, body) => Some(body)
        _ => None
      }
    _ => None
  }
}

/// Collect names defined by internal defines at the beginning of a body.
/// Handles (define name ...), (define (name ...) ...), and spliced (begin ...) forms.
fn collect_body_define_names(body : SExpr) -> Array[String] {
  let names : Array[String] = []
  collect_body_define_names_inner(body, names)
  names
}

fn collect_body_define_names_inner(body : SExpr, names : Array[String]) -> Unit {
  match body {
    SExpr::Pair(first, rest) =>
      match first {
        // (define name ...)
        SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Symbol(name), _)) => {
          if not(names.contains(name)) {
            names.push(name)
          }
          collect_body_define_names_inner(rest, names)
        }
        // (define (name ...) ...)
        SExpr::Pair(
          SExpr::Symbol("define"),
          SExpr::Pair(SExpr::Pair(SExpr::Symbol(name), _), _)
        ) => {
          if not(names.contains(name)) {
            names.push(name)
          }
          collect_body_define_names_inner(rest, names)
        }
        // (begin ...) — splice and scan contents
        SExpr::Pair(SExpr::Symbol("begin"), begin_body) => {
          collect_body_define_names_inner(begin_body, names)
          collect_body_define_names_inner(rest, names)
        }
        // Non-define form: stop scanning (R5RS: defines must precede expressions)
        _ => ()
      }
    _ => ()
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

      // Create SyntaxRules with empty def_env and rename_map
      // rename_map will be populated by expand_let_syntax for hygiene
      Ok({ literals, rules, def_env: empty_env(), rename_map: Map::new() })
    }
    _ =>
      Err(
        CompileError::InvalidSyntax(
          "Expected (syntax-rules (literals...) (pattern template) ...)",
        ),
      )
  }
}
