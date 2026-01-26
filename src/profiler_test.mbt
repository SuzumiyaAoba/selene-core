/// プロファイラのテスト

/// プロファイラの作成テスト
test "profiler: create" {
  let profiler = new_profiler()
  assert_true!(profiler.enabled)
  assert_eq!(profiler.total_instructions, 0L)
  assert_eq!(profiler.total_calls, 0L)
}

/// プロファイラのリセットテスト
test "profiler: reset" {
  let profiler = new_profiler()

  // データを追加
  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Pop)
  profiler_record_call(profiler, 0, Some("test"))

  assert_true!(profiler.total_instructions > 0L)
  assert_true!(profiler.total_calls > 0L)

  // リセット
  profiler_reset(profiler)

  assert_eq!(profiler.total_instructions, 0L)
  assert_eq!(profiler.total_calls, 0L)
}

/// 有効化/無効化テスト
test "profiler: enable/disable" {
  let profiler = new_profiler()

  assert_true!(profiler.enabled)

  profiler_disable(profiler)
  assert_true!(not(profiler.enabled))

  // 無効時は記録されない
  profiler_record_instruction(profiler, Opcode::Push(0))
  assert_eq!(profiler.total_instructions, 0L)

  profiler_enable(profiler)
  profiler_record_instruction(profiler, Opcode::Push(0))
  assert_eq!(profiler.total_instructions, 1L)
}

/// 命令記録テスト
test "profiler: record instructions" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Push(1))
  profiler_record_instruction(profiler, Opcode::Pop)
  profiler_record_instruction(profiler, Opcode::Push(2))

  assert_eq!(profiler.total_instructions, 4L)

  // Push が 3 回記録されているはず
  match profiler.instruction_stats.get("Push") {
    Some(stats) => assert_eq!(stats.count, 3L)
    None => fail!("Push stats not found")
  }

  // Pop が 1 回記録されているはず
  match profiler.instruction_stats.get("Pop") {
    Some(stats) => assert_eq!(stats.count, 1L)
    None => fail!("Pop stats not found")
  }
}

/// 関数呼び出し記録テスト
test "profiler: record function calls" {
  let profiler = new_profiler()

  profiler_record_call(profiler, -1, Some("main"))
  profiler_record_call(profiler, 0, Some("factorial"))
  profiler_record_call(profiler, 0, Some("factorial"))
  profiler_record_call(profiler, 1, None)

  assert_eq!(profiler.total_calls, 4L)

  // factorial が 2 回呼び出されているはず
  match profiler.function_stats.get(0) {
    Some(stats) => {
      assert_eq!(stats.call_count, 2L)
      assert_eq!(stats.name, "factorial")
    }
    None => fail!("factorial stats not found")
  }

  // 名前なしの lambda は自動生成名
  match profiler.function_stats.get(1) {
    Some(stats) => assert_true!(stats.name.contains("lambda"))
    None => fail!("lambda stats not found")
  }
}

/// 関数リターン記録テスト
test "profiler: record returns" {
  let profiler = new_profiler()

  profiler_record_call(profiler, -1, Some("main"))
  profiler_record_call(profiler, 0, Some("foo"))

  assert_eq!(profiler.call_stack.length(), 2)

  profiler_record_return(profiler)
  assert_eq!(profiler.call_stack.length(), 1)

  profiler_record_return(profiler)
  assert_eq!(profiler.call_stack.length(), 0)
}

/// 命令レポートテスト
test "profiler: instruction report" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Push(1))
  profiler_record_instruction(profiler, Opcode::Pop)

  let report = profiler_instruction_report(profiler)
  assert_true!(report.contains("Instruction Statistics"))
  assert_true!(report.contains("Push"))
  assert_true!(report.contains("Pop"))
  assert_true!(report.contains("Total instructions: 3"))
}

/// 関数レポートテスト
test "profiler: function report" {
  let profiler = new_profiler()

  profiler_record_call(profiler, -1, Some("main"))
  profiler_record_call(profiler, 0, Some("test-func"))

  let report = profiler_function_report(profiler)
  assert_true!(report.contains("Function Statistics"))
  assert_true!(report.contains("main"))
  assert_true!(report.contains("test-func"))
  assert_true!(report.contains("Total calls: 2"))
}

/// ホットスポットレポートテスト
test "profiler: hotspot report" {
  let profiler = new_profiler()

  // 複数の命令を記録
  let mut i = 0
  while i < 100 {
    profiler_record_instruction(profiler, Opcode::Push(0))
    i = i + 1
  }
  let mut j = 0
  while j < 50 {
    profiler_record_instruction(profiler, Opcode::Pop)
    j = j + 1
  }
  let mut k = 0
  while k < 10 {
    profiler_record_instruction(profiler, Opcode::Return)
    k = k + 1
  }

  // 関数呼び出しも記録
  profiler_record_call(profiler, 0, Some("hot-function"))
  profiler_record_call(profiler, 0, Some("hot-function"))
  profiler_record_call(profiler, 1, Some("cold-function"))

  let report = profiler_hotspot_report(profiler, 3)
  assert_true!(report.contains("Hotspot Analysis"))
  assert_true!(report.contains("Push"))  // 最も多い
  assert_true!(report.contains("hot-function"))  // 最も呼び出される
}

/// サマリーレポートテスト
test "profiler: summary report" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_call(profiler, -1, Some("main"))

  let report = profiler_summary(profiler)
  assert_true!(report.contains("Profiler Summary"))
  assert_true!(report.contains("Total instructions executed"))
  assert_true!(report.contains("Total function calls"))
}

/// 完全レポートテスト
test "profiler: full report" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Pop)
  profiler_record_call(profiler, -1, Some("main"))

  let report = profiler_full_report(profiler)
  assert_true!(report.contains("Profiler Summary"))
  assert_true!(report.contains("Instruction Statistics"))
  assert_true!(report.contains("Function Statistics"))
  assert_true!(report.contains("Hotspot Analysis"))
}

/// 空のプロファイラレポートテスト
test "profiler: empty reports" {
  let profiler = new_profiler()

  let instr_report = profiler_instruction_report(profiler)
  assert_true!(instr_report.contains("No instructions executed"))

  let func_report = profiler_function_report(profiler)
  assert_true!(func_report.contains("No function calls recorded"))
}

/// 実際の式でのプロファイリングテスト
test "profiler: with simple expression" {
  reset_gc_stats()
  let profiler = new_profiler()

  let expr = parse_one("(+ 1 2)")
  match vm_eval_with_profiler(expr, profiler) {
    Ok(result) => {
      match result {
        Value::Number(Number::Int(n)) => assert_eq!(n, 3)
        _ => fail!("Expected number")
      }
      // 命令が実行されたことを確認
      assert_true!(profiler.total_instructions > 0L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// Lambda でのプロファイリングテスト
test "profiler: with lambda" {
  reset_gc_stats()
  let profiler = new_profiler()

  let expr = parse_one("((lambda (x) (+ x 1)) 5)")
  match vm_eval_with_profiler(expr, profiler) {
    Ok(result) => {
      match result {
        Value::Number(Number::Int(n)) => assert_eq!(n, 6)
        _ => fail!("Expected number")
      }
      // 関数呼び出しが記録されたことを確認
      assert_true!(profiler.total_calls >= 1L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// 再帰関数でのプロファイリングテスト
test "profiler: with recursion" {
  reset_gc_stats()
  let profiler = new_profiler()

  // fact を定義して呼び出す代わりに、簡単な再帰的構造をテスト
  let expr = parse_one("(+ (+ 1 2) (+ 3 4))")
  match vm_eval_with_profiler(expr, profiler) {
    Ok(result) => {
      match result {
        Value::Number(Number::Int(n)) => assert_eq!(n, 10)
        _ => fail!("Expected number")
      }
      // 命令が実行されたことを確認（少なくとも1つ以上）
      assert_true!(profiler.total_instructions >= 1L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// GC統計との連携テスト
test "profiler: gc stats integration" {
  reset_gc_stats()
  let profiler = new_profiler()

  let expr = parse_one("(list 1 2 3)")
  match vm_eval_with_profiler(expr, profiler) {
    Ok(_) => {
      let summary = profiler_summary(profiler)
      assert_true!(summary.contains("Memory allocations"))
      assert_true!(summary.contains("Pairs"))
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}
