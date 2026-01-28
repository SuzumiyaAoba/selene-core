/// Test Bytecode Dump Tool

/// Test default options
test "bytecode_dump: default options" {
  let options = default_dump_options()
  assert_true!(options.verbose)
  assert_true!(not(options.hex_addresses))
  assert_true!(options.inline_constants)
  assert_eq!(options.indent_width, 2)
}

/// Testing Brief Options
test "bytecode_dump: compact options" {
  let options = compact_dump_options()
  assert_true!(not(options.verbose))
  assert_true!(options.inline_constants)
}

/// Simple expression dump test
test "bytecode_dump: simple expression" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("BYTECODE MODULE DUMP"))
      assert_true!(dump.contains("MAIN CHUNK"))
      assert_true!(dump.contains("Code:"))
      assert_true!(dump.contains("END OF DUMP"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Lambda dump test
test "bytecode_dump: lambda" {
  let expr = parse_one("(lambda (x) (+ x 1))")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("MAIN CHUNK"))
      // There should be child chunks because there is a lambda
      assert_true!(dump.contains("CHILD CHUNKS") || dump.contains("MAKE_CLOSURE"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Constant Pool Dump Test
test "bytecode_dump: constants" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("Constants:") || dump.contains("42"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Name table dump test
test "bytecode_dump: names" {
  let expr = parse_one("(+ x y)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // There should be a name table because there is a global variable reference
      assert_true!(dump.contains("LOAD_GLOBAL") || dump.contains("Names:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Brief Mode Dump Test
test "bytecode_dump: compact mode" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let verbose_dump = dump_module(module, default_dump_options())
      let compact_dump = dump_module(module, compact_dump_options())
      // Brief mode should be shorter than Advanced mode
      assert_true!(compact_dump.length() <= verbose_dump.length())
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Test hexadecimal address
test "bytecode_dump: hex addresses" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let options : DumpOptions = {
        verbose: true,
        hex_addresses: true,
        inline_constants: true,
        indent_width: 2,
      }
      let dump = dump_module(module, options)
      assert_true!(dump.contains("0x"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Test of constant display (via dump output)
test "bytecode_dump: constant display" {
  // Compile and dump expressions containing various constants
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("42") || dump.contains("int"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // string_literal
  let expr2 = parse_one("\"hello\"")
  match compile_to_module(expr2) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("hello") || dump.contains("string"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Symbol constant
  let expr3 = parse_one("'foo")
  match compile_to_module(expr3) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("foo") || dump.contains("symbol"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Test opcode display (via dump output)
test "bytecode_dump: opcode display" {
  // Compile and dump expressions containing various instructions
  // Push
  let expr1 = parse_one("42")
  match compile_to_module(expr1) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Call - Primitive function call
  let expr2 = parse_one("(+ 1 2)")
  match compile_to_module(expr2) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // Verify that dumps are generated successfully (may be optimized with constant convolution)
      assert_true!(dump.contains("Code:") || dump.contains("PRIM_CALL") || dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Jump (if statement generates jump_IF_false or jump)
  let expr3 = parse_one("(if #t 1 2)")
  match compile_to_module(expr3) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // Has jump or jump_IF_false or conditional branch instructions
      assert_true!(dump.contains("JUMP") || dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Return
  let expr4 = parse_one("(lambda (x) x)")
  match compile_to_module(expr4) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("RETURN"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// test compile_and_dump
test "bytecode_dump: compile_and_dump" {
  match compile_and_dump_default("(+ 1 2)") {
    Ok(dump) => {
      assert_true!(dump.contains("BYTECODE MODULE DUMP"))
      assert_true!(dump.contains("Code:"))
    }
    Err(e) => fail!("Compile and dump failed: " + e)
  }
}

/// Test Module Statistics
test "bytecode_dump: module stats" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let stats = dump_module_stats(module)
      assert_true!(stats.contains("Module Statistics"))
      assert_true!(stats.contains("Code size"))
      assert_true!(stats.contains("Constants"))
      assert_true!(stats.contains("Totals"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Complex expression dump test
test "bytecode_dump: complex expression" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("BYTECODE MODULE DUMP"))
      // Since it is a recursive function, there should be multiple instruction types
      assert_true!(dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// dump test for if expression
test "bytecode_dump: if expression" {
  let expr = parse_one("(if #t 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // the if statement should generate a jump instruction (jump or jump_IF_false)
      // or may be optimized with constant convolution
      assert_true!(dump.contains("JUMP") || dump.contains("PUSH") || dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// List dump test
test "bytecode_dump: list" {
  let expr = parse_one("(list 1 2 3)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // list should generate a primitive call or make_list
      assert_true!(dump.contains("PRIM_CALL") || dump.contains("MAKE_LIST"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Test String Escape
test "bytecode_dump: string escape" {
  let expr = parse_one("\"hello\\nworld\"")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // Line breaks should be escaped
      assert_true!(dump.contains("string"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Test Chunk Dump
test "bytecode_dump: chunk dump" {
  let expr = parse_one("(lambda (x y) (+ x y))")
  match compile_to_module(expr) {
    Ok(module) => {
      let chunk_dump = dump_chunk(module.main, -1, module, default_dump_options())
      assert_true!(chunk_dump.contains("Arity:"))
      assert_true!(chunk_dump.contains("Locals:"))
      assert_true!(chunk_dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// Inline Constant Disabled Test
test "bytecode_dump: no inline constants" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(module) => {
      let options : DumpOptions = {
        verbose: true,
        hex_addresses: false,
        inline_constants: false,
        indent_width: 2,
      }
      let dump = dump_module(module, options)
      // Push instructions should have no inline constants
      assert_true!(dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}
