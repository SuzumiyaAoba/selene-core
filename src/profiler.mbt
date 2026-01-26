/// プロファイラ
///
/// VM の実行パフォーマンスを計測する:
/// - 命令実行回数
/// - 関数呼び出し統計
/// - メモリアロケーション統計
/// - ホットスポット分析

/// 命令統計
pub(all) struct InstructionStats {
  /// 命令名
  name : String
  /// 実行回数
  mut count : Int64
}

/// 関数統計
pub(all) struct FunctionStats {
  /// チャンクインデックス（-1 はメイン）
  chunk_idx : Int
  /// 関数名（debug_name または自動生成）
  name : String
  /// 呼び出し回数
  mut call_count : Int64
  /// 総命令実行回数
  mut instruction_count : Int64
}

/// プロファイラ状態
pub(all) struct Profiler {
  /// 命令種別ごとの統計
  instruction_stats : @hashmap.T[String, InstructionStats]
  /// 関数ごとの統計
  function_stats : @hashmap.T[Int, FunctionStats]
  /// 総命令実行回数
  mut total_instructions : Int64
  /// 総関数呼び出し回数
  mut total_calls : Int64
  /// プロファイリングが有効かどうか
  mut enabled : Bool
  /// 現在のコールスタック（関数統計用）
  call_stack : Array[Int]
  /// GC 開始時の統計スナップショット
  mut gc_start_allocations : Int
}

/// 新しいプロファイラを作成
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

/// プロファイラをリセット
pub fn profiler_reset(profiler : Profiler) -> Unit {
  profiler.instruction_stats.clear()
  profiler.function_stats.clear()
  profiler.total_instructions = 0L
  profiler.total_calls = 0L
  profiler.call_stack.clear()
  profiler.gc_start_allocations = 0
}

/// プロファイリングを有効化
pub fn profiler_enable(profiler : Profiler) -> Unit {
  profiler.enabled = true
}

/// プロファイリングを無効化
pub fn profiler_disable(profiler : Profiler) -> Unit {
  profiler.enabled = false
}

/// 命令実行を記録
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

  // 現在の関数の命令カウントも更新
  if profiler.call_stack.length() > 0 {
    let current_chunk = profiler.call_stack[profiler.call_stack.length() - 1]
    match profiler.function_stats.get(current_chunk) {
      Some(stats) => stats.instruction_count = stats.instruction_count + 1L
      None => ()
    }
  }
}

/// 関数呼び出しを記録
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

/// 関数リターンを記録
pub fn profiler_record_return(profiler : Profiler) -> Unit {
  if not(profiler.enabled) {
    return
  }

  if profiler.call_stack.length() > 0 {
    let _ = profiler.call_stack.pop()
  }
}

/// オペコードを名前に変換
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

/// 命令統計のレポートを生成
pub fn profiler_instruction_report(profiler : Profiler) -> String {
  if profiler.total_instructions == 0L {
    return "No instructions executed."
  }

  let mut result = "=== Instruction Statistics ===\n\n"
  result = result + "Total instructions: " + profiler.total_instructions.to_string() + "\n\n"

  // 統計を配列に収集してソート
  let stats_list : Array[(String, Int64)] = []
  profiler.instruction_stats.each(fn(name, stats) {
    stats_list.push((name, stats.count))
  })

  // 実行回数でソート（降順）
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

/// 関数統計のレポートを生成
pub fn profiler_function_report(profiler : Profiler) -> String {
  if profiler.total_calls == 0L {
    return "No function calls recorded."
  }

  let mut result = "=== Function Statistics ===\n\n"
  result = result + "Total calls: " + profiler.total_calls.to_string() + "\n\n"

  // 統計を配列に収集
  let stats_list : Array[(String, Int64, Int64)] = []
  profiler.function_stats.each(fn(_idx, stats) {
    stats_list.push((stats.name, stats.call_count, stats.instruction_count))
  })

  // 呼び出し回数でソート（降順）
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

/// ホットスポット分析レポートを生成
pub fn profiler_hotspot_report(profiler : Profiler, top_n : Int) -> String {
  let mut result = "=== Hotspot Analysis (Top " + top_n.to_string() + ") ===\n\n"

  // 命令ホットスポット
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

  // 関数ホットスポット
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

/// サマリーレポートを生成
pub fn profiler_summary(profiler : Profiler) -> String {
  let mut result = "=== Profiler Summary ===\n\n"

  result = result + "Total instructions executed: " + profiler.total_instructions.to_string() + "\n"
  result = result + "Total function calls: " + profiler.total_calls.to_string() + "\n"
  result = result + "Unique instruction types: " + count_hashmap_entries(profiler.instruction_stats).to_string() + "\n"
  result = result + "Unique functions called: " + count_hashmap_entries_int(profiler.function_stats).to_string() + "\n"

  // GC統計との連携
  let gc_stats = get_gc_stats()
  result = result + "\nMemory allocations (from GC):\n"
  result = result + "  Closures: " + gc_stats.closures_allocated.to_string() + "\n"
  result = result + "  Pairs: " + gc_stats.pairs_allocated.to_string() + "\n"
  result = result + "  Vectors: " + gc_stats.vectors_allocated.to_string() + "\n"
  result = result + "  Boxes: " + gc_stats.boxes_allocated.to_string() + "\n"
  result = result + "  Continuations: " + gc_stats.continuations_allocated.to_string() + "\n"

  result
}

/// 完全なレポートを生成
pub fn profiler_full_report(profiler : Profiler) -> String {
  let mut result = profiler_summary(profiler) + "\n"
  result = result + profiler_instruction_report(profiler) + "\n"
  result = result + profiler_function_report(profiler) + "\n"
  result = result + profiler_hotspot_report(profiler, 5)
  result
}

/// HashMap のエントリ数をカウント
fn count_hashmap_entries(map : @hashmap.T[String, InstructionStats]) -> Int {
  let mut count = 0
  map.each(fn(_k, _v) { count = count + 1 })
  count
}

/// HashMap のエントリ数をカウント（Int キー）
fn count_hashmap_entries_int(map : @hashmap.T[Int, FunctionStats]) -> Int {
  let mut count = 0
  map.each(fn(_k, _v) { count = count + 1 })
  count
}

/// 統計を降順ソート
fn sort_stats_descending(list : Array[(String, Int64)]) -> Unit {
  // 単純なバブルソート
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

/// 関数統計を降順ソート（呼び出し回数でソート）
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

/// 文字列を右パディング
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

/// 文字列を切り詰め
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

/// パーセンテージをフォーマット
fn format_percentage(p : Double) -> String {
  format_double(p, 1) + "%"
}

/// 小数をフォーマット
fn format_double(d : Double, decimals : Int) -> String {
  let int_part = d.to_int()
  let frac = d - int_part.to_double()
  let multiplier = pow10(decimals)
  let frac_int = (frac * multiplier.to_double()).to_int()
  int_part.to_string() + "." + pad_left_zero(frac_int, decimals)
}

/// 10のべき乗
fn pow10(n : Int) -> Int {
  let mut result = 1
  let mut i = 0
  while i < n {
    result = result * 10
    i = i + 1
  }
  result
}

/// ゼロ埋め左パディング
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

/// プロファイリング付きで VM を実行
pub fn vm_run_with_profiler(
  vm : VMState,
  profiler : Profiler
) -> Result[Value, VMError] {
  // トップレベルフレームを追加
  let initial_frame : VMCallFrame = {
    return_chunk: -1,
    return_ip: 0,
    base_ptr: 0,
    num_locals: 0,
  }
  vm.call_stack.push(initial_frame)

  // メイン関数の呼び出しを記録
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

    // 命令実行前にプロファイル記録
    profiler_record_instruction(profiler, opcode)

    // Call/TailCall の場合は関数呼び出しも記録
    match opcode {
      Opcode::Call(_) | Opcode::TailCall(_) => {
        // 関数呼び出しは vm_step 後に記録（呼び出し先が確定してから）
        ()
      }
      Opcode::Return => {
        profiler_record_return(profiler)
      }
      _ => ()
    }

    match vm_step(vm) {
      Ok(true) => {
        // Call 後にチャンクが変わった場合は関数呼び出しを記録
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

  profiler_record_return(profiler)  // メイン関数のリターン

  if vm.stack.length() > 0 {
    Ok(vm.stack[vm.stack.length() - 1])
  } else {
    Ok(Value::Nil)
  }
}

/// S 式をプロファイリング付きで評価
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
