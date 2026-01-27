/// wasm-gc バックエンド用のスタブ実装
/// 標準入力の読み取りは wasm-gc では利用できません

/// 標準入力から一行読み取る（プロンプト付き、スタブ実装）
/// wasm-gc バックエンドでは常に空文字列を返します
pub fn read_line_with_prompt(_prompt : String) -> String {
  ""  // wasm-gc では stdin 読み取りは利用不可
}

/// 標準入力から一行読み取る（スタブ実装）
/// wasm-gc バックエンドでは常に空文字列を返します
pub fn read_line() -> String {
  ""  // wasm-gc では stdin 読み取りは利用不可
}

// =============================================================================
// ポート操作スタブ（wasm-gc では利用不可）
// =============================================================================

/// ファイルを入力用に開く（常に失敗）
pub fn open_input_file(_filename : String, _port_id : Int) -> Int {
  -1  // wasm-gc ではファイル操作は利用不可
}

/// ファイルを出力用に開く（常に失敗）
pub fn open_output_file(_filename : String, _port_id : Int) -> Int {
  -1  // wasm-gc ではファイル操作は利用不可
}

/// ポートを閉じる（常に失敗）
pub fn close_port(_port_id : Int) -> Bool {
  false  // wasm-gc ではファイル操作は利用不可
}

/// ポートから1文字読み取る（常にEOF）
pub fn read_char_from_port(_port_id : Int) -> Int {
  -1  // wasm-gc ではファイル操作は利用不可
}

/// ポートから1文字先読み（常にEOF）
pub fn peek_char_from_port(_port_id : Int) -> Int {
  -1  // wasm-gc ではファイル操作は利用不可
}

/// ポートに1文字書き込む（常に失敗）
pub fn write_char_to_port(_port_id : Int, _char_code : Int) -> Bool {
  false  // wasm-gc ではファイル操作は利用不可
}

/// ポートに文字列を書き込む（常に失敗）
pub fn write_string_to_port(_port_id : Int, _str : String) -> Bool {
  false  // wasm-gc ではファイル操作は利用不可
}

/// ポートがEOFに達したかどうか（常にtrue）
pub fn is_eof(_port_id : Int) -> Bool {
  true  // wasm-gc ではファイル操作は利用不可
}

/// ファイル全体を読み込む（常に空文字列）
pub fn read_file(_filename : String) -> String {
  ""  // wasm-gc ではファイル操作は利用不可
}

/// ファイルが存在するかどうか（常にfalse）
pub fn file_exists(_filename : String) -> Bool {
  false  // wasm-gc ではファイル操作は利用不可
}
