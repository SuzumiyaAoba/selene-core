/// JavaScript FFI for Node.js
/// このファイルは JS バックエンド専用です

/// 標準入力から一行読み取る（同期版）
/// Node.js の fs.readSync を使用して標準入力（fd=0）から読み取る
extern "js" fn read_line_sync_ffi() -> String =
  #|() => {
  #|  const fs = require('fs');
  #|  let buffer = Buffer.alloc(1);
  #|  let bytesRead = 0;
  #|  let result = '';
  #|
  #|  // 標準入力から改行まで1バイトずつ読み取る
  #|  while (true) {
  #|    try {
  #|      bytesRead = fs.readSync(0, buffer, 0, 1);
  #|      if (bytesRead === 0) break;
  #|      const char = buffer.toString('utf8', 0, bytesRead);
  #|      if (char === '\n') break;
  #|      result += char;
  #|    } catch (e) {
  #|      // EOFやエラーの場合は終了
  #|      break;
  #|    }
  #|  }
  #|
  #|  return result;
  #|}

/// 標準入力から一行読み取る
/// JS バックエンドでのみ動作します
pub fn read_line() -> String {
  read_line_sync_ffi()
}

// =============================================================================
// ポート操作 FFI
// =============================================================================

/// ポートストア（ポートID -> ファイルディスクリプタ）
/// グローバルな Map として管理
extern "js" fn port_store_init_ffi() -> Unit =
  #|() => {
  #|  if (!globalThis.__selene_ports) {
  #|    globalThis.__selene_ports = new Map();
  #|  }
  #|}

/// ファイルを入力用に開く（ポートIDを返す、失敗時は-1）
extern "js" fn open_input_file_ffi(filename : String, port_id : Int) -> Int =
  #|(filename, port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) {
  #|    globalThis.__selene_ports = new Map();
  #|  }
  #|  try {
  #|    const fd = fs.openSync(filename, 'r');
  #|    globalThis.__selene_ports.set(port_id, { fd: fd, type: 'input', buffer: '', eof: false });
  #|    return port_id;
  #|  } catch (e) {
  #|    return -1;
  #|  }
  #|}

/// ファイルを出力用に開く（ポートIDを返す、失敗時は-1）
extern "js" fn open_output_file_ffi(filename : String, port_id : Int) -> Int =
  #|(filename, port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) {
  #|    globalThis.__selene_ports = new Map();
  #|  }
  #|  try {
  #|    const fd = fs.openSync(filename, 'w');
  #|    globalThis.__selene_ports.set(port_id, { fd: fd, type: 'output' });
  #|    return port_id;
  #|  } catch (e) {
  #|    return -1;
  #|  }
  #|}

/// ポートを閉じる（成功時true）
extern "js" fn close_port_ffi(port_id : Int) -> Bool =
  #|(port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return false;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port) return false;
  #|  try {
  #|    fs.closeSync(port.fd);
  #|    globalThis.__selene_ports.delete(port_id);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

/// ポートから1文字読み取る（EOFの場合は-1）
extern "js" fn read_char_ffi(port_id : Int) -> Int =
  #|(port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return -1;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port || port.type !== 'input') return -1;
  #|  if (port.eof) return -1;
  #|  try {
  #|    const buffer = Buffer.alloc(1);
  #|    const bytesRead = fs.readSync(port.fd, buffer, 0, 1);
  #|    if (bytesRead === 0) {
  #|      port.eof = true;
  #|      return -1;
  #|    }
  #|    return buffer[0];
  #|  } catch (e) {
  #|    port.eof = true;
  #|    return -1;
  #|  }
  #|}

/// ポートから1文字先読み（消費しない、EOFの場合は-1）
extern "js" fn peek_char_ffi(port_id : Int) -> Int =
  #|(port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return -1;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port || port.type !== 'input') return -1;
  #|  if (port.eof) return -1;
  #|
  #|  // バッファに文字があればそれを返す
  #|  if (port.peeked !== undefined) {
  #|    return port.peeked;
  #|  }
  #|
  #|  try {
  #|    const buffer = Buffer.alloc(1);
  #|    const bytesRead = fs.readSync(port.fd, buffer, 0, 1);
  #|    if (bytesRead === 0) {
  #|      port.eof = true;
  #|      return -1;
  #|    }
  #|    // 先読みした文字を保存
  #|    port.peeked = buffer[0];
  #|    return buffer[0];
  #|  } catch (e) {
  #|    port.eof = true;
  #|    return -1;
  #|  }
  #|}

/// 先読み文字を消費する（read_char前に呼ぶ）
extern "js" fn consume_peeked_ffi(port_id : Int) -> Unit =
  #|(port_id) => {
  #|  if (!globalThis.__selene_ports) return;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (port) {
  #|    delete port.peeked;
  #|  }
  #|}

/// ポートに1文字書き込む
extern "js" fn write_char_ffi(port_id : Int, char_code : Int) -> Bool =
  #|(port_id, char_code) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return false;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port || port.type !== 'output') return false;
  #|  try {
  #|    const buffer = Buffer.from([char_code]);
  #|    fs.writeSync(port.fd, buffer);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

/// ポートに文字列を書き込む
extern "js" fn write_string_ffi(port_id : Int, str : String) -> Bool =
  #|(port_id, str) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return false;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port || port.type !== 'output') return false;
  #|  try {
  #|    fs.writeSync(port.fd, str);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

/// ポートがEOFに達したかどうか
extern "js" fn eof_object_ffi(port_id : Int) -> Bool =
  #|(port_id) => {
  #|  if (!globalThis.__selene_ports) return true;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port) return true;
  #|  return port.eof === true;
  #|}

// =============================================================================
// ポート操作ラッパー関数
// =============================================================================

/// ファイルを入力用に開く
pub fn open_input_file(filename : String, port_id : Int) -> Int {
  open_input_file_ffi(filename, port_id)
}

/// ファイルを出力用に開く
pub fn open_output_file(filename : String, port_id : Int) -> Int {
  open_output_file_ffi(filename, port_id)
}

/// ポートを閉じる
pub fn close_port(port_id : Int) -> Bool {
  close_port_ffi(port_id)
}

/// ポートから1文字読み取る
pub fn read_char_from_port(port_id : Int) -> Int {
  // 先読みした文字があればそれを返す
  let peeked = peek_char_ffi(port_id)
  if peeked >= 0 {
    consume_peeked_ffi(port_id)
    return peeked
  }
  read_char_ffi(port_id)
}

/// ポートから1文字先読み
pub fn peek_char_from_port(port_id : Int) -> Int {
  peek_char_ffi(port_id)
}

/// ポートに1文字書き込む
pub fn write_char_to_port(port_id : Int, char_code : Int) -> Bool {
  write_char_ffi(port_id, char_code)
}

/// ポートに文字列を書き込む
pub fn write_string_to_port(port_id : Int, str : String) -> Bool {
  write_string_ffi(port_id, str)
}

/// ポートがEOFに達したかどうか
pub fn is_eof(port_id : Int) -> Bool {
  eof_object_ffi(port_id)
}

// =============================================================================
// ファイル読み込み（load用）
// =============================================================================

/// ファイル全体を文字列として読み込む（失敗時は空文字列）
extern "js" fn read_file_ffi(filename : String) -> String =
  #|(filename) => {
  #|  const fs = require('fs');
  #|  try {
  #|    return fs.readFileSync(filename, 'utf8');
  #|  } catch (e) {
  #|    return '';
  #|  }
  #|}

/// ファイル全体を読み込む
pub fn read_file(filename : String) -> String {
  read_file_ffi(filename)
}

/// ファイルが存在するかどうか
extern "js" fn file_exists_ffi(filename : String) -> Bool =
  #|(filename) => {
  #|  const fs = require('fs');
  #|  try {
  #|    fs.accessSync(filename, fs.constants.R_OK);
  #|    return true;
  #|  } catch (e) {
  #|    return false;
  #|  }
  #|}

/// ファイルが存在するかどうか
pub fn file_exists(filename : String) -> Bool {
  file_exists_ffi(filename)
}
