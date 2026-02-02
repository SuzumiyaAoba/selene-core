/// Macro expansion functions (pure SExpr → SExpr transformation)
/// These functions don't depend on runtime and can be used by both compiler and runtime.

/// Value matched by pattern variable
pub(all) enum PatternValue {
  /// single value
  Single(SExpr)
  /// repeat (match with ellipsis)
  Repeated(Array[Map[String, PatternValue]])
}

/// Expand the macro
/// If the expression is a macro call, return the expanded expression
pub fn expand_macro(
  syntax_rules : SyntaxRules,
  expr : SExpr
) -> Result[SExpr, String] {
  // Try each rule in turn
  for rule in syntax_rules.rules {
    match match_pattern(rule.pattern, expr, syntax_rules.literals) {
      Some(bindings) => {
        // Match successful, deploy template
        return expand_template(rule.template, bindings)
      }
      None => continue
    }
  }
  Err("syntax-rules: no matching pattern")
}

/// perform pattern matching
/// Returns the binding on success, None on failure.
fn match_pattern(
  pattern : SExpr,
  expr : SExpr,
  literals : Array[String]
) -> Map[String, PatternValue]? {
  let bindings : Map[String, PatternValue] = Map::new()
  if match_pattern_inner(pattern, expr, literals, bindings) {
    Some(bindings)
  } else {
    None
  }
}

/// Internal implementation of pattern matching
fn match_pattern_inner(
  pattern : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  match pattern {
    // Wildcard (_) matches anything
    SExpr::Symbol("_") => true
    // Literal keywords require exact match
    SExpr::Symbol(name) =>
      if is_literal(name, literals) {
        match expr {
          SExpr::Symbol(expr_name) => name == expr_name
          _ => false
        }
      } else {
        // Pattern variable: match and bind any expression
        bindings.set(name, PatternValue::Single(expr))
        true
      }
    // numeric literal
    SExpr::Number(n) =>
      match expr {
        SExpr::Number(m) => n == m
        _ => false
      }
    // boolean literal
    SExpr::Bool(b) =>
      match expr {
        SExpr::Bool(c) => b == c
        _ => false
      }
    // character literal
    SExpr::Char(c) =>
      match expr {
        SExpr::Char(d) => c == d
        _ => false
      }
    // string literal
    SExpr::String(s) =>
      match expr {
        SExpr::String(t) => s == t
        _ => false
      }
    // empty list
    SExpr::Nil =>
      match expr {
        SExpr::Nil => true
        _ => false
      }
    // List pattern (ellipsis compatible)
    SExpr::Pair(pcar, pcdr) => match_list_pattern(pcar, pcdr, expr, literals, bindings)
    // others
    _ => false
  }
}

/// List pattern matching (ellipsis supported)
fn match_list_pattern(
  pcar : SExpr,
  pcdr : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  // Does not match unless expr is a list
  match expr {
    SExpr::Pair(ecar, ecdr) => {
      // Check if pcdr is of the form (... ...)
      match pcdr {
        SExpr::Pair(SExpr::Symbol("..."), rest) => {
          // ellipsis pattern: matches pcar 0 or more times
          match_ellipsis_pattern(pcar, rest, expr, literals, bindings)
        }
        _ => {
          // normal list match
          if match_pattern_inner(pcar, ecar, literals, bindings) {
            match_pattern_inner(pcdr, ecdr, literals, bindings)
          } else {
            false
          }
        }
      }
    }
    SExpr::Nil =>
      // If the expression is an empty list
      match pcdr {
        SExpr::Pair(SExpr::Symbol("..."), rest) => {
          // For ellipsis, treat as 0 matches
          // Bind pcar pattern variables as empty repeats
          let pattern_vars = collect_pattern_variables(pcar, literals)
          for name in pattern_vars {
            bindings.set(name, PatternValue::Repeated([]))
          }
          // match the rest of the pattern
          match_pattern_inner(rest, SExpr::Nil, literals, bindings)
        }
        _ => false
      }
    _ => false
  }
}

/// ellipsis pattern matching
fn match_ellipsis_pattern(
  elem_pattern : SExpr,
  rest_pattern : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  // Collect pattern variables
  let pattern_vars = collect_pattern_variables(elem_pattern, literals)

  // Store repeat bindings
  let repeated : Array[Map[String, PatternValue]] = []

  // Match elements by scanning an expression
  let mut current = expr
  let _ = while true {
    match current {
      SExpr::Pair(ecar, ecdr) => {
        // If rest_pattern is not empty, it must be matched from behind
        // For simplicity, first try to match greedily.
        let elem_bindings : Map[String, PatternValue] = Map::new()
        if match_pattern_inner(elem_pattern, ecar, literals, elem_bindings) {
          repeated.push(elem_bindings)
          current = ecdr
        } else {
          break
        }
      }
      SExpr::Nil => break
      _ => break
    }
  } else {
    ()
  }

  // Put together repeating bindings
  for name in pattern_vars {
    bindings.set(name, PatternValue::Repeated(repeated))
  }

  // match the rest of the pattern
  match_pattern_inner(rest_pattern, current, literals, bindings)
}

/// Collect pattern variables within a pattern
fn collect_pattern_variables(pattern : SExpr, literals : Array[String]) -> Array[String] {
  let vars : Array[String] = []
  collect_pattern_variables_inner(pattern, literals, vars)
  vars
}

fn collect_pattern_variables_inner(
  pattern : SExpr,
  literals : Array[String],
  vars : Array[String]
) -> Unit {
  match pattern {
    SExpr::Symbol("_") => () // Ignore wildcards
    SExpr::Symbol("...") => () // ellipsis is ignored
    SExpr::Symbol(name) =>
      if not(is_literal(name, literals)) {
        // Add if not already added
        if not(vars.contains(name)) {
          vars.push(name)
        }
      }
    SExpr::Pair(car, cdr) => {
      collect_pattern_variables_inner(car, literals, vars)
      collect_pattern_variables_inner(cdr, literals, vars)
    }
    _ => ()
  }
}

/// Whether the identifier is a literal keyword
fn is_literal(name : String, literals : Array[String]) -> Bool {
  literals.contains(name)
}

/// Expand template
fn expand_template(
  template : SExpr,
  bindings : Map[String, PatternValue]
) -> Result[SExpr, String] {
  expand_template_inner(template, bindings, 0)
}

/// Internal implementation of template deployment
fn expand_template_inner(
  template : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[SExpr, String] {
  match template {
    // Replace if symbol is a pattern variable
    SExpr::Symbol(name) =>
      match bindings.get(name) {
        Some(PatternValue::Single(value)) => Ok(value)
        Some(PatternValue::Repeated(_)) =>
          if depth > 0 {
            // Use current index value within repeat context
            // This is handled by expand_repeated
            Ok(template)
          } else {
            Err("syntax-rules: repeated pattern variable outside of ellipsis")
          }
        None =>
          // Symbols that are not pattern variables remain as is.
          Ok(template)
      }
    // For lists, handle ellipsis
    SExpr::Pair(car, cdr) => expand_list_template(car, cdr, bindings, depth)
    // Others remain the same
    _ => Ok(template)
  }
}

/// Expand list template (ellipsis compatible)
fn expand_list_template(
  car : SExpr,
  cdr : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[SExpr, String] {
  // Check if cdr is in format (... ...)
  match cdr {
    SExpr::Pair(SExpr::Symbol("..."), rest) => {
      // ellipsis expansion
      let expanded_elements = match expand_repeated(car, bindings, depth + 1) {
        Ok(elems) => elems
        Err(e) => return Err(e)
      }
      // Expand remaining templates
      let expanded_rest = match expand_template_inner(rest, bindings, depth) {
        Ok(r) => r
        Err(e) => return Err(e)
      }
      // Combine expanded elements into list
      let mut result = expanded_rest
      let mut i = expanded_elements.length() - 1
      let _ = while i >= 0 {
        result = SExpr::Pair(expanded_elements[i], result)
        i = i - 1
      } else {
        ()
      }
      Ok(result)
    }
    _ => {
      // Normal list expansion
      let expanded_car = match expand_template_inner(car, bindings, depth) {
        Ok(c) => c
        Err(e) => return Err(e)
      }
      let expanded_cdr = match expand_template_inner(cdr, bindings, depth) {
        Ok(c) => c
        Err(e) => return Err(e)
      }
      Ok(SExpr::Pair(expanded_car, expanded_cdr))
    }
  }
}

/// Expand repeating template
fn expand_repeated(
  template : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[Array[SExpr], String] {
  // Find repeating pattern variables in templates
  let repeated_vars = find_repeated_variables(template, bindings)
  if repeated_vars.is_empty() {
    return Err("syntax-rules: no repeated variables in ellipsis template")
  }

  // Determine the number of iterations (using the length of the first iteration variable)
  let first_var = repeated_vars[0]
  let count = match bindings.get(first_var) {
    Some(PatternValue::Repeated(values)) => values.length()
    _ => return Err("syntax-rules: expected repeated binding")
  }

  // Expand at each iteration
  let results : Array[SExpr] = []
  let mut i = 0
  let _ = while i < count {
    // Create a binding for this iteration
    let iter_bindings : Map[String, PatternValue] = Map::new()

    // Process existing bindings
    bindings.each(
      fn(name, value) {
        match value {
          PatternValue::Single(v) => iter_bindings.set(name, PatternValue::Single(v))
          PatternValue::Repeated(values) =>
            if i < values.length() {
              // Merge bindings for this iteration
              let iter_bind = values[i]
              iter_bind.each(
                fn(inner_name, inner_value) {
                  iter_bindings.set(inner_name, inner_value)
                },
              )
            }
        }
      },
    )

    let expanded = match expand_template_inner(template, iter_bindings, depth) {
      Ok(e) => e
      Err(e) => return Err(e)
    }
    results.push(expanded)
    i = i + 1
  } else {
    ()
  }

  Ok(results)
}

/// Find repeating pattern variables in templates
fn find_repeated_variables(
  template : SExpr,
  bindings : Map[String, PatternValue]
) -> Array[String] {
  let vars : Array[String] = []
  find_repeated_variables_inner(template, bindings, vars)
  vars
}

fn find_repeated_variables_inner(
  template : SExpr,
  bindings : Map[String, PatternValue],
  vars : Array[String]
) -> Unit {
  match template {
    SExpr::Symbol(name) =>
      match bindings.get(name) {
        Some(PatternValue::Repeated(_)) =>
          if not(vars.contains(name)) {
            vars.push(name)
          }
        _ => ()
      }
    SExpr::Pair(car, cdr) => {
      // Skip after ellipsis
      match cdr {
        SExpr::Pair(SExpr::Symbol("..."), _) => ()
        _ => {
          find_repeated_variables_inner(car, bindings, vars)
          find_repeated_variables_inner(cdr, bindings, vars)
        }
      }
    }
    _ => ()
  }
}
