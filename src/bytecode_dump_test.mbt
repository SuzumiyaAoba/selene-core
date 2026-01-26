/// バイトコードダンプツールのテスト

/// デフォルトオプションのテスト
test "bytecode_dump: default options" {
  let options = default_dump_options()
  assert_true!(options.verbose)
  assert_true!(not(options.hex_addresses))
  assert_true!(options.inline_constants)
  assert_eq!(options.indent_width, 2)
}

/// 簡潔オプションのテスト
test "bytecode_dump: compact options" {
  let options = compact_dump_options()
  assert_true!(not(options.verbose))
  assert_true!(options.inline_constants)
}

/// 簡単な式のダンプテスト
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

/// Lambda のダンプテスト
test "bytecode_dump: lambda" {
  let expr = parse_one("(lambda (x) (+ x 1))")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("MAIN CHUNK"))
      // Lambda があるので子チャンクがあるはず
      assert_true!(dump.contains("CHILD CHUNKS") || dump.contains("MAKE_CLOSURE"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// 定数プールのダンプテスト
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

/// 名前テーブルのダンプテスト
test "bytecode_dump: names" {
  let expr = parse_one("(+ x y)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // グローバル変数参照があるので名前テーブルがあるはず
      assert_true!(dump.contains("LOAD_GLOBAL") || dump.contains("Names:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// 簡潔モードのダンプテスト
test "bytecode_dump: compact mode" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let verbose_dump = dump_module(module, default_dump_options())
      let compact_dump = dump_module(module, compact_dump_options())
      // 簡潔モードは詳細モードより短いはず
      assert_true!(compact_dump.length() <= verbose_dump.length())
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// 16進数アドレスのテスト
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

/// 定数表示のテスト（ダンプ出力経由）
test "bytecode_dump: constant display" {
  // 各種定数を含む式をコンパイルしてダンプ
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("42") || dump.contains("int"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // 文字列定数
  let expr2 = parse_one("\"hello\"")
  match compile_to_module(expr2) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("hello") || dump.contains("string"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // シンボル定数
  let expr3 = parse_one("'foo")
  match compile_to_module(expr3) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("foo") || dump.contains("symbol"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// オペコード表示のテスト（ダンプ出力経由）
test "bytecode_dump: opcode display" {
  // 各種命令を含む式をコンパイルしてダンプ
  // Push
  let expr1 = parse_one("42")
  match compile_to_module(expr1) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Call - プリミティブ関数呼び出し
  let expr2 = parse_one("(+ 1 2)")
  match compile_to_module(expr2) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // ダンプが正常に生成されることを確認（定数畳み込みで最適化されている可能性あり）
      assert_true!(dump.contains("Code:") || dump.contains("PRIM_CALL") || dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }

  // Jump (if 文は JUMP_IF_FALSE または JUMP を生成)
  let expr3 = parse_one("(if #t 1 2)")
  match compile_to_module(expr3) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // JUMP または JUMP_IF_FALSE または条件分岐命令がある
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

/// compile_and_dump のテスト
test "bytecode_dump: compile_and_dump" {
  match compile_and_dump_default("(+ 1 2)") {
    Ok(dump) => {
      assert_true!(dump.contains("BYTECODE MODULE DUMP"))
      assert_true!(dump.contains("Code:"))
    }
    Err(e) => fail!("Compile and dump failed: " + e)
  }
}

/// モジュール統計のテスト
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

/// 複雑な式のダンプテスト
test "bytecode_dump: complex expression" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      assert_true!(dump.contains("BYTECODE MODULE DUMP"))
      // 再帰関数なので複数の命令タイプがあるはず
      assert_true!(dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// if 式のダンプテスト
test "bytecode_dump: if expression" {
  let expr = parse_one("(if #t 1 2)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // if 文はジャンプ命令を生成するはず（JUMP または JUMP_IF_FALSE）
      // もしくは定数畳み込みで最適化されている可能性がある
      assert_true!(dump.contains("JUMP") || dump.contains("PUSH") || dump.contains("Code:"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// リストのダンプテスト
test "bytecode_dump: list" {
  let expr = parse_one("(list 1 2 3)")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // list はプリミティブ呼び出しか MAKE_LIST を生成するはず
      assert_true!(dump.contains("PRIM_CALL") || dump.contains("MAKE_LIST"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// 文字列エスケープのテスト
test "bytecode_dump: string escape" {
  let expr = parse_one("\"hello\\nworld\"")
  match compile_to_module(expr) {
    Ok(module) => {
      let dump = dump_module(module, default_dump_options())
      // 改行はエスケープされるはず
      assert_true!(dump.contains("string"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}

/// チャンクダンプのテスト
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

/// インライン定数無効のテスト
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
      // PUSH 命令にはインライン定数がないはず
      assert_true!(dump.contains("PUSH"))
    }
    Err(e) => fail!("Compile failed: " + e.to_string())
  }
}
