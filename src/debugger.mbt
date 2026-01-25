/// デバッガ
///
/// VM のデバッグ機能を提供する:
/// - ブレークポイントの設定/解除
/// - ステップ実行
/// - 状態検査（スタック、変数、コールスタック）
/// - コード表示

/// ブレークポイント
pub(all) struct Breakpoint {
  /// ブレークポイントID
  id : Int
  /// チャンクインデックス（-1 はメインチャンク）
  chunk_idx : Int
  /// 命令アドレス
  address : Int
  /// 有効かどうか
  mut enabled : Bool
  /// ヒット回数
  mut hit_count : Int
}

/// デバッグイベント
pub(all) enum DebugEvent {
  /// ブレークポイントにヒット
  BreakpointHit(Int)  // ブレークポイントID
  /// ステップ完了
  StepComplete
  /// 実行完了
  ExecutionComplete(Value)
  /// エラー発生
  Error(VMError)
}

/// デバッガ状態
pub(all) struct Debugger {
  /// VM 状態への参照
  vm : VMState
  /// ブレークポイントリスト
  breakpoints : Array[Breakpoint]
  /// 次のブレークポイントID
  mut next_bp_id : Int
  /// ステップモード
  mut step_mode : StepMode
  /// ステップ時の開始コールスタック深さ
  mut step_start_depth : Int
  /// デバッグが有効かどうか
  mut enabled : Bool
  /// 実行履歴（最近の命令）
  execution_history : Array[ExecutionRecord]
  /// 履歴の最大長
  history_max_length : Int
}

/// ステップモード
pub(all) enum StepMode {
  /// ステップなし（通常実行）
  None
  /// 1命令ステップ
  StepInto
  /// 関数呼び出しをスキップ
  StepOver
  /// 現在の関数から出るまで実行
  StepOut
}

/// 実行記録
pub(all) struct ExecutionRecord {
  /// チャンクインデックス
  chunk_idx : Int
  /// 命令アドレス
  address : Int
  /// 実行された命令
  opcode : String
  /// スタックの深さ
  stack_depth : Int
}

/// 新しいデバッガを作成
pub fn new_debugger(vm : VMState) -> Debugger {
  {
    vm,
    breakpoints: [],
    next_bp_id: 1,
    step_mode: StepMode::None,
    step_start_depth: 0,
    enabled: true,
    execution_history: [],
    history_max_length: 100,
  }
}

/// ブレークポイントを追加
pub fn add_breakpoint(
  debugger : Debugger,
  chunk_idx : Int,
  address : Int
) -> Int {
  let bp : Breakpoint = {
    id: debugger.next_bp_id,
    chunk_idx,
    address,
    enabled: true,
    hit_count: 0,
  }
  debugger.breakpoints.push(bp)
  debugger.next_bp_id = debugger.next_bp_id + 1
  bp.id
}

/// メインチャンクにブレークポイントを追加
pub fn add_breakpoint_main(debugger : Debugger, address : Int) -> Int {
  add_breakpoint(debugger, -1, address)
}

/// ブレークポイントを削除
pub fn remove_breakpoint(debugger : Debugger, bp_id : Int) -> Bool {
  let new_bps : Array[Breakpoint] = []
  let mut found = false
  for bp in debugger.breakpoints {
    if bp.id == bp_id {
      found = true
    } else {
      new_bps.push(bp)
    }
  }
  debugger.breakpoints.clear()
  for bp in new_bps {
    debugger.breakpoints.push(bp)
  }
  found
}

/// ブレークポイントを有効化
pub fn enable_breakpoint(debugger : Debugger, bp_id : Int) -> Bool {
  for bp in debugger.breakpoints {
    if bp.id == bp_id {
      bp.enabled = true
      return true
    }
  }
  false
}

/// ブレークポイントを無効化
pub fn disable_breakpoint(debugger : Debugger, bp_id : Int) -> Bool {
  for bp in debugger.breakpoints {
    if bp.id == bp_id {
      bp.enabled = false
      return true
    }
  }
  false
}

/// 全てのブレークポイントをクリア
pub fn clear_breakpoints(debugger : Debugger) -> Unit {
  debugger.breakpoints.clear()
}

/// ブレークポイント一覧を取得
pub fn list_breakpoints(debugger : Debugger) -> Array[Breakpoint] {
  debugger.breakpoints
}

/// 現在の位置にブレークポイントがあるかチェック
fn check_breakpoint(debugger : Debugger) -> Int? {
  let chunk_idx = debugger.vm.current_chunk
  let address = debugger.vm.ip

  for bp in debugger.breakpoints {
    if bp.enabled && bp.chunk_idx == chunk_idx && bp.address == address {
      bp.hit_count = bp.hit_count + 1
      return Some(bp.id)
    }
  }
  None
}

/// 現在のコードチャンクを取得
fn debugger_get_current_chunk(debugger : Debugger) -> CodeChunk {
  if debugger.vm.current_chunk < 0 {
    debugger.vm.compiled_module.main
  } else {
    debugger.vm.compiled_module.chunks[debugger.vm.current_chunk]
  }
}

/// 1命令ステップ実行
pub fn debug_step(debugger : Debugger) -> Result[DebugEvent, VMError] {
  if not(debugger.enabled) {
    return Err(VMError::RuntimeError("Debugger is disabled"))
  }

  let chunk = debugger_get_current_chunk(debugger)
  if debugger.vm.ip >= chunk.code.length() {
    return Ok(DebugEvent::ExecutionComplete(Value::Nil))
  }

  // 実行前の状態を記録
  let record : ExecutionRecord = {
    chunk_idx: debugger.vm.current_chunk,
    address: debugger.vm.ip,
    opcode: chunk.code[debugger.vm.ip].to_string(),
    stack_depth: debugger.vm.stack.length(),
  }

  // 履歴に追加
  debugger.execution_history.push(record)
  if debugger.execution_history.length() > debugger.history_max_length {
    // 古い履歴を削除
    let new_history : Array[ExecutionRecord] = []
    let mut i = 1
    while i < debugger.execution_history.length() {
      new_history.push(debugger.execution_history[i])
      i = i + 1
    }
    debugger.execution_history.clear()
    for h in new_history {
      debugger.execution_history.push(h)
    }
  }

  // 1命令実行
  match vm_step(debugger.vm) {
    Ok(true) => Ok(DebugEvent::StepComplete)
    Ok(false) => {
      if debugger.vm.stack.length() > 0 {
        Ok(DebugEvent::ExecutionComplete(debugger.vm.stack[debugger.vm.stack.length() - 1]))
      } else {
        Ok(DebugEvent::ExecutionComplete(Value::Nil))
      }
    }
    Err(e) => Err(e)
  }
}

/// 次のブレークポイントまで実行
pub fn debug_continue(debugger : Debugger) -> Result[DebugEvent, VMError] {
  if not(debugger.enabled) {
    return Err(VMError::RuntimeError("Debugger is disabled"))
  }

  debugger.step_mode = StepMode::None

  while true {
    // ブレークポイントチェック
    match check_breakpoint(debugger) {
      Some(bp_id) => return Ok(DebugEvent::BreakpointHit(bp_id))
      None => ()
    }

    // 1命令実行
    match debug_step(debugger) {
      Ok(DebugEvent::StepComplete) => continue
      Ok(event) => return Ok(event)
      Err(e) => return Err(e)
    }
  }

  Ok(DebugEvent::ExecutionComplete(Value::Nil))
}

/// step into: 1命令実行（関数呼び出しも入る）
pub fn debug_step_into(debugger : Debugger) -> Result[DebugEvent, VMError] {
  debugger.step_mode = StepMode::StepInto
  debug_step(debugger)
}

/// step over: 関数呼び出しをスキップして次の命令へ
pub fn debug_step_over(debugger : Debugger) -> Result[DebugEvent, VMError] {
  if not(debugger.enabled) {
    return Err(VMError::RuntimeError("Debugger is disabled"))
  }

  let start_depth = debugger.vm.call_stack.length()
  debugger.step_mode = StepMode::StepOver
  debugger.step_start_depth = start_depth

  // 最初の1命令を実行
  match debug_step(debugger) {
    Ok(DebugEvent::StepComplete) => ()
    Ok(event) => return Ok(event)
    Err(e) => return Err(e)
  }

  // コールスタックの深さが開始時以下になるまで実行
  while debugger.vm.call_stack.length() > start_depth {
    match debug_step(debugger) {
      Ok(DebugEvent::StepComplete) => continue
      Ok(event) => return Ok(event)
      Err(e) => return Err(e)
    }
  }

  debugger.step_mode = StepMode::None
  Ok(DebugEvent::StepComplete)
}

/// step out: 現在の関数から出るまで実行
pub fn debug_step_out(debugger : Debugger) -> Result[DebugEvent, VMError] {
  if not(debugger.enabled) {
    return Err(VMError::RuntimeError("Debugger is disabled"))
  }

  let start_depth = debugger.vm.call_stack.length()
  debugger.step_mode = StepMode::StepOut
  debugger.step_start_depth = start_depth

  // コールスタックの深さが開始時より小さくなるまで実行
  while debugger.vm.call_stack.length() >= start_depth {
    match debug_step(debugger) {
      Ok(DebugEvent::StepComplete) => continue
      Ok(event) => return Ok(event)
      Err(e) => return Err(e)
    }
  }

  debugger.step_mode = StepMode::None
  Ok(DebugEvent::StepComplete)
}

/// 最後まで実行
pub fn debug_run(debugger : Debugger) -> Result[Value, VMError] {
  if not(debugger.enabled) {
    return Err(VMError::RuntimeError("Debugger is disabled"))
  }

  debugger.step_mode = StepMode::None

  while true {
    match debug_step(debugger) {
      Ok(DebugEvent::StepComplete) => continue
      Ok(DebugEvent::ExecutionComplete(v)) => return Ok(v)
      Ok(DebugEvent::BreakpointHit(_)) => continue  // ブレークポイントを無視
      Ok(DebugEvent::Error(e)) => return Err(e)
      Err(e) => return Err(e)
    }
  }

  Ok(Value::Nil)
}

/// 現在のスタック状態を取得
pub fn debug_get_stack(debugger : Debugger) -> Array[Value] {
  let result : Array[Value] = []
  for v in debugger.vm.stack {
    result.push(v)
  }
  result
}

/// スタックの文字列表現を取得
pub fn debug_stack_to_string(debugger : Debugger) -> String {
  let stack = debugger.vm.stack
  if stack.length() == 0 {
    return "Stack: (empty)"
  }

  let mut result = "Stack (top to bottom):\n"
  let mut i = stack.length() - 1
  while i >= 0 {
    result = result + "  [" + i.to_string() + "] " + debug_value_to_string(stack[i]) + "\n"
    i = i - 1
  }
  result
}

/// コールスタックを取得
pub fn debug_get_call_stack(debugger : Debugger) -> Array[VMCallFrame] {
  let result : Array[VMCallFrame] = []
  for f in debugger.vm.call_stack {
    result.push(f)
  }
  result
}

/// コールスタックの文字列表現を取得
pub fn debug_call_stack_to_string(debugger : Debugger) -> String {
  let call_stack = debugger.vm.call_stack
  if call_stack.length() == 0 {
    return "Call Stack: (empty)"
  }

  let mut result = "Call Stack:\n"
  let mut i = call_stack.length() - 1
  while i >= 0 {
    let frame = call_stack[i]
    let chunk_name = if frame.return_chunk < 0 {
      "main"
    } else {
      let chunk = debugger.vm.compiled_module.chunks[frame.return_chunk]
      match chunk.debug_name {
        Some(name) => name
        None => "lambda@" + frame.return_chunk.to_string()
      }
    }
    result = result + "  [" + i.to_string() + "] " + chunk_name +
      " (return_ip=" + frame.return_ip.to_string() +
      ", base_ptr=" + frame.base_ptr.to_string() + ")\n"
    i = i - 1
  }
  result
}

/// 現在の位置情報を取得
pub fn debug_get_location(debugger : Debugger) -> String {
  let chunk_idx = debugger.vm.current_chunk
  let ip = debugger.vm.ip
  let chunk = debugger_get_current_chunk(debugger)

  let chunk_name = if chunk_idx < 0 {
    "main"
  } else {
    match chunk.debug_name {
      Some(name) => name
      None => "chunk@" + chunk_idx.to_string()
    }
  }

  chunk_name + ":" + ip.to_string()
}

/// 現在の命令を取得
pub fn debug_get_current_instruction(debugger : Debugger) -> String? {
  let chunk = debugger_get_current_chunk(debugger)
  let ip = debugger.vm.ip

  if ip >= chunk.code.length() {
    return None
  }

  Some(chunk.code[ip].to_string())
}

/// 周辺のコードを表示
pub fn debug_disassemble(
  debugger : Debugger,
  context_lines : Int
) -> String {
  let chunk = debugger_get_current_chunk(debugger)
  let ip = debugger.vm.ip

  let start = if ip - context_lines < 0 { 0 } else { ip - context_lines }
  let end = if ip + context_lines >= chunk.code.length() {
    chunk.code.length()
  } else {
    ip + context_lines + 1
  }

  let mut result = "Disassembly:\n"
  let mut i = start
  while i < end {
    let marker = if i == ip { "=> " } else { "   " }
    result = result + marker + i.to_string().pad_start(4, ' ') + ": " +
      chunk.code[i].to_string() + "\n"
    i = i + 1
  }
  result
}

/// ローカル変数を表示
pub fn debug_locals_to_string(debugger : Debugger) -> String {
  if debugger.vm.call_stack.length() == 0 {
    return "Locals: (no active frame)"
  }

  let frame = debugger.vm.call_stack[debugger.vm.call_stack.length() - 1]
  let base = frame.base_ptr
  let num_locals = frame.num_locals

  if num_locals == 0 {
    return "Locals: (none)"
  }

  let mut result = "Locals:\n"
  let mut i = 0
  while i < num_locals && base + i < debugger.vm.stack.length() {
    let value = debugger.vm.stack[base + i]
    result = result + "  [" + i.to_string() + "] " + debug_value_to_string(value) + "\n"
    i = i + 1
  }
  result
}

/// グローバル変数を表示
pub fn debug_globals_to_string(debugger : Debugger) -> String {
  let mut result = "Globals:\n"
  let mut count = 0
  debugger.vm.globals.each(fn(name, value) {
    // ネイティブ関数は省略
    match value {
      Value::Procedure(Procedure::Native(_)) => ()
      _ => {
        result = result + "  " + name + " = " + debug_value_to_string(value) + "\n"
        count = count + 1
      }
    }
  })
  if count == 0 {
    return "Globals: (none defined)"
  }
  result
}

/// 実行履歴を表示
pub fn debug_history_to_string(debugger : Debugger, count : Int) -> String {
  let history = debugger.execution_history
  if history.length() == 0 {
    return "Execution History: (empty)"
  }

  let start = if history.length() - count < 0 { 0 } else { history.length() - count }

  let mut result = "Execution History (recent " + count.to_string() + "):\n"
  let mut i = start
  while i < history.length() {
    let record = history[i]
    let chunk_name = if record.chunk_idx < 0 { "main" } else { "chunk@" + record.chunk_idx.to_string() }
    result = result + "  " + chunk_name + ":" + record.address.to_string() +
      " " + record.opcode + " (stack=" + record.stack_depth.to_string() + ")\n"
    i = i + 1
  }
  result
}

/// デバッグ状態の全体サマリーを表示
pub fn debug_summary(debugger : Debugger) -> String {
  let mut result = "=== Debug Summary ===\n\n"

  // 位置情報
  result = result + "Location: " + debug_get_location(debugger) + "\n"
  match debug_get_current_instruction(debugger) {
    Some(instr) => result = result + "Current: " + instr + "\n"
    None => result = result + "Current: (end of code)\n"
  }
  result = result + "\n"

  // コード
  result = result + debug_disassemble(debugger, 3) + "\n"

  // スタック
  result = result + debug_stack_to_string(debugger) + "\n"

  // ローカル変数
  result = result + debug_locals_to_string(debugger) + "\n"

  // コールスタック
  result = result + debug_call_stack_to_string(debugger)

  result
}

/// Value を表示用の文字列に変換
fn debug_value_to_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(true) => "#t"
    Value::Bool(false) => "#f"
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Number(Number::Rational(n, d)) => n.to_string() + "/" + d.to_string()
    Value::Number(Number::Complex(r, i)) =>
      r.to_string() + (if i >= 0.0 { "+" } else { "" }) + i.to_string() + "i"
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""
    Value::Symbol(s) => s
    Value::Pair(_, _) => "(pair ...)"
    Value::Vector(_) => "#(vector ...)"
    Value::Procedure(Procedure::Native(name)) => "#<native:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<closure>"
    Value::Procedure(Procedure::VMClosure(c)) => "#<vm-closure@" + c.chunk_idx.to_string() + ">"
    Value::Procedure(Procedure::Cont(_)) => "#<continuation>"
    Value::Procedure(Procedure::VMCont(c)) => "#<vm-continuation@" + c.id.to_string() + ">"
    Value::Promise(_) => "#<promise>"
    Value::MultipleValues(vs) => "#<values:" + vs.length().to_string() + ">"
    Value::Syntax(_) => "#<syntax>"
    Value::Port(p) => "#<port:" + p.name + ">"
    Value::Box(_) => "#<box>"
  }
}

/// 文字列を指定幅で左パディング
fn pad_start(s : String, width : Int, pad_char : Char) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let mut result = ""
  let mut i = 0
  while i < width - len {
    result = result + pad_char.to_string()
    i = i + 1
  }
  result + s
}
