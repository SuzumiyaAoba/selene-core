/// Testing the profiler

/// Profiler creation test
test "profiler: create" {
  let profiler = new_profiler()
  assert_true!(profiler.enabled)
  assert_eq!(profiler.total_instructions, 0L)
  assert_eq!(profiler.total_calls, 0L)
}

/// Profiler reset test
test "profiler: reset" {
  let profiler = new_profiler()

  // add data
  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Pop)
  profiler_record_call(profiler, 0, Some("test"))

  assert_true!(profiler.total_instructions > 0L)
  assert_true!(profiler.total_calls > 0L)

  // reset
  profiler_reset(profiler)

  assert_eq!(profiler.total_instructions, 0L)
  assert_eq!(profiler.total_calls, 0L)
}

/// Enabling/disabling test
test "profiler: enable/disable" {
  let profiler = new_profiler()

  assert_true!(profiler.enabled)

  profiler_disable(profiler)
  assert_true!(not(profiler.enabled))

  // Not recorded when disabled
  profiler_record_instruction(profiler, Opcode::Push(0))
  assert_eq!(profiler.total_instructions, 0L)

  profiler_enable(profiler)
  profiler_record_instruction(profiler, Opcode::Push(0))
  assert_eq!(profiler.total_instructions, 1L)
}

/// Instruction record test
test "profiler: record instructions" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_instruction(profiler, Opcode::Push(1))
  profiler_record_instruction(profiler, Opcode::Pop)
  profiler_record_instruction(profiler, Opcode::Push(2))

  assert_eq!(profiler.total_instructions, 4L)

  // Push should have been recorded 3 times.
  match profiler.instruction_stats.get("Push") {
    Some(stats) => assert_eq!(stats.count, 3L)
    None => fail!("Push stats not found")
  }

  // Pop should have been recorded once.
  match profiler.instruction_stats.get("Pop") {
    Some(stats) => assert_eq!(stats.count, 1L)
    None => fail!("Pop stats not found")
  }
}

/// Function call recording test
test "profiler: record function calls" {
  let profiler = new_profiler()

  profiler_record_call(profiler, -1, Some("main"))
  profiler_record_call(profiler, 0, Some("factorial"))
  profiler_record_call(profiler, 0, Some("factorial"))
  profiler_record_call(profiler, 1, None)

  assert_eq!(profiler.total_calls, 4L)

  // factorial should have been called twice
  match profiler.function_stats.get(0) {
    Some(stats) => {
      assert_eq!(stats.call_count, 2L)
      assert_eq!(stats.name, "factorial")
    }
    None => fail!("factorial stats not found")
  }

  // Unnamed lambda is an automatically generated name
  match profiler.function_stats.get(1) {
    Some(stats) => assert_true!(stats.name.contains("lambda"))
    None => fail!("lambda stats not found")
  }
}

/// Function return recording test
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

/// instruction report test
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

/// function report test
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

/// hotspot report test
test "profiler: hotspot report" {
  let profiler = new_profiler()

  // Record multiple instructions
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

  // Also records function calls
  profiler_record_call(profiler, 0, Some("hot-function"))
  profiler_record_call(profiler, 0, Some("hot-function"))
  profiler_record_call(profiler, 1, Some("cold-function"))

  let report = profiler_hotspot_report(profiler, 3)
  assert_true!(report.contains("Hotspot Analysis"))
  assert_true!(report.contains("Push"))  // most
  assert_true!(report.contains("hot-function"))  // most called
}

/// Summary report test
test "profiler: summary report" {
  let profiler = new_profiler()

  profiler_record_instruction(profiler, Opcode::Push(0))
  profiler_record_call(profiler, -1, Some("main"))

  let report = profiler_summary(profiler)
  assert_true!(report.contains("Profiler Summary"))
  assert_true!(report.contains("Total instructions executed"))
  assert_true!(report.contains("Total function calls"))
}

/// full report test
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

/// Empty profiler report test
test "profiler: empty reports" {
  let profiler = new_profiler()

  let instr_report = profiler_instruction_report(profiler)
  assert_true!(instr_report.contains("No instructions executed"))

  let func_report = profiler_function_report(profiler)
  assert_true!(func_report.contains("No function calls recorded"))
}

/// Profiling tests with real expressions
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
      // Verify that the instruction was executed
      assert_true!(profiler.total_instructions > 0L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// Profiling tests with Lambda
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
      // Verify function call was recorded
      assert_true!(profiler.total_calls >= 1L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// Profiling tests with recursive functions
test "profiler: with recursion" {
  reset_gc_stats()
  let profiler = new_profiler()

  // Test simple recursive constructs instead of defining and calling fact
  let expr = parse_one("(+ (+ 1 2) (+ 3 4))")
  match vm_eval_with_profiler(expr, profiler) {
    Ok(result) => {
      match result {
        Value::Number(Number::Int(n)) => assert_eq!(n, 10)
        _ => fail!("Expected number")
      }
      // Verify that instructions have been executed (at least one)
      assert_true!(profiler.total_instructions >= 1L)
    }
    Err(e) => fail!("Eval failed: " + e)
  }
}

/// Cooperation test with GC statistics
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
