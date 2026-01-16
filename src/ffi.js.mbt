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
