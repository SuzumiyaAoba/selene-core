/// シリアライズのテスト

/// 基本的なモジュールのシリアライズ
test "serialize: simple module" {
  // (+ 1 2) をコンパイル
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      // ヘッダーの確認
      assert_true!(serialized.contains("SELENE_BYTECODE_V1"))
      assert_true!(serialized.contains("main_chunk:"))
      assert_true!(serialized.contains("arity:"))
      assert_true!(serialized.contains("code:"))
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// Lambda を含むモジュールのシリアライズ
test "serialize: module with lambda" {
  let expr = parse_one("(lambda (x) x)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      assert_true!(serialized.contains("SELENE_BYTECODE_V1"))
      // 子チャンクがあるはず
      assert_true!(serialized.contains("chunks:"))
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// 定数を含むモジュールのシリアライズ
test "serialize: module with constants" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let serialized = serialize_module_to_string(compiled)
      assert_true!(serialized.contains("constants:"))
      assert_true!(serialized.contains("42") || serialized.contains("Int(42)"))
    }
    Err(_) => fail!("Compilation failed")
  }
}
