/// wasm-gc バックエンド用のスタブ実装
/// 標準入力の読み取りは wasm-gc では利用できません

/// 標準入力から一行読み取る（スタブ実装）
/// wasm-gc バックエンドでは常に空文字列を返します
pub fn read_line() -> String {
  ""  // wasm-gc では stdin 読み取りは利用不可
}
