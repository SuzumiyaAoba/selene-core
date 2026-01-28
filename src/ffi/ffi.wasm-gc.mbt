/// Stub implementation for wasm-gc backend
/// Reading standard input is not available with wasm-gc

/// Read a line from standard input (prompted, stub implementation)
/// wasm-gc backend always returns empty string
pub fn read_line_with_prompt(_prompt : String) -> String {
  ""  // stdin reading not available with wasm-gc
}

/// Read one line from standard input (stub implementation)
/// wasm-gc backend always returns empty string
pub fn read_line() -> String {
  ""  // stdin reading not available with wasm-gc
}

// =============================================================================
// Port operation stub (not available in wasm-gc)
// =============================================================================

/// Open file for input (always fails)
pub fn open_input_file(_filename : String, _port_id : Int) -> Int {
  -1  // File operations are not available in wasm-gc
}

/// Open file for output (always fails)
pub fn open_output_file(_filename : String, _port_id : Int) -> Int {
  -1  // File operations are not available in wasm-gc
}

/// Close port (always fails)
pub fn close_port(_port_id : Int) -> Bool {
  false  // File operations are not available in wasm-gc
}

/// Read one character from port (always EOF)
pub fn read_char_from_port(_port_id : Int) -> Int {
  -1  // File operations are not available in wasm-gc
}

/// Read ahead one character from port (always EOF)
pub fn peek_char_from_port(_port_id : Int) -> Int {
  -1  // File operations are not available in wasm-gc
}

/// Write one character to port (always fails)
pub fn write_char_to_port(_port_id : Int, _char_code : Int) -> Bool {
  false  // File operations are not available in wasm-gc
}

/// Write string to port (always fails)
pub fn write_string_to_port(_port_id : Int, _str : String) -> Bool {
  false  // File operations are not available in wasm-gc
}

/// Whether the port has reached EOF (always true)
pub fn is_eof(_port_id : Int) -> Bool {
  true  // File operations are not available in wasm-gc
}

/// Read the entire file (always empty string)
pub fn read_file(_filename : String) -> String {
  ""  // File operations are not available in wasm-gc
}

/// whether the file exists (always false)
pub fn file_exists(_filename : String) -> Bool {
  false  // File operations are not available in wasm-gc
}
