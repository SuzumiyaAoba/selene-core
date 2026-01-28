/// Serialization test

/// Basic module serialization
test "serialize: simple module" {
  // Compile (+ 1 2)
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      // Check the header
      assert_true(serialized.contains("SELENE_BYTECODE_V1"))
      assert_true(serialized.contains("main_chunk:"))
      assert_true(serialized.contains("arity:"))
      assert_true(serialized.contains("code:"))
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Serializing modules containing Lambda
test "serialize: module with lambda" {
  let expr = parse_one("(lambda (x) x)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      assert_true(serialized.contains("SELENE_BYTECODE_V1"))
      // There should be a child chunk
      assert_true(serialized.contains("chunks:"))
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Serializing modules containing constants
test "serialize: module with constants" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      assert_true(serialized.contains("constants:"))
      assert_true(serialized.contains("42") || serialized.contains("Int(42)"))
    }
    Err(_) => fail("Compilation failed")
  }
}

/// ========================================
/// Deserialization test
/// ========================================

/// Basic round trip test
test "deserialize: simple roundtrip" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          // main chunk comparison
          assert_eq(restored.main.arity, original.main.arity)
          assert_eq(restored.main.num_free_vars, original.main.num_free_vars)
          assert_eq(restored.main.num_locals, original.main.num_locals)
          assert_eq(restored.main.code.length(), original.main.code.length())
          assert_eq(restored.main.constants.length(), original.main.constants.length())
          assert_eq(restored.main.names.length(), original.main.names.length())
          assert_eq(restored.chunks.length(), original.chunks.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Roundtrips involving Lambda
test "deserialize: lambda roundtrip" {
  let expr = parse_one("(lambda (x y) (+ x y))")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          // Match number of chunks
          assert_eq(restored.chunks.length(), original.chunks.length())
          // Lambda chunk arity matches
          if restored.chunks.length() > 0 {
            assert_eq(restored.chunks[0].arity, original.chunks[0].arity)
          }
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Constant round trip
test "deserialize: constants roundtrip" {
  let expr = parse_one("(list 1 2 \"hello\" 'world)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Control flow round trip
test "deserialize: control flow roundtrip" {
  let expr = parse_one("(if #t 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq(restored.main.code.length(), original.main.code.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// invalid format error
test "deserialize: invalid format" {
  match deserialize_module_from_string("INVALID_HEADER") {
    Err(SerializeError::InvalidFormat(_)) => ()
    _ => fail("Expected InvalidFormat error")
  }

  match deserialize_module_from_string("") {
    Err(SerializeError::UnexpectedEnd) => ()
    _ => fail("Expected UnexpectedEnd error")
  }
}

/// Roundtrips for complex programs
test "deserialize: complex program roundtrip" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq(restored.main.code.length(), original.main.code.length())
          assert_eq(restored.chunks.length(), original.chunks.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Bool constant round trip
test "deserialize: bool constants roundtrip" {
  let expr = parse_one("(if #t #t #f)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Symbol round trip
test "deserialize: symbol roundtrip" {
  let expr = parse_one("'foo")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// ========================================
/// Binary format testing
/// ========================================

/// Basic round trip in binary format
test "binary: simple roundtrip" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let binary = serialize_module_to_binary(original)
      match deserialize_module_from_binary(binary) {
        Ok(restored) => {
          assert_eq(restored.main.arity, original.main.arity)
          assert_eq(restored.main.num_free_vars, original.main.num_free_vars)
          assert_eq(restored.main.num_locals, original.main.num_locals)
          assert_eq(restored.main.code.length(), original.main.code.length())
          assert_eq(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail("Binary deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Lambda roundtrip in binary format
test "binary: lambda roundtrip" {
  let expr = parse_one("(lambda (x y) (+ x y))")
  match compile_to_module(expr) {
    Ok(original) => {
      let binary = serialize_module_to_binary(original)
      match deserialize_module_from_binary(binary) {
        Ok(restored) => {
          assert_eq(restored.chunks.length(), original.chunks.length())
          if restored.chunks.length() > 0 {
            assert_eq(restored.chunks[0].arity, original.chunks[0].arity)
          }
        }
        Err(e) => fail("Binary deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Constant round trip in binary format
test "binary: constants roundtrip" {
  let expr = parse_one("(list 1 2 \"hello\" 'world)")
  match compile_to_module(expr) {
    Ok(original) => {
      let binary = serialize_module_to_binary(original)
      match deserialize_module_from_binary(binary) {
        Ok(restored) => {
          assert_eq(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail("Binary deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Control flow round trip in binary format
test "binary: control flow roundtrip" {
  let expr = parse_one("(if #t 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let binary = serialize_module_to_binary(original)
      match deserialize_module_from_binary(binary) {
        Ok(restored) => {
          assert_eq(restored.main.code.length(), original.main.code.length())
        }
        Err(e) => fail("Binary deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Complex program round trip in binary format
test "binary: complex program roundtrip" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(original) => {
      let binary = serialize_module_to_binary(original)
      match deserialize_module_from_binary(binary) {
        Ok(restored) => {
          assert_eq(restored.main.code.length(), original.main.code.length())
          assert_eq(restored.chunks.length(), original.chunks.length())
        }
        Err(e) => fail("Binary deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail("Compilation failed")
  }
}

/// Bad data error in binary format
test "binary: invalid format" {
  // empty data
  match deserialize_module_from_binary([]) {
    Err(SerializeError::UnexpectedEnd) => ()
    _ => fail("Expected UnexpectedEnd error")
  }

  // fraudulent magic number
  match deserialize_module_from_binary([0x00, 0x00, 0x00, 0x00]) {
    Err(SerializeError::InvalidFormat(_)) => ()
    _ => fail("Expected InvalidFormat error")
  }
}

/// Ensure binary size is smaller than text
test "binary: smaller than text" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let text = serialize_module_to_string(compiled)
      let binary = serialize_module_to_binary(compiled)
      // binary should be smaller than text
      assert_true(binary.length() < text.length())
    }
    Err(_) => fail("Compilation failed")
  }
}
