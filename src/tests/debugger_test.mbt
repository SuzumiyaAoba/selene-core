/// Debugger testing

/// Adding and removing breakpoints test
test "debugger: add and remove breakpoints" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      // Add breakpoint
      let bp1 = add_breakpoint_main(debugger, 0)
      let bp2 = add_breakpoint_main(debugger, 2)
      let bp3 = add_breakpoint(debugger, 0, 1)

      assert_eq(bp1, 1)
      assert_eq(bp2, 2)
      assert_eq(bp3, 3)

      let bps = list_breakpoints(debugger)
      assert_eq(bps.length(), 3)

      // Delete breakpoint
      assert_true(remove_breakpoint(debugger, bp2))
      let bps2 = list_breakpoints(debugger)
      assert_eq(bps2.length(), 2)

      // Delete non-existent breakpoints
      assert_true(not(remove_breakpoint(debugger, 999)))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Breakpoint enable/disable test
test "debugger: enable and disable breakpoints" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      let bp1 = add_breakpoint_main(debugger, 0)

      // Disable
      assert_true(disable_breakpoint(debugger, bp1))
      let bps = list_breakpoints(debugger)
      assert_true(not(bps[0].enabled))

      // enable
      assert_true(enable_breakpoint(debugger, bp1))
      let bps2 = list_breakpoints(debugger)
      assert_true(bps2[0].enabled)
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Breakpoint clear test
test "debugger: clear breakpoints" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      let _ = add_breakpoint_main(debugger, 0)
      let _ = add_breakpoint_main(debugger, 1)
      let _ = add_breakpoint_main(debugger, 2)

      assert_eq(list_breakpoints(debugger).length(), 3)

      clear_breakpoints(debugger)
      assert_eq(list_breakpoints(debugger).length(), 0)
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// step execution test
test "debugger: step execution" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)

      // Add top level frame
      let initial_frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 0,
        base_ptr: 0,
        num_locals: 0,
      }
      vm.call_stack.push(initial_frame)

      let debugger = new_debugger(vm)

      // 1 instruction step
      match debug_step(debugger) {
        Ok(DebugEvent::StepComplete) => ()
        Ok(_) => fail("Expected StepComplete")
        Err(e) => fail("Step failed: " + e.to_string())
      }

      // Verify IP is advanced
      assert_true(vm.ip > 0)
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Run test until the end
test "debugger: run to completion" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)

      // Add top level frame
      let initial_frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 0,
        base_ptr: 0,
        num_locals: 0,
      }
      vm.call_stack.push(initial_frame)

      let debugger = new_debugger(vm)

      match debug_run(debugger) {
        Ok(result) => {
          match result {
            Value::Number(Number::Int(n)) => assert_eq(n, 3)
            _ => fail("Expected number")
          }
        }
        Err(e) => fail("Run failed: " + e.to_string())
      }
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Stack display test
test "debugger: stack display" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      // empty stack
      let empty_str = debug_stack_to_string(debugger)
      assert_true(empty_str.contains("empty"))

      // push value
      vm.stack.push(Value::Number(Number::Int(42)))
      vm.stack.push(Value::Bool(true))

      let stack_str = debug_stack_to_string(debugger)
      assert_true(stack_str.contains("42"))
      assert_true(stack_str.contains("#t"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Call stack display test
test "debugger: call stack display" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      // empty call stack
      let empty_str = debug_call_stack_to_string(debugger)
      assert_true(empty_str.contains("empty"))

      // add frame
      let frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 5,
        base_ptr: 0,
        num_locals: 2,
      }
      vm.call_stack.push(frame)

      let call_str = debug_call_stack_to_string(debugger)
      assert_true(call_str.contains("main"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Location test
test "debugger: location info" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      let location = debug_get_location(debugger)
      assert_true(location.contains("main"))
      assert_true(location.contains("0"))

      // get instructions
      match debug_get_current_instruction(debugger) {
        Some(instr) => assert_true(instr.length() > 0)
        None => fail("Expected instruction")
      }
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Disassembly display test
test "debugger: disassemble" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      let disasm = debug_disassemble(debugger, 2)
      assert_true(disasm.contains("Disassembly"))
      assert_true(disasm.contains("=>"))  // Current position marker
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Debug summary test
test "debugger: summary" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      let summary = debug_summary(debugger)
      assert_true(summary.contains("Debug Summary"))
      assert_true(summary.contains("Location"))
      assert_true(summary.contains("Disassembly"))
      assert_true(summary.contains("Stack"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Execution history test
test "debugger: execution history" {
  let expr = parse_one("(+ 1 2)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)

      // Add top level frame
      let initial_frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 0,
        base_ptr: 0,
        num_locals: 0,
      }
      vm.call_stack.push(initial_frame)

      let debugger = new_debugger(vm)

      // Execute several steps (continue even if it fails)
      let mut step_count = 0
      while step_count < 10 {
        match debug_step(debugger) {
          Ok(DebugEvent::StepComplete) => step_count = step_count + 1
          _ => break
        }
      }

      // Make sure history is recorded (at least one)
      assert_true(debugger.execution_history.length() >= 1)

      let history_str = debug_history_to_string(debugger, 5)
      assert_true(history_str.contains("History"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Global variable display test
test "debugger: globals display" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      // Add user-defined global
      vm.globals.set("my-var", Value::Number(Number::Int(123)))

      let globals_str = debug_globals_to_string(debugger)
      assert_true(globals_str.contains("my-var"))
      assert_true(globals_str.contains("123"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Local variable display test
test "debugger: locals display" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      // Without frame
      let no_frame_str = debug_locals_to_string(debugger)
      assert_true(no_frame_str.contains("no active frame"))

      // Add a frame and set local variables
      vm.stack.push(Value::Number(Number::Int(10)))
      vm.stack.push(Value::Number(Number::Int(20)))

      let frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 0,
        base_ptr: 0,
        num_locals: 2,
      }
      vm.call_stack.push(frame)

      let locals_str = debug_locals_to_string(debugger)
      assert_true(locals_str.contains("10"))
      assert_true(locals_str.contains("20"))
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Testing with debugger disabled
test "debugger: disabled" {
  let expr = parse_one("42")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)
      let debugger = new_debugger(vm)

      debugger.enabled = false

      match debug_step(debugger) {
        Err(VMError::RuntimeError(msg)) => assert_true(msg.contains("disabled"))
        _ => fail("Expected error when debugger is disabled")
      }
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}

/// Stepping tests on complex expressions
test "debugger: step through lambda" {
  let expr = parse_one("((lambda (x) (+ x 1)) 5)")
  match compile_to_module(expr) {
    Ok(compiled) => {
      let vm = new_vm_state(compiled)

      // Add top level frame
      let initial_frame : VMCallFrame = {
        return_chunk: -1,
        return_ip: 0,
        base_ptr: 0,
        num_locals: 0,
      }
      vm.call_stack.push(initial_frame)

      let debugger = new_debugger(vm)

      // run to the end
      match debug_run(debugger) {
        Ok(result) => {
          match result {
            Value::Number(Number::Int(n)) => assert_eq(n, 6)
            _ => fail("Expected number 6")
          }
        }
        Err(e) => fail("Run failed: " + e.to_string())
      }
    }
    Err(e) => fail("Compile failed: " + e.to_string())
  }
}
