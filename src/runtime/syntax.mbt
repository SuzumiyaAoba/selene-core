/// Implementing the syntax-rules macro system (runtime wrapper)
/// The core macro expansion logic is in @core/macro.mbt

/// Create SyntaxRules by evaluating syntax-rules expressions
/// (syntax-rules (literals...) (pattern template) ...)
pub fn eval_syntax_rules(args : SExpr, env : Env) -> Result[Value, EvalError] {
  // Get (literals...)
  let (literals_sexpr, rest) = match args {
    SExpr::Pair(lits, r) => (lits, r)
    _ => return Err(EvalError::InvalidSyntax("syntax-rules: expected literals list"))
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
              EvalError::InvalidSyntax("syntax-rules: literals must be identifiers"),
            )
        }
        current = cdr
      }
      _ => return Err(EvalError::InvalidSyntax("syntax-rules: invalid literals list"))
    }
  } else {
    ()
  }

  // extract rules
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
              EvalError::InvalidSyntax(
                "syntax-rules: rule must be (pattern template)",
              ),
            )
        }
        current = cdr
      }
      _ => return Err(EvalError::InvalidSyntax("syntax-rules: invalid rules list"))
    }
  } else {
    ()
  }

  Ok(Value::Syntax({ literals, rules, def_env: env }))
}

/// Expand a macro (runtime wrapper that returns EvalError)
/// This is a wrapper around the core expand_macro function
pub fn expand_macro_eval(
  syntax_rules : SyntaxRules,
  expr : SExpr
) -> Result[SExpr, EvalError] {
  // Call the core expand_macro and convert error type
  match expand_macro(syntax_rules, expr) {
    Ok(result) => Ok(result)
    Err(msg) => Err(EvalError::InvalidSyntax(msg))
  }
}
