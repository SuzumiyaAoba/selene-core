/// Macro environment for compile-time macro expansion

/// Macro environment (compile-time)
pub(all) struct MacroEnv {
  /// Macro definitions (name → SyntaxRules)
  macros : @hashmap.T[String, SyntaxRules]
  /// Parent environment (for let-syntax scope)
  parent : MacroEnv?
  /// Names shadowed by variable definitions (internal define)
  shadowed : @hashmap.T[String, Unit]
}

/// Create a new empty macro environment
pub fn new_macro_env() -> MacroEnv {
  { macros: @hashmap.new(), parent: None, shadowed: @hashmap.new() }
}

/// Extend macro environment with a new scope
pub fn extend_macro_env(parent : MacroEnv) -> MacroEnv {
  { macros: @hashmap.new(), parent: Some(parent), shadowed: @hashmap.new() }
}

/// Define a macro in the environment
pub fn define_macro(env : MacroEnv, name : String, rules : SyntaxRules) -> Unit {
  env.macros.set(name, rules)
}

/// Shadow a macro name (e.g., when an internal define overrides a macro)
pub fn shadow_macro(env : MacroEnv, name : String) -> Unit {
  env.shadowed.set(name, ())
}

/// Lookup a macro by name
pub fn lookup_macro(env : MacroEnv, name : String) -> SyntaxRules? {
  // Check if shadowed in this scope
  match env.shadowed.get(name) {
    Some(_) => None
    None =>
      match env.macros.get(name) {
        Some(rules) => Some(rules)
        None =>
          match env.parent {
            Some(parent) => lookup_macro(parent, name)
            None => None
          }
      }
  }
}

/// Check if a name is defined as a macro
pub fn is_macro(env : MacroEnv, name : String) -> Bool {
  not(lookup_macro(env, name) is None)
}
