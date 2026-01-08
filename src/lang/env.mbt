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

fn clone_frame(frame : Array[Binding]) -> Array[Binding] {
  let copied : Array[Binding] = []
  for item in frame {
    copied.push(item)
  }
  copied
}

fn find_in_frame(frame : Array[Binding], name : String) -> Int? {
  let mut i = 0
  let len = frame.length()
  let _ = while i < len {
    let (key, _) = frame[i]
    if key == name {
      return Some(i)
    }
    i = i + 1
  } else { () }
  None
}

pub fn lookup(env : Env, name : String) -> Value? {
  match find_in_frame(env.frame, name) {
    Some(idx) => {
      let (_, value) = env.frame[idx]
      Some(value)
    }
    None => match env.parent {
      Some(parent) => lookup(parent, name)
      None => None
    }
  }
}

pub fn define(env : Env, name : String, value : Value) -> Env {
  let new_frame = clone_frame(env.frame)
  match find_in_frame(new_frame, name) {
    Some(idx) => {
      new_frame[idx] = (name, value)
      { parent: env.parent, frame: new_frame }
    }
    None => {
      new_frame.push((name, value))
      { parent: env.parent, frame: new_frame }
    }
  }
}

pub fn set_bang(env : Env, name : String, value : Value) -> (Env, Bool) {
  match find_in_frame(env.frame, name) {
    Some(idx) => {
      let new_frame = clone_frame(env.frame)
      new_frame[idx] = (name, value)
      ({ parent: env.parent, frame: new_frame }, true)
    }
    None => match env.parent {
      Some(parent) => {
        let (new_parent, ok) = set_bang(parent, name, value)
        if ok {
          ({ parent: Some(new_parent), frame: clone_frame(env.frame) }, true)
        } else {
          (env, false)
        }
      }
      None => (env, false)
    }
  }
}
