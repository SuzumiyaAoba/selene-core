/// JavaScript FFI for Node.js
/// This file is for JS backend only

/// Display a prompt and then read a line from standard input (synchronous version)
/// Read from standard input (fd=0) using Node.js' fs.readSync
extern "js" fn read_line_with_prompt_ffi(prompt : String) -> String =
  #|(prompt) => {
  #|  const fs = require('fs');
  #|
  #|  // Output prompt (no line breaks)
  #|  if (prompt && prompt.length > 0) {
  #|    process.stdout.write(prompt);
  #|  }
  #|
  #|  let buffer = Buffer.alloc(1);
  #|  let bytesRead = 0;
  #|  let result = '';
  #|
  #|  // Read one byte at a time from standard input to newline
  #|  while (true) {
  #|    try {
  #|      bytesRead = fs.readSync(0, buffer, 0, 1);
  #|      if (bytesRead === 0) break;
  #|      const char = buffer.toString('utf8', 0, bytesRead);
  #|      if (char === '\n') break;
  #|      result += char;
  #|    } catch (e) {
  #|      // Exit in case of EOF or error
  #|      break;
  #|    }
  #|  }
  #|
  #|  return result;
  #|}

/// Read a line from standard input (with prompt)
/// Works only with JS backend
pub fn read_line_with_prompt(prompt : String) -> String {
  read_line_with_prompt_ffi(prompt)
}

/// Read a line from standard input
/// Works only with JS backend
pub fn read_line() -> String {
  read_line_with_prompt("")
}

// =============================================================================
// Port operation FFI
// =============================================================================

/// Port store (port ID -> file descriptor)
/// Managed as a global Map
extern "js" fn port_store_init_ffi() -> Unit =
  #|() => {
  #|  if (!globalThis.__selene_ports) {
  #|    globalThis.__selene_ports = new Map();
  #|  }
  #|}

/// Open file for input (return port ID, -1 on failure)
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

/// Open file for output (return port ID, -1 on failure)
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

/// Close port (true on success)
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

/// Read one character from port (-1 for EOF)
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

/// Read ahead one character from port (does not consume, -1 for EOF)
extern "js" fn peek_char_ffi(port_id : Int) -> Int =
  #|(port_id) => {
  #|  const fs = require('fs');
  #|  if (!globalThis.__selene_ports) return -1;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port || port.type !== 'input') return -1;
  #|  if (port.eof) return -1;
  #|
  #|  // Returns the character in the buffer if there is one
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
  #|    // Save read-ahead characters
  #|    port.peeked = buffer[0];
  #|    return buffer[0];
  #|  } catch (e) {
  #|    port.eof = true;
  #|    return -1;
  #|  }
  #|}

/// Consume read-ahead characters (call before read_char)
extern "js" fn consume_peeked_ffi(port_id : Int) -> Unit =
  #|(port_id) => {
  #|  if (!globalThis.__selene_ports) return;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (port) {
  #|    delete port.peeked;
  #|  }
  #|}

/// write one character to port
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

/// write string to port
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

/// Whether the port has reached EOF
extern "js" fn eof_object_ffi(port_id : Int) -> Bool =
  #|(port_id) => {
  #|  if (!globalThis.__selene_ports) return true;
  #|  const port = globalThis.__selene_ports.get(port_id);
  #|  if (!port) return true;
  #|  return port.eof === true;
  #|}

// =============================================================================
// Port operation wrapper function
// =============================================================================

/// Open file for input
pub fn open_input_file(filename : String, port_id : Int) -> Int {
  open_input_file_ffi(filename, port_id)
}

/// Open file for output
pub fn open_output_file(filename : String, port_id : Int) -> Int {
  open_output_file_ffi(filename, port_id)
}

/// close port
pub fn close_port(port_id : Int) -> Bool {
  close_port_ffi(port_id)
}

/// read one character from port
pub fn read_char_from_port(port_id : Int) -> Int {
  // If there is a prefetched character, return it
  let peeked = peek_char_ffi(port_id)
  if peeked >= 0 {
    consume_peeked_ffi(port_id)
    return peeked
  }
  read_char_ffi(port_id)
}

/// Read ahead one character from port
pub fn peek_char_from_port(port_id : Int) -> Int {
  peek_char_ffi(port_id)
}

/// write one character to port
pub fn write_char_to_port(port_id : Int, char_code : Int) -> Bool {
  write_char_ffi(port_id, char_code)
}

/// write string to port
pub fn write_string_to_port(port_id : Int, str : String) -> Bool {
  write_string_ffi(port_id, str)
}

/// Whether the port has reached EOF
pub fn is_eof(port_id : Int) -> Bool {
  eof_object_ffi(port_id)
}

// =============================================================================
// File reading (for load)
// =============================================================================

/// Read the entire file as a string (empty string in case of failure)
extern "js" fn read_file_ffi(filename : String) -> String =
  #|(filename) => {
  #|  const fs = require('fs');
  #|  try {
  #|    return fs.readFileSync(filename, 'utf8');
  #|  } catch (e) {
  #|    return '';
  #|  }
  #|}

/// load the entire file
pub fn read_file(filename : String) -> String {
  read_file_ffi(filename)
}

/// whether the file exists
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

/// whether the file exists
pub fn file_exists(filename : String) -> Bool {
  file_exists_ffi(filename)
}
