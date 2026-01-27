/// エントリーポイント。
///
/// JavaScript バックエンド（Node.js）では対話的 REPL を起動します：
///   moon run src --target js
///
/// WASM バックエンドではサンプル式を実行します：
///   moon run src
fn main {
  run_vm_interactive()
}
