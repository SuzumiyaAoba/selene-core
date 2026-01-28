/// Stub implementation for wasm backend
/// Reading standard input is not available in wasm

/// Read a line from standard input (prompted, stub implementation)
/// wasm backend always returns empty string
pub fn read_line_with_prompt(_prompt : String) -> String {
  ""  // stdin reading not available in wasm
}

/// Read one line from standard input (stub implementation)
/// wasm backend always returns empty string
pub fn read_line() -> String {
  ""  // stdin reading not available in wasm
}

// =============================================================================
// Port operation stubs (not available in wasm)
// =============================================================================

/// Open file for input (always fails)
pub fn open_input_file(_filename : String, _port_id : Int) -> Int {
  -1  // File operations are not available in wasm
}

/// Open file for output (always fails)
pub fn open_output_file(_filename : String, _port_id : Int) -> Int {
  -1  // File operations are not available in wasm
}

/// Close port (always fails)
pub fn close_port(_port_id : Int) -> Bool {
  false  // File operations are not available in wasm
}

/// Read one character from port (always EOF)
pub fn read_char_from_port(_port_id : Int) -> Int {
  -1  // File operations are not available in wasm
}

/// Read ahead one character from port (always EOF)
pub fn peek_char_from_port(_port_id : Int) -> Int {
  -1  // File operations are not available in wasm
}

/// Write one character to port (always fails)
pub fn write_char_to_port(_port_id : Int, _char_code : Int) -> Bool {
  false  // File operations are not available in wasm
}

/// Write string to port (always fails)
pub fn write_string_to_port(_port_id : Int, _str : String) -> Bool {
  false  // File operations are not available in wasm
}

/// Whether the port has reached EOF (always true)
pub fn is_eof(_port_id : Int) -> Bool {
  true  // File operations are not available in wasm
}

/// Read the entire file (always empty string)
pub fn read_file(_filename : String) -> String {
  ""  // File operations are not available in wasm
}

/// whether the file exists (always false)
pub fn file_exists(_filename : String) -> Bool {
  false  // File operations are not available in wasm
}
