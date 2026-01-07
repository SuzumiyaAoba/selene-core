/// Lexical environment model (draft).

pub type Binding = (String, Value)

pub(all) struct Env {
  parent : Env?
  frame : Array[Binding]
}

pub fn empty_env() -> Env {
  { parent: None, frame: [] }
}

pub fn extend(parent : Env, bindings : Array[Binding]) -> Env {
  { parent: Some(parent), frame: bindings }
}
