/// スタックベース仮想マシン
///
/// バイトコードを実行する VM の実装
///
/// 型定義:
/// - VMClosure, VMContinuation, VMCallFrame は value.mbt で定義
/// - Procedure enum に VMClosure, VMCont が追加されている

/// VM のエラー
pub(all) enum VMError {
  StackUnderflow
  InvalidInstruction
  TypeError(String)
  ArityError(String)
  UnboundVariable(String)
  DivisionByZero
  IndexOutOfBounds
  NotAProcedure
  InvalidContinuation
  RuntimeError(String)
} derive(Show)

/// VM プロミス（遅延評価）
pub(all) struct VMPromise {
  /// 評価済みかどうか
  mut forced : Bool
  /// コードチャンクインデックス（未評価の場合）
  chunk_idx : Int
  /// 評価済みの値
  mut value : Value
}

/// VM 状態
pub(all) struct VMState {
  /// 値スタック
  stack : Array[Value]
  /// コールスタック
  call_stack : Array[VMCallFrame]
  /// 現在のコードチャンクインデックス（-1 はメイン）
  mut current_chunk : Int
  /// 命令ポインタ
  mut ip : Int
  /// グローバル環境
  globals : @hashmap.T[String, Value]
  /// コンパイル済みモジュール
  compiled_module : CompiledModule
  /// 継続カウンタ
  mut cont_counter : Int
}

/// 新しい VM 状態を作成
pub fn new_vm_state(compiled_module : CompiledModule) -> VMState {
  let globals = create_initial_globals()
  {
    stack: [],
    call_stack: [],
    current_chunk: -1,
    ip: 0,
    globals,
    compiled_module,
    cont_counter: 0,
  }
}

/// 外部グローバル環境を使用して VM 状態を作成
pub fn new_vm_state_with_globals(
  compiled_module : CompiledModule,
  globals : @hashmap.T[String, Value]
) -> VMState {
  {
    stack: [],
    call_stack: [],
    current_chunk: -1,
    ip: 0,
    globals,
    compiled_module,
    cont_counter: 0,
  }
}

/// 初期グローバル環境を作成
pub fn create_initial_globals() -> @hashmap.T[String, Value] {
  let globals : @hashmap.T[String, Value] = @hashmap.new()
  globals.set("+", Value::Procedure(Procedure::Native("+")))
  globals.set("-", Value::Procedure(Procedure::Native("-")))
  globals.set("*", Value::Procedure(Procedure::Native("*")))
  globals.set("/", Value::Procedure(Procedure::Native("/")))
  globals.set("cons", Value::Procedure(Procedure::Native("cons")))
  globals.set("car", Value::Procedure(Procedure::Native("car")))
  globals.set("cdr", Value::Procedure(Procedure::Native("cdr")))
  globals.set("null?", Value::Procedure(Procedure::Native("null?")))
  globals.set("pair?", Value::Procedure(Procedure::Native("pair?")))
  globals.set("list", Value::Procedure(Procedure::Native("list")))
  globals.set("=", Value::Procedure(Procedure::Native("=")))
  globals.set("<", Value::Procedure(Procedure::Native("<")))
  globals.set(">", Value::Procedure(Procedure::Native(">")))
  globals.set("<=", Value::Procedure(Procedure::Native("<=")))
  globals.set(">=", Value::Procedure(Procedure::Native(">=")))
  globals.set("eq?", Value::Procedure(Procedure::Native("eq?")))
  globals.set("eqv?", Value::Procedure(Procedure::Native("eqv?")))
  globals.set("equal?", Value::Procedure(Procedure::Native("equal?")))
  globals.set("not", Value::Procedure(Procedure::Native("not")))
  globals.set("display", Value::Procedure(Procedure::Native("display")))
  globals.set("newline", Value::Procedure(Procedure::Native("newline")))
  globals
}

/// 現在のコードチャンクを取得
fn get_current_chunk(vm : VMState) -> CodeChunk {
  if vm.current_chunk < 0 {
    vm.compiled_module.main
  } else {
    vm.compiled_module.chunks[vm.current_chunk]
  }
}

/// スタックからポップ
fn vm_pop(vm : VMState) -> Result[Value, VMError] {
  if vm.stack.length() == 0 {
    Err(VMError::StackUnderflow)
  } else {
    Ok(vm.stack.pop().unwrap())
  }
}

/// スタックにプッシュ
fn vm_push(vm : VMState, value : Value) -> Unit {
  vm.stack.push(value)
}

/// スタックトップを取得（ポップしない）
fn vm_peek(vm : VMState) -> Result[Value, VMError] {
  if vm.stack.length() == 0 {
    Err(VMError::StackUnderflow)
  } else {
    Ok(vm.stack[vm.stack.length() - 1])
  }
}

/// ローカル変数を取得
fn vm_get_local(vm : VMState, depth : Int, index : Int) -> Result[Value, VMError] {
  let frame_idx = vm.call_stack.length() - 1 - depth
  if frame_idx < 0 {
    return Err(VMError::RuntimeError("invalid frame depth"))
  }
  let frame = vm.call_stack[frame_idx]
  let stack_idx = frame.base_ptr + index
  if stack_idx >= vm.stack.length() {
    return Err(VMError::IndexOutOfBounds)
  }
  Ok(vm.stack[stack_idx])
}

/// ローカル変数を設定
fn vm_set_local(
  vm : VMState,
  depth : Int,
  index : Int,
  value : Value
) -> Result[Unit, VMError] {
  let frame_idx = vm.call_stack.length() - 1 - depth
  if frame_idx < 0 {
    return Err(VMError::RuntimeError("invalid frame depth"))
  }
  let frame = vm.call_stack[frame_idx]
  let stack_idx = frame.base_ptr + index
  if stack_idx >= vm.stack.length() {
    return Err(VMError::IndexOutOfBounds)
  }
  vm.stack[stack_idx] = value
  Ok(())
}

/// プリミティブ操作を実行
fn vm_exec_primop(
  vm : VMState,
  kind : PrimOpKind,
  argc : Int
) -> Result[Value, VMError] {
  let args : Array[Value] = []
  let mut i = 0
  while i < argc {
    match vm_pop(vm) {
      Ok(v) => args.push(v)
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  args.rev_inplace()

  match kind {
    PrimOpKind::Add => vm_exec_add(args)
    PrimOpKind::Sub => vm_exec_sub(args)
    PrimOpKind::Mul => vm_exec_mul(args)
    PrimOpKind::Div => vm_exec_div(args)
    PrimOpKind::NumEq => vm_exec_num_eq(args)
    PrimOpKind::Lt => vm_exec_lt(args)
    PrimOpKind::Gt => vm_exec_gt(args)
    PrimOpKind::Le => vm_exec_le(args)
    PrimOpKind::Ge => vm_exec_ge(args)
    PrimOpKind::Cons => vm_exec_cons(args)
    PrimOpKind::Car => vm_exec_car(args)
    PrimOpKind::Cdr => vm_exec_cdr(args)
    PrimOpKind::NullP => vm_exec_null_p(args)
    PrimOpKind::PairP => vm_exec_pair_p(args)
    PrimOpKind::Not => vm_exec_not(args)
    PrimOpKind::List => vm_exec_list(args)
    PrimOpKind::Length => vm_exec_length(args)
    PrimOpKind::Eq => vm_exec_eq_p(args)
    PrimOpKind::Eqv => vm_exec_eqv_p(args)
    PrimOpKind::Equal => vm_exec_equal_p(args)
    PrimOpKind::ZeroP => vm_exec_zero_p(args)
    PrimOpKind::PositiveP => vm_exec_positive_p(args)
    PrimOpKind::NegativeP => vm_exec_negative_p(args)
    PrimOpKind::NumberP => vm_exec_number_p(args)
    PrimOpKind::BooleanP => vm_exec_boolean_p(args)
    PrimOpKind::SymbolP => vm_exec_symbol_p(args)
    PrimOpKind::StringP => vm_exec_string_p(args)
    PrimOpKind::ProcedureP => vm_exec_procedure_p(args)
    _ => Err(VMError::RuntimeError("unimplemented primitive: " + kind.to_string()))
  }
}

/// 加算
fn vm_exec_add(args : Array[Value]) -> Result[Value, VMError] {
  let mut result = 0
  for arg in args {
    match arg {
      Value::Number(Number::Int(n)) => result = result + n
      _ => return Err(VMError::TypeError("+ requires numbers"))
    }
  }
  Ok(Value::Number(Number::Int(result)))
}

/// 減算
fn vm_exec_sub(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() == 0 {
    return Err(VMError::ArityError("- requires at least 1 argument"))
  }
  if args.length() == 1 {
    match args[0] {
      Value::Number(Number::Int(n)) => return Ok(Value::Number(Number::Int(-n)))
      _ => return Err(VMError::TypeError("- requires numbers"))
    }
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("- requires numbers"))
  }
  let mut result = first
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => result = result - n
      _ => return Err(VMError::TypeError("- requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Number(Number::Int(result)))
}

/// 乗算
fn vm_exec_mul(args : Array[Value]) -> Result[Value, VMError] {
  let mut result = 1
  for arg in args {
    match arg {
      Value::Number(Number::Int(n)) => result = result * n
      _ => return Err(VMError::TypeError("* requires numbers"))
    }
  }
  Ok(Value::Number(Number::Int(result)))
}

/// 除算
fn vm_exec_div(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Err(VMError::ArityError("/ requires at least 2 arguments"))
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("/ requires numbers"))
  }
  let mut result = first
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if n == 0 {
          return Err(VMError::DivisionByZero)
        }
        result = result / n
      }
      _ => return Err(VMError::TypeError("/ requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Number(Number::Int(result)))
}

/// 数値等価
fn vm_exec_num_eq(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let first = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) =>
        if n != first {
          return Ok(Value::Bool(false))
        }
      _ => return Err(VMError::TypeError("= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// 小なり
fn vm_exec_lt(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("< requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev >= n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("< requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// 大なり
fn vm_exec_gt(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("> requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev <= n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("> requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// 以下
fn vm_exec_le(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError("<= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev > n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError("<= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// 以上
fn vm_exec_ge(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() < 2 {
    return Ok(Value::Bool(true))
  }
  let mut prev = match args[0] {
    Value::Number(Number::Int(n)) => n
    _ => return Err(VMError::TypeError(">= requires numbers"))
  }
  let mut i = 1
  while i < args.length() {
    match args[i] {
      Value::Number(Number::Int(n)) => {
        if prev < n {
          return Ok(Value::Bool(false))
        }
        prev = n
      }
      _ => return Err(VMError::TypeError(">= requires numbers"))
    }
    i = i + 1
  }
  Ok(Value::Bool(true))
}

/// cons
fn vm_exec_cons(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("cons requires 2 arguments"))
  }
  Ok(Value::Pair(args[0], args[1]))
}

/// car
fn vm_exec_car(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("car requires 1 argument"))
  }
  match args[0] {
    Value::Pair(car, _) => Ok(car)
    _ => Err(VMError::TypeError("car requires a pair"))
  }
}

/// cdr
fn vm_exec_cdr(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("cdr requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, cdr) => Ok(cdr)
    _ => Err(VMError::TypeError("cdr requires a pair"))
  }
}

/// null?
fn vm_exec_null_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("null? requires 1 argument"))
  }
  match args[0] {
    Value::Nil => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// pair?
fn vm_exec_pair_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("pair? requires 1 argument"))
  }
  match args[0] {
    Value::Pair(_, _) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// not
fn vm_exec_not(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("not requires 1 argument"))
  }
  match args[0] {
    Value::Bool(false) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// list
fn vm_exec_list(args : Array[Value]) -> Result[Value, VMError] {
  let mut result : Value = Value::Nil
  let mut i = args.length() - 1
  while i >= 0 {
    result = Value::Pair(args[i], result)
    i = i - 1
  }
  Ok(result)
}

/// length
fn vm_exec_length(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("length requires 1 argument"))
  }
  let mut count = 0
  let mut current = args[0]
  while true {
    match current {
      Value::Nil => return Ok(Value::Number(Number::Int(count)))
      Value::Pair(_, cdr) => {
        count = count + 1
        current = cdr
      }
      _ => return Err(VMError::TypeError("length requires a list"))
    }
  }
  Ok(Value::Number(Number::Int(count)))
}

/// 値の同一性チェック（簡易版）
fn vm_values_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    _ => false
  }
}

/// 値の等価性チェック（再帰的）
fn vm_values_equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Value::Nil, Value::Nil) => true
    (Value::Bool(x), Value::Bool(y)) => x == y
    (Value::Number(Number::Int(x)), Value::Number(Number::Int(y))) => x == y
    (Value::Symbol(x), Value::Symbol(y)) => x == y
    (Value::Char(x), Value::Char(y)) => x == y
    (Value::String(x), Value::String(y)) => x == y
    (Value::Pair(car1, cdr1), Value::Pair(car2, cdr2)) =>
      vm_values_equal(car1, car2) && vm_values_equal(cdr1, cdr2)
    _ => false
  }
}

/// eq?
fn vm_exec_eq_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("eq? requires 2 arguments"))
  }
  Ok(Value::Bool(vm_values_eq(args[0], args[1])))
}

/// eqv?
fn vm_exec_eqv_p(args : Array[Value]) -> Result[Value, VMError] {
  vm_exec_eq_p(args)
}

/// equal?
fn vm_exec_equal_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 2 {
    return Err(VMError::ArityError("equal? requires 2 arguments"))
  }
  Ok(Value::Bool(vm_values_equal(args[0], args[1])))
}

/// zero?
fn vm_exec_zero_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("zero? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n == 0))
    _ => Err(VMError::TypeError("zero? requires a number"))
  }
}

/// positive?
fn vm_exec_positive_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("positive? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n > 0))
    _ => Err(VMError::TypeError("positive? requires a number"))
  }
}

/// negative?
fn vm_exec_negative_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("negative? requires 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Bool(n < 0))
    _ => Err(VMError::TypeError("negative? requires a number"))
  }
}

/// number?
fn vm_exec_number_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("number? requires 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// boolean?
fn vm_exec_boolean_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("boolean? requires 1 argument"))
  }
  match args[0] {
    Value::Bool(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// symbol?
fn vm_exec_symbol_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("symbol? requires 1 argument"))
  }
  match args[0] {
    Value::Symbol(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// string?
fn vm_exec_string_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("string? requires 1 argument"))
  }
  match args[0] {
    Value::String(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// procedure?
fn vm_exec_procedure_p(args : Array[Value]) -> Result[Value, VMError] {
  if args.length() != 1 {
    return Err(VMError::ArityError("procedure? requires 1 argument"))
  }
  match args[0] {
    Value::Procedure(_) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}

/// 値が真かどうかをチェック（Scheme では #f 以外はすべて真）
fn vm_is_truthy(value : Value) -> Bool {
  match value {
    Value::Bool(false) => false
    _ => true
  }
}

/// 関数を呼び出す
fn vm_call_function(
  vm : VMState,
  func : Value,
  args : Array[Value],
  is_tail : Bool
) -> Result[Unit, VMError] {
  match func {
    Value::Procedure(Procedure::VMClosure(closure)) => {
      let target_chunk = vm.compiled_module.chunks[closure.chunk_idx]
      if target_chunk.arity >= 0 && args.length() != target_chunk.arity {
        return Err(VMError::ArityError("closure arity mismatch"))
      }
      if is_tail && vm.call_stack.length() > 0 {
        let frame = vm.call_stack[vm.call_stack.length() - 1]
        while vm.stack.length() > frame.base_ptr {
          let _ = vm.stack.pop()
        }
        for arg in args {
          vm_push(vm, arg)
        }
        vm.current_chunk = closure.chunk_idx
        vm.ip = 0
      } else {
        let frame : VMCallFrame = {
          return_chunk: vm.current_chunk,
          return_ip: vm.ip,
          base_ptr: vm.stack.length(),
          num_locals: args.length(),
        }
        vm.call_stack.push(frame)
        for arg in args {
          vm_push(vm, arg)
        }
        vm.current_chunk = closure.chunk_idx
        vm.ip = 0
      }
      Ok(())
    }
    Value::Procedure(Procedure::Native(name)) => {
      match apply_builtin(name, args) {
        Ok(v) => {
          vm_push(vm, v)
          Ok(())
        }
        Err(e) => Err(VMError::RuntimeError(e.to_string()))
      }
    }
    Value::Procedure(Procedure::VMCont(cont)) => {
      if args.length() != 1 {
        return Err(VMError::ArityError("continuation requires 1 argument"))
      }
      vm.stack.clear()
      for v in cont.stack {
        vm.stack.push(v)
      }
      vm.call_stack.clear()
      for f in cont.call_stack {
        vm.call_stack.push(f)
      }
      vm_push(vm, args[0])
      vm.current_chunk = cont.return_chunk
      vm.ip = cont.return_ip
      Ok(())
    }
    _ => Err(VMError::NotAProcedure)
  }
}

/// 1 命令を実行
fn vm_step(vm : VMState) -> Result[Bool, VMError] {
  let chunk = get_current_chunk(vm)
  if vm.ip >= chunk.code.length() {
    return Ok(false)
  }

  let instr = chunk.code[vm.ip]
  vm.ip = vm.ip + 1

  match instr {
    Opcode::Push(idx) => {
      let bc_val = chunk.constants[idx]
      let value = bc_value_to_value(bc_val)
      vm_push(vm, value)
      Ok(true)
    }

    Opcode::Pop => {
      match vm_pop(vm) {
        Ok(_) => Ok(true)
        Err(e) => Err(e)
      }
    }

    Opcode::LoadLocal(depth, index) => {
      match vm_get_local(vm, depth, index) {
        Ok(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::StoreLocal(depth, index) => {
      match vm_pop(vm) {
        Ok(value) =>
          match vm_set_local(vm, depth, index, value) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::LoadGlobal(idx) => {
      let name = chunk.names[idx]
      match vm.globals.get(name) {
        Some(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        None => Err(VMError::UnboundVariable(name))
      }
    }

    Opcode::StoreGlobal(idx) => {
      let name = chunk.names[idx]
      match vm_pop(vm) {
        Ok(value) => {
          vm.globals.set(name, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::MakeClosure(chunk_idx) => {
      let closure : VMClosure = { chunk_idx, captures: [] }
      vm_push(vm, Value::Procedure(Procedure::VMClosure(closure)))
      Ok(true)
    }

    Opcode::Call(argc) => {
      let args : Array[Value] = []
      let mut i = 0
      while i < argc {
        match vm_pop(vm) {
          Ok(v) => args.push(v)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      args.rev_inplace()
      match vm_pop(vm) {
        Ok(func) =>
          match vm_call_function(vm, func, args, false) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::TailCall(argc) => {
      let args : Array[Value] = []
      let mut i = 0
      while i < argc {
        match vm_pop(vm) {
          Ok(v) => args.push(v)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      args.rev_inplace()
      match vm_pop(vm) {
        Ok(func) =>
          match vm_call_function(vm, func, args, true) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::Return => {
      match vm_pop(vm) {
        Ok(result) => {
          if vm.call_stack.length() == 0 {
            vm_push(vm, result)
            return Ok(false)
          }
          let frame = vm.call_stack.pop().unwrap()
          while vm.stack.length() > frame.base_ptr {
            let _ = vm.stack.pop()
          }
          vm_push(vm, result)
          vm.current_chunk = frame.return_chunk
          vm.ip = frame.return_ip
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Jump(target) => {
      vm.ip = target
      Ok(true)
    }

    Opcode::JumpIfFalse(target) => {
      match vm_pop(vm) {
        Ok(value) => {
          if not(vm_is_truthy(value)) {
            vm.ip = target
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::PrimCall(kind, argc) => {
      match vm_exec_primop(vm, kind, argc) {
        Ok(result) => {
          vm_push(vm, result)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::CaptureCC => {
      match vm_pop(vm) {
        Ok(proc) => {
          let cont_id = vm.cont_counter
          vm.cont_counter = vm.cont_counter + 1
          let stack_copy : Array[Value] = []
          for v in vm.stack {
            stack_copy.push(v)
          }
          let call_stack_copy : Array[VMCallFrame] = []
          for f in vm.call_stack {
            call_stack_copy.push(f)
          }
          let cont : VMContinuation = {
            id: cont_id,
            stack: stack_copy,
            call_stack: call_stack_copy,
            return_chunk: vm.current_chunk,
            return_ip: vm.ip,
          }
          let cont_value = Value::Procedure(Procedure::VMCont(cont))
          match vm_call_function(vm, proc, [cont_value], false) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Halt => Ok(false)

    Opcode::MakePair => {
      match vm_pop(vm) {
        Ok(cdr) =>
          match vm_pop(vm) {
            Ok(car) => {
              vm_push(vm, Value::Pair(car, cdr))
              Ok(true)
            }
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }

    Opcode::MakeList(n) => {
      let mut result : Value = Value::Nil
      let mut i = 0
      while i < n {
        match vm_pop(vm) {
          Ok(elem) => result = Value::Pair(elem, result)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      vm_push(vm, result)
      Ok(true)
    }

    Opcode::MakeVector(n) => {
      let items : Array[Value] = []
      let mut i = 0
      while i < n {
        match vm_pop(vm) {
          Ok(elem) => items.push(elem)
          Err(e) => return Err(e)
        }
        i = i + 1
      }
      items.rev_inplace()
      vm_push(vm, Value::Vector(items))
      Ok(true)
    }

    Opcode::MakePromise(_) => {
      vm_push(vm, Value::Nil)
      Ok(true)
    }

    Opcode::AndJump(target) => {
      match vm_peek(vm) {
        Ok(value) => {
          if not(vm_is_truthy(value)) {
            vm.ip = target
          } else {
            let _ = vm_pop(vm)
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::OrJump(target) => {
      match vm_peek(vm) {
        Ok(value) => {
          if vm_is_truthy(value) {
            vm.ip = target
          } else {
            let _ = vm_pop(vm)
          }
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::Dup => {
      match vm_peek(vm) {
        Ok(value) => {
          vm_push(vm, value)
          Ok(true)
        }
        Err(e) => Err(e)
      }
    }

    Opcode::AllocateLocals(n) => {
      let mut i = 0
      while i < n {
        vm_push(vm, Value::Nil)
        i = i + 1
      }
      Ok(true)
    }

    Opcode::InitLocal(depth, index) => {
      match vm_pop(vm) {
        Ok(value) =>
          match vm_set_local(vm, depth, index, value) {
            Ok(_) => Ok(true)
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }
  }
}

/// VM を実行
pub fn vm_run(vm : VMState) -> Result[Value, VMError] {
  // トップレベル用のダミーフレームを作成
  let initial_frame : VMCallFrame = {
    return_chunk: -1,
    return_ip: 0,
    base_ptr: 0,
    num_locals: 0,
  }
  vm.call_stack.push(initial_frame)

  while true {
    match vm_step(vm) {
      Ok(true) => continue
      Ok(false) => break
      Err(e) => return Err(e)
    }
  }
  if vm.stack.length() > 0 {
    Ok(vm.stack[vm.stack.length() - 1])
  } else {
    Ok(Value::Nil)
  }
}

/// コンパイル済みモジュールを実行
pub fn vm_run_module(compiled_module : CompiledModule) -> Result[Value, VMError] {
  let vm = new_vm_state(compiled_module)
  vm_run(vm)
}

/// S 式を VM で実行
pub fn vm_eval(expr : SExpr) -> Result[Value, String] {
  match compile_to_module(expr) {
    Ok(compiled_module) =>
      match vm_run_module(compiled_module) {
        Ok(v) => Ok(v)
        Err(e) => Err(e.to_string())
      }
    Err(e) => Err(e.to_string())
  }
}
