/// entry point.
///
/// The JavaScript backend (Node.js) launches an interactive REPL:
///   moon run src --target js
///
/// The WASM backend runs a sample expression:
///   moon run src
fn main {
  run_vm_interactive()
}
