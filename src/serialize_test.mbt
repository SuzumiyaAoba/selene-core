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

/// ========================================
/// デシリアライズのテスト
/// ========================================

/// 基本的なラウンドトリップテスト
test "deserialize: simple roundtrip" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          // main chunk の比較
          assert_eq!(restored.main.arity, original.main.arity)
          assert_eq!(restored.main.num_free_vars, original.main.num_free_vars)
          assert_eq!(restored.main.num_locals, original.main.num_locals)
          assert_eq!(restored.main.code.length(), original.main.code.length())
          assert_eq!(restored.main.constants.length(), original.main.constants.length())
          assert_eq!(restored.main.names.length(), original.main.names.length())
          assert_eq!(restored.chunks.length(), original.chunks.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// Lambda を含むラウンドトリップ
test "deserialize: lambda roundtrip" {
  let expr = parse_one("(lambda (x y) (+ x y))")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          // chunks の数が一致
          assert_eq!(restored.chunks.length(), original.chunks.length())
          // lambda chunk の arity が一致
          if restored.chunks.length() > 0 {
            assert_eq!(restored.chunks[0].arity, original.chunks[0].arity)
          }
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// 定数のラウンドトリップ
test "deserialize: constants roundtrip" {
  let expr = parse_one("(list 1 2 \"hello\" 'world)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq!(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// 制御フローのラウンドトリップ
test "deserialize: control flow roundtrip" {
  let expr = parse_one("(if #t 1 2)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq!(restored.main.code.length(), original.main.code.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// 無効なフォーマットのエラー
test "deserialize: invalid format" {
  match deserialize_module_from_string("INVALID_HEADER") {
    Err(SerializeError::InvalidFormat(_)) => ()
    _ => fail!("Expected InvalidFormat error")
  }

  match deserialize_module_from_string("") {
    Err(SerializeError::UnexpectedEnd) => ()
    _ => fail!("Expected UnexpectedEnd error")
  }
}

/// 複雑なプログラムのラウンドトリップ
test "deserialize: complex program roundtrip" {
  let expr = parse_one("(define (fact n) (if (<= n 1) 1 (* n (fact (- n 1)))))")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq!(restored.main.code.length(), original.main.code.length())
          assert_eq!(restored.chunks.length(), original.chunks.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// Bool定数のラウンドトリップ
test "deserialize: bool constants roundtrip" {
  let expr = parse_one("(if #t #t #f)")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq!(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}

/// Symbolのラウンドトリップ
test "deserialize: symbol roundtrip" {
  let expr = parse_one("'foo")
  match compile_to_module(expr) {
    Ok(original) => {
      let serialized = serialize_module_to_string(original)
      match deserialize_module_from_string(serialized) {
        Ok(restored) => {
          assert_eq!(restored.main.constants.length(), original.main.constants.length())
        }
        Err(e) => fail!("Deserialization failed: " + e.to_string())
      }
    }
    Err(_) => fail!("Compilation failed")
  }
}
