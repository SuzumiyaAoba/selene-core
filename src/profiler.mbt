/// profiler
///
/// Measure VM execution performance:
/// - Number of instruction executions
/// - Function call statistics
/// - Memory allocation statistics
/// - Hotspot analysis

/// instruction statistics
pub(all) struct InstructionStats {
  /// instruction name
  name : String
  /// Number of executions
  mut count : Int64
}

/// function statistics
pub(all) struct FunctionStats {
  /// Chunk index (-1 is main)
  chunk_idx : Int
  /// Function name (debug_name or auto-generated)
  name : String
  /// Number of calls
  mut call_count : Int64
  /// Total number of instruction executions
  mut instruction_count : Int64
}

/// profiler state
pub(all) struct Profiler {
  /// Statistics by instruction type
  instruction_stats : @hashmap.T[String, InstructionStats]
  /// Statistics per function
  function_stats : @hashmap.T[Int, FunctionStats]
  /// Total number of instruction executions
  mut total_instructions : Int64
  /// Total number of function calls
  mut total_calls : Int64
  /// Whether profiling is enabled
  mut enabled : Bool
  /// Current call stack (for function statistics)
  call_stack : Array[Int]
  /// Statistics snapshot when GC starts
  mut gc_start_allocations : Int
}

/// Create a new profiler
pub fn new_profiler() -> Profiler {
  {
    instruction_stats: @hashmap.new(),
    function_stats: @hashmap.new(),
    total_instructions: 0L,
    total_calls: 0L,
    enabled: true,
    call_stack: [],
    gc_start_allocations: 0,
  }
}

/// Reset profiler
pub fn profiler_reset(profiler : Profiler) -> Unit {
  profiler.instruction_stats.clear()
  profiler.function_stats.clear()
  profiler.total_instructions = 0L
  profiler.total_calls = 0L
  profiler.call_stack.clear()
  profiler.gc_start_allocations = 0
}

/// Enable profiling
pub fn profiler_enable(profiler : Profiler) -> Unit {
  profiler.enabled = true
}

/// Disable profiling
pub fn profiler_disable(profiler : Profiler) -> Unit {
  profiler.enabled = false
}

/// Record instruction execution
pub fn profiler_record_instruction(profiler : Profiler, opcode : Opcode) -> Unit {
  if not(profiler.enabled) {
    return
  }

  profiler.total_instructions = profiler.total_instructions + 1L

  let name = opcode_to_name(opcode)

  match profiler.instruction_stats.get(name) {
    Some(stats) => stats.count = stats.count + 1L
    None => {
      let stats : InstructionStats = { name, count: 1L }
      profiler.instruction_stats.set(name, stats)
    }
  }

  // Also updates the instruction count of the current function
  if profiler.call_stack.length() > 0 {
    let current_chunk = profiler.call_stack[profiler.call_stack.length() - 1]
    match profiler.function_stats.get(current_chunk) {
      Some(stats) => stats.instruction_count = stats.instruction_count + 1L
      None => ()
    }
  }
}

/// Record function calls
pub fn profiler_record_call(
  profiler : Profiler,
  chunk_idx : Int,
  debug_name : String?
) -> Unit {
  if not(profiler.enabled) {
    return
  }

  profiler.total_calls = profiler.total_calls + 1L
  profiler.call_stack.push(chunk_idx)

  match profiler.function_stats.get(chunk_idx) {
    Some(stats) => stats.call_count = stats.call_count + 1L
    None => {
      let name = match debug_name {
        Some(n) => n
        None =>
          if chunk_idx < 0 { "main" } else { "lambda@" + chunk_idx.to_string() }
      }
      let stats : FunctionStats = {
        chunk_idx,
        name,
        call_count: 1L,
        instruction_count: 0L,
      }
      profiler.function_stats.set(chunk_idx, stats)
    }
  }
}

/// Record function return
pub fn profiler_record_return(profiler : Profiler) -> Unit {
  if not(profiler.enabled) {
    return
  }

  if profiler.call_stack.length() > 0 {
    let _ = profiler.call_stack.pop()
  }
}

/// Convert opcode to name
fn opcode_to_name(opcode : Opcode) -> String {
  match opcode {
    Opcode::Push(_) => "Push"
    Opcode::Pop => "Pop"
    Opcode::LoadLocal(_, _) => "LoadLocal"
    Opcode::StoreLocal(_, _) => "StoreLocal"
    Opcode::LoadGlobal(_) => "LoadGlobal"
    Opcode::StoreGlobal(_) => "StoreGlobal"
    Opcode::MakeClosure(_, _) => "MakeClosure"
    Opcode::MakeBox => "MakeBox"
    Opcode::BoxGet => "BoxGet"
    Opcode::BoxSet => "BoxSet"
    Opcode::Call(_) => "Call"
    Opcode::TailCall(_) => "TailCall"
    Opcode::Return => "Return"
    Opcode::Jump(_) => "Jump"
    Opcode::JumpIfFalse(_) => "JumpIfFalse"
    Opcode::PrimCall(_, _) => "PrimCall"
    Opcode::CaptureCC => "CaptureCC"
    Opcode::Halt => "Halt"
    Opcode::MakePair => "MakePair"
    Opcode::MakeList(_) => "MakeList"
    Opcode::MakeVector(_) => "MakeVector"
    Opcode::MakePromise(_) => "MakePromise"
    Opcode::AndJump(_) => "AndJump"
    Opcode::OrJump(_) => "OrJump"
    Opcode::Dup => "Dup"
    Opcode::AllocateLocals(_) => "AllocateLocals"
    Opcode::InitLocal(_, _) => "InitLocal"
  }
}

/// Generate a report of instruction statistics
pub fn profiler_instruction_report(profiler : Profiler) -> String {
  if profiler.total_instructions == 0L {
    return "No instructions executed."
  }

  let mut result = "=== Instruction Statistics ===\n\n"
  result = result + "Total instructions: " + profiler.total_instructions.to_string() + "\n\n"

  // Collect and sort statistics into an array
  let stats_list : Array[(String, Int64)] = []
  profiler.instruction_stats.each(fn(name, stats) {
    stats_list.push((name, stats.count))
  })

  // Sort by number of executions (descending order)
  sort_stats_descending(stats_list)

  result = result + "By instruction type:\n"
  result = result + "----------------------------------------\n"
  result = result + pad_right("Instruction", 20) + pad_right("Count", 15) + "Percentage\n"
  result = result + "----------------------------------------\n"

  for entry in stats_list {
    let (name, count) = entry
    let percentage = (count.to_double() / profiler.total_instructions.to_double()) * 100.0
    result = result + pad_right(name, 20) +
      pad_right(count.to_string(), 15) +
      format_percentage(percentage) + "\n"
  }

  result
}

/// Generate a report of function statistics
pub fn profiler_function_report(profiler : Profiler) -> String {
  if profiler.total_calls == 0L {
    return "No function calls recorded."
  }

  let mut result = "=== Function Statistics ===\n\n"
  result = result + "Total calls: " + profiler.total_calls.to_string() + "\n\n"

  // Collect statistics into array
  let stats_list : Array[(String, Int64, Int64)] = []
  profiler.function_stats.each(fn(_idx, stats) {
    stats_list.push((stats.name, stats.call_count, stats.instruction_count))
  })

  // Sort by number of calls (descending order)
  sort_function_stats_descending(stats_list)

  result = result + "By function:\n"
  result = result + "------------------------------------------------------------\n"
  result = result + pad_right("Function", 25) +
    pad_right("Calls", 12) +
    pad_right("Instructions", 15) +
    "Avg Instr/Call\n"
  result = result + "------------------------------------------------------------\n"

  for entry in stats_list {
    let (name, calls, instructions) = entry
    let avg = if calls > 0L {
      instructions.to_double() / calls.to_double()
    } else {
      0.0
    }
    result = result + pad_right(truncate_string(name, 24), 25) +
      pad_right(calls.to_string(), 12) +
      pad_right(instructions.to_string(), 15) +
      format_double(avg, 2) + "\n"
  }

  result
}

/// Generate hotspot analysis report
pub fn profiler_hotspot_report(profiler : Profiler, top_n : Int) -> String {
  let mut result = "=== Hotspot Analysis (Top " + top_n.to_string() + ") ===\n\n"

  // instruction hotspot
  result = result + "Most executed instruction types:\n"
  let instr_list : Array[(String, Int64)] = []
  profiler.instruction_stats.each(fn(name, stats) {
    instr_list.push((name, stats.count))
  })
  sort_stats_descending(instr_list)

  let instr_count = if top_n < instr_list.length() { top_n } else { instr_list.length() }
  let mut i = 0
  while i < instr_count {
    let (name, count) = instr_list[i]
    let percentage = (count.to_double() / profiler.total_instructions.to_double()) * 100.0
    result = result + "  " + (i + 1).to_string() + ". " + name + ": " +
      count.to_string() + " (" + format_percentage(percentage) + ")\n"
    i = i + 1
  }

  result = result + "\n"

  // function hotspot
  result = result + "Most called functions:\n"
  let func_list : Array[(String, Int64, Int64)] = []
  profiler.function_stats.each(fn(_idx, stats) {
    func_list.push((stats.name, stats.call_count, stats.instruction_count))
  })
  sort_function_stats_descending(func_list)

  let func_count = if top_n < func_list.length() { top_n } else { func_list.length() }
  let mut j = 0
  while j < func_count {
    let (name, calls, _) = func_list[j]
    let percentage = (calls.to_double() / profiler.total_calls.to_double()) * 100.0
    result = result + "  " + (j + 1).to_string() + ". " + name + ": " +
      calls.to_string() + " calls (" + format_percentage(percentage) + ")\n"
    j = j + 1
  }

  result
}

/// Generate summary report
pub fn profiler_summary(profiler : Profiler) -> String {
  let mut result = "=== Profiler Summary ===\n\n"

  result = result + "Total instructions executed: " + profiler.total_instructions.to_string() + "\n"
  result = result + "Total function calls: " + profiler.total_calls.to_string() + "\n"
  result = result + "Unique instruction types: " + count_hashmap_entries(profiler.instruction_stats).to_string() + "\n"
  result = result + "Unique functions called: " + count_hashmap_entries_int(profiler.function_stats).to_string() + "\n"

  // Cooperation with GC statistics
  let gc_stats = get_gc_stats()
  result = result + "\nMemory allocations (from GC):\n"
  result = result + "  Closures: " + gc_stats.closures_allocated.to_string() + "\n"
  result = result + "  Pairs: " + gc_stats.pairs_allocated.to_string() + "\n"
  result = result + "  Vectors: " + gc_stats.vectors_allocated.to_string() + "\n"
  result = result + "  Boxes: " + gc_stats.boxes_allocated.to_string() + "\n"
  result = result + "  Continuations: " + gc_stats.continuations_allocated.to_string() + "\n"

  result
}

/// Generate complete report
pub fn profiler_full_report(profiler : Profiler) -> String {
  let mut result = profiler_summary(profiler) + "\n"
  result = result + profiler_instruction_report(profiler) + "\n"
  result = result + profiler_function_report(profiler) + "\n"
  result = result + profiler_hotspot_report(profiler, 5)
  result
}

/// Count the number of entries in HashMap
fn count_hashmap_entries(map : @hashmap.T[String, InstructionStats]) -> Int {
  let mut count = 0
  map.each(fn(_k, _v) { count = count + 1 })
  count
}

/// Count the number of entries in HashMap (Int key)
fn count_hashmap_entries_int(map : @hashmap.T[Int, FunctionStats]) -> Int {
  let mut count = 0
  map.each(fn(_k, _v) { count = count + 1 })
  count
}

/// Sort statistics in descending order
fn sort_stats_descending(list : Array[(String, Int64)]) -> Unit {
  // simple bubble sort
  let n = list.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if list[j].1 < list[j + 1].1 {
        let temp = list[j]
        list[j] = list[j + 1]
        list[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
}

/// Sort function statistics in descending order (sort by number of calls)
fn sort_function_stats_descending(list : Array[(String, Int64, Int64)]) -> Unit {
  let n = list.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if list[j].1 < list[j + 1].1 {
        let temp = list[j]
        list[j] = list[j + 1]
        list[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
}

/// right padding string
fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let mut result = s
  let mut i = 0
  while i < width - len {
    result = result + " "
    i = i + 1
  }
  result
}

/// truncate string
fn truncate_string(s : String, max_len : Int) -> String {
  if s.length() <= max_len {
    return s
  }
  let mut result = ""
  let chars = s.to_array()
  let mut i = 0
  while i < max_len - 3 {
    result = result + chars[i].to_string()
    i = i + 1
  }
  result + "..."
}

/// format percentage
fn format_percentage(p : Double) -> String {
  format_double(p, 1) + "%"
}

/// format decimal
fn format_double(d : Double, decimals : Int) -> String {
  let int_part = d.to_int()
  let frac = d - int_part.to_double()
  let multiplier = pow10(decimals)
  let frac_int = (frac * multiplier.to_double()).to_int()
  int_part.to_string() + "." + pad_left_zero(frac_int, decimals)
}

/// power of 10
fn pow10(n : Int) -> Int {
  let mut result = 1
  let mut i = 0
  while i < n {
    result = result * 10
    i = i + 1
  }
  result
}

/// Zero-filled left padding
fn pad_left_zero(n : Int, width : Int) -> String {
  let s = n.to_string()
  let len = s.length()
  if len >= width {
    return s
  }
  let mut result = ""
  let mut i = 0
  while i < width - len {
    result = result + "0"
    i = i + 1
  }
  result + s
}

/// Run VM with profiling
pub fn vm_run_with_profiler(
  vm : VMState,
  profiler : Profiler
) -> Result[Value, VMError] {
  // Add top level frame
  let initial_frame : VMCallFrame = {
    return_chunk: -1,
    return_ip: 0,
    base_ptr: 0,
    num_locals: 0,
  }
  vm.call_stack.push(initial_frame)

  // Record main function call
  profiler_record_call(profiler, -1, Some("main"))

  while true {
    let chunk = if vm.current_chunk < 0 {
      vm.compiled_module.main
    } else {
      vm.compiled_module.chunks[vm.current_chunk]
    }

    if vm.ip >= chunk.code.length() {
      break
    }

    let opcode = chunk.code[vm.ip]

    // Profile recording before instruction execution
    profiler_record_instruction(profiler, opcode)

    // For Call/TailCall, function calls are also recorded.
    match opcode {
      Opcode::Call(_) | Opcode::TailCall(_) => {
        // Function calls are recorded after vm_step (after the call destination is determined)
        ()
      }
      Opcode::Return => {
        profiler_record_return(profiler)
      }
      _ => ()
    }

    match vm_step(vm) {
      Ok(true) => {
        // Record function call if chunk changes after Call
        match opcode {
          Opcode::Call(_) | Opcode::TailCall(_) => {
            let new_chunk_idx = vm.current_chunk
            let debug_name = if new_chunk_idx < 0 {
              Some("main")
            } else {
              vm.compiled_module.chunks[new_chunk_idx].debug_name
            }
            profiler_record_call(profiler, new_chunk_idx, debug_name)
          }
          _ => ()
        }
        continue
      }
      Ok(false) => break
      Err(e) => return Err(e)
    }
  }

  profiler_record_return(profiler)  // main function return

  if vm.stack.length() > 0 {
    Ok(vm.stack[vm.stack.length() - 1])
  } else {
    Ok(Value::Nil)
  }
}

/// Evaluate S-expression with profiling
pub fn vm_eval_with_profiler(
  expr : SExpr,
  profiler : Profiler
) -> Result[Value, String] {
  match compile_to_module(expr) {
    Ok(compiled_module) => {
      let vm = new_vm_state(compiled_module)
      match vm_run_with_profiler(vm, profiler) {
        Ok(v) => Ok(v)
        Err(e) => Err(e.to_string())
      }
    }
    Err(e) => Err(e.to_string())
  }
}
