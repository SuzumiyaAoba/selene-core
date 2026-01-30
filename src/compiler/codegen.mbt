/// Code generation (IR → bytecode)
///
/// Generate bytecode from intermediate representation

/// code generation context
struct CodegenContext {
  /// main builder
  builder : CodeChunkBuilder
  /// Generated child chunks (nested functions)
  chunks : Array[CodeChunk]
  /// Index of boxed parameter (depth=0)
  boxed_params : Array[Int]
  /// Name of local variable being boxed (depth=0)
  boxed_locals : Array[String]
}

/// Create new context
fn new_context(debug_name : String?) -> CodegenContext {
  {
    builder: new_builder(debug_name),
    chunks: [],
    boxed_params: [],
    boxed_locals: [],
  }
}

/// Create a new context with boxing information
fn new_context_with_boxing(
  debug_name : String?,
  boxed_params : Array[Int],
  boxed_locals : Array[String]
) -> CodegenContext {
  {
    builder: new_builder(debug_name),
    chunks: [],
    boxed_params,
    boxed_locals,
  }
}

/// Convert IR expression to bytecode
fn codegen_expr(ctx : CodegenContext, expr : IRExpr) -> Unit {
  match expr {
    IRExpr::Const(c) => codegen_const(ctx, c)
    IRExpr::Var(var_ref) => codegen_var(ctx, var_ref)
    IRExpr::GlobalVar(name) => codegen_global_var(ctx, name)
    IRExpr::If(cond_expr, then_branch, else_branch) =>
      codegen_if(ctx, cond_expr, then_branch, else_branch)
    IRExpr::Begin(exprs) => codegen_begin(ctx, exprs)
    IRExpr::Lambda(info) => codegen_lambda(ctx, info)
    IRExpr::App(func, args) => codegen_app(ctx, func, args, false)
    IRExpr::TailApp(func, args) => codegen_app(ctx, func, args, true)
    IRExpr::Let(bindings, body) => codegen_let(ctx, bindings, body)
    IRExpr::Letrec(bindings, body) => codegen_letrec(ctx, bindings, body)
    IRExpr::Set(var_ref, value) => codegen_set(ctx, var_ref, value)
    IRExpr::GlobalSet(name, value) => codegen_global_set(ctx, name, value)
    IRExpr::PrimOp(kind, args) => codegen_primop(ctx, kind, args)
    IRExpr::CallCC(proc) => codegen_call_cc(ctx, proc)
    IRExpr::Quote(c) => codegen_quote(ctx, c)
    IRExpr::Delay(body) => codegen_delay(ctx, body)
    IRExpr::And(exprs) => codegen_and(ctx, exprs)
    IRExpr::Or(exprs) => codegen_or(ctx, exprs)
  }
}

/// Generate code for constants
fn codegen_const(ctx : CodegenContext, c : IRConst) -> Unit {
  match c {
    IRConst::Pair(car, cdr) => {
      // Pairs are constructed recursively
      codegen_const(ctx, car)
      codegen_const(ctx, cdr)
      ctx.builder.emit(Opcode::MakePair)
    }
    IRConst::Vector(items) => {
      // Vectors are constructed by pushing elements in sequence
      for item in items {
        codegen_const(ctx, item)
      }
      ctx.builder.emit(Opcode::MakeVector(items.length()))
    }
    _ => {
      let bc_val = ir_const_to_bc_value(c)
      let idx = ctx.builder.add_const(bc_val)
      ctx.builder.emit(Opcode::Push(idx))
    }
  }
}

/// Generate code for local variable references
/// Note: The optimizer has adjusted the index of VarRef
/// - Free variables: depth=0, index=capture position
/// - Parameters: depth=0, index=number of captures + parameter position
fn codegen_var(ctx : CodegenContext, var_ref : VarRef) -> Unit {
  ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))

  // Check if variable is boxed (applies to both depth=0 and depth>0)
  let is_boxed = {
    let mut found = false
    for idx in ctx.boxed_params {
      if idx == var_ref.index {
        found = true
        break
      }
    }
    if !found {
      for name in ctx.boxed_locals {
        if name == var_ref.name {
          found = true
          break
        }
      }
    }
    found
  }
  if is_boxed {
    ctx.builder.emit(Opcode::BoxGet)
  }
}

/// Generate code for global variable references
fn codegen_global_var(ctx : CodegenContext, name : String) -> Unit {
  let idx = ctx.builder.add_name(name)
  ctx.builder.emit(Opcode::LoadGlobal(idx))
}

/// Generate code for if expressions
fn codegen_if(
  ctx : CodegenContext,
  cond_expr : IRExpr,
  then_branch : IRExpr,
  else_branch : IRExpr
) -> Unit {
  // evaluate cond_expr
  codegen_expr(ctx, cond_expr)
  // If false, jump to else
  let else_jump_pos = ctx.builder.current_pos()
  ctx.builder.emit(Opcode::JumpIfFalse(0))  // patch later
  // then branch
  codegen_expr(ctx, then_branch)
  // jump to end after then
  let end_jump_pos = ctx.builder.current_pos()
  ctx.builder.emit(Opcode::Jump(0))  // patch later
  // else branch
  let else_pos = ctx.builder.current_pos()
  codegen_expr(ctx, else_branch)
  // end
  let end_pos = ctx.builder.current_pos()
  // Patch jump destination
  ctx.builder.patch(else_jump_pos, Opcode::JumpIfFalse(else_pos))
  ctx.builder.patch(end_jump_pos, Opcode::Jump(end_pos))
}

/// Generate code for begin expressions
fn codegen_begin(ctx : CodegenContext, exprs : Array[IRExpr]) -> Unit {
  if exprs.length() == 0 {
    // Empty begin returns nil
    let idx = ctx.builder.add_const(BCValue::Nil)
    ctx.builder.emit(Opcode::Push(idx))
    return
  }
  let len = exprs.length()
  let mut i = 0
  while i < len {
    codegen_expr(ctx, exprs[i])
    // Discard results except for the last expression
    if i < len - 1 {
      ctx.builder.emit(Opcode::Pop)
    }
    i = i + 1
  }
}

/// Generate code for lambda expressions
fn codegen_lambda(ctx : CodegenContext, info : LambdaInfo) -> Unit {
  // Identify captured variables that are boxed in parent scope
  // These require BoxGet when referencing because the box itself is captured.
  let captured_boxed_indices : Array[Int] = []
  let mut cap_i = 0
  while cap_i < info.free_vars.length() {
    let var_ref = info.free_vars[cap_i]
    let mut is_boxed = false
    for name in ctx.boxed_locals {
      if name == var_ref.name {
        is_boxed = true
        break
      }
    }
    if is_boxed {
      captured_boxed_indices.push(cap_i)
    }
    cap_i = cap_i + 1
  }

  // Adjust local index of parameters (behind capture)
  let adjusted_boxed_params : Array[Int] = []
  // Add index of captured box
  for idx in captured_boxed_indices {
    adjusted_boxed_params.push(idx)
  }
  // Add parameters to Lambda itself that require boxing
  for boxed_param_idx in info.boxed_params {
    adjusted_boxed_params.push(info.free_vars.length() + boxed_param_idx)
  }

  // Compile function body in new context (include boxing and capturing information)
  let func_ctx = new_context_with_boxing(None, adjusted_boxed_params, info.boxed_locals.copy())
  func_ctx.builder.arity = info.arity
  // Number of local variables: number of captures + number of parameters
  func_ctx.builder.num_locals = info.free_vars.length() + info.params.length()
  func_ctx.builder.num_free_vars = info.free_vars.length()

  // Box parameters that require boxing when starting Lambda
  // Note: The captured box is already boxed, so skip it
  for boxed_param_idx in info.boxed_params {
    let param_local_idx = info.free_vars.length() + boxed_param_idx
    func_ctx.builder.emit(Opcode::LoadLocal(0, param_local_idx))
    func_ctx.builder.emit(Opcode::MakeBox)
    func_ctx.builder.emit(Opcode::StoreLocal(0, param_local_idx))
  }

  // Compile the body
  codegen_expr(func_ctx, info.body)
  func_ctx.builder.emit(Opcode::Return)

  // Add function chunk
  let func_chunk = func_ctx.builder.build()
  let chunk_idx = ctx.chunks.length()

  // Offset chunk index in func_chunk if there are child chunks
  // The chunk referenced by MakeClosure/MakePromise in func_chunk is
  // located in func_ctx.chunks[0], func_ctx.chunks[1], ...
  // These will be placed in chunk_idx+1, chunk_idx+2, ... when added to ctx.chunks
  if func_ctx.chunks.length() > 0 {
    let offset = chunk_idx + 1  // The position where the child chunk starts
    offset_chunk_indices(func_chunk, offset)
  }

  ctx.chunks.push(func_chunk)

  // Also added chunks of child context (recursively offset)
  for chunk in func_ctx.chunks {
    ctx.chunks.push(chunk)
  }

  // Push free variable onto stack
  // Note: VarRef of free_vars has been optimized to be a reference from the parent scope.
  // MakeClosure pops and reverses, so here we push in order.
  // Important: Boxed variables capture the box itself (do not call BoxGet)
  for var_ref in info.free_vars {
    // Determine if this variable is boxed
    let is_boxed = {
      let mut found = false
      for name in ctx.boxed_locals {
        if name == var_ref.name {
          found = true
          break
        }
      }
      found
    }
    if is_boxed {
      // If boxed: push the box itself (do not call BoxGet)
      ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))
    } else {
      // If unboxed: regular variable reference
      codegen_expr(ctx, IRExpr::Var(var_ref))
    }
  }

  // Create closure (chunk_idx, number of captures)
  ctx.builder.emit(Opcode::MakeClosure(chunk_idx, info.free_vars.length()))
}

/// Offset chunk index of MakeClosure/MakePromise within chunk
fn offset_chunk_indices(chunk : CodeChunk, offset : Int) -> Unit {
  let mut i = 0
  while i < chunk.code.length() {
    match chunk.code[i] {
      Opcode::MakeClosure(idx, num_captures) => {
        chunk.code[i] = Opcode::MakeClosure(idx + offset, num_captures)
      }
      Opcode::MakePromise(idx) => {
        chunk.code[i] = Opcode::MakePromise(idx + offset)
      }
      _ => ()
    }
    i = i + 1
  }
}

/// Generate code for function application
fn codegen_app(
  ctx : CodegenContext,
  func : IRExpr,
  args : Array[IRExpr],
  is_tail : Bool
) -> Unit {
  // evaluate function
  codegen_expr(ctx, func)
  // evaluate arguments
  for arg in args {
    codegen_expr(ctx, arg)
  }
  // call
  if is_tail {
    ctx.builder.emit(Opcode::TailCall(args.length()))
  } else {
    ctx.builder.emit(Opcode::Call(args.length()))
  }
}

/// Collect variable names that are set! in IR expressions (including variables in outer scopes)
fn codegen_collect_set_vars(expr : IRExpr) -> Array[String] {
  let set_vars : Array[String] = []
  codegen_collect_set_vars_inner(expr, set_vars, 0)
  set_vars
}

/// set! Internal function for collecting variables
/// current_depth: Current scope depth (+1 for each additional let)
fn codegen_collect_set_vars_inner(expr : IRExpr, set_vars : Array[String], current_depth : Int) -> Unit {
  match expr {
    IRExpr::Set(var_ref, value) => {
      // Collect variables with depth=0 (current scope)
      if var_ref.depth == 0 {
        let mut found = false
        for v in set_vars {
          if v == var_ref.name {
            found = true
            break
          }
        }
        if !found {
          set_vars.push(var_ref.name)
        }
      }
      codegen_collect_set_vars_inner(value, set_vars, current_depth)
    }
    IRExpr::Const(_) => ()
    IRExpr::Var(_) => ()
    IRExpr::GlobalVar(_) => ()
    IRExpr::GlobalSet(_, value) => codegen_collect_set_vars_inner(value, set_vars, current_depth)
    IRExpr::If(cond, then_branch, else_branch) => {
      codegen_collect_set_vars_inner(cond, set_vars, current_depth)
      codegen_collect_set_vars_inner(then_branch, set_vars, current_depth)
      codegen_collect_set_vars_inner(else_branch, set_vars, current_depth)
    }
    IRExpr::Begin(exprs) => {
      for e in exprs {
        codegen_collect_set_vars_inner(e, set_vars, current_depth)
      }
    }
    IRExpr::Lambda(info) => {
      // Detect set! on captured variables in Lambda
      // After optimization, captured variables are referenced as depth=0
      // Collect variable names included in free_vars that are set! in body
      let free_var_names : Array[String] = []
      for fv in info.free_vars {
        free_var_names.push(fv.name)
      }
      // Collect all set! in Lambda body
      let lambda_set_vars : Array[String] = []
      codegen_collect_all_set_vars(info.body, lambda_set_vars)
      // Add matches to free_vars to set_vars in outer scope
      for sv in lambda_set_vars {
        let mut is_free = false
        for fv_name in free_var_names {
          if fv_name == sv {
            is_free = true
            break
          }
        }
        if is_free {
          let mut found = false
          for v in set_vars {
            if v == sv {
              found = true
              break
            }
          }
          if !found {
            set_vars.push(sv)
          }
        }
      }
    }
    IRExpr::App(func, args) => {
      codegen_collect_set_vars_inner(func, set_vars, current_depth)
      for arg in args {
        codegen_collect_set_vars_inner(arg, set_vars, current_depth)
      }
    }
    IRExpr::TailApp(func, args) => {
      codegen_collect_set_vars_inner(func, set_vars, current_depth)
      for arg in args {
        codegen_collect_set_vars_inner(arg, set_vars, current_depth)
      }
    }
    IRExpr::Let(bindings, body) => {
      for binding in bindings {
        codegen_collect_set_vars_inner(binding.init, set_vars, current_depth)
      }
      // body is a new scope, but variables in outer scopes cannot be set!
      // (to access with depth > 0)
      codegen_collect_set_vars_inner(body, set_vars, current_depth + 1)
    }
    IRExpr::Letrec(bindings, body) => {
      for binding in bindings {
        codegen_collect_set_vars_inner(binding.init, set_vars, current_depth)
      }
      codegen_collect_set_vars_inner(body, set_vars, current_depth + 1)
    }
    IRExpr::PrimOp(_, args) => {
      for arg in args {
        codegen_collect_set_vars_inner(arg, set_vars, current_depth)
      }
    }
    IRExpr::CallCC(proc) => codegen_collect_set_vars_inner(proc, set_vars, current_depth)
    IRExpr::Quote(_) => ()
    IRExpr::Delay(body) => codegen_collect_set_vars_inner(body, set_vars, current_depth)
    IRExpr::And(exprs) => {
      for e in exprs {
        codegen_collect_set_vars_inner(e, set_vars, current_depth)
      }
    }
    IRExpr::Or(exprs) => {
      for e in exprs {
        codegen_collect_set_vars_inner(e, set_vars, current_depth)
      }
    }
  }
}

/// Collect all set! variable names in the expression (ignoring depth)
fn codegen_collect_all_set_vars(expr : IRExpr, set_vars : Array[String]) -> Unit {
  match expr {
    IRExpr::Set(var_ref, value) => {
      let mut found = false
      for v in set_vars {
        if v == var_ref.name {
          found = true
          break
        }
      }
      if !found {
        set_vars.push(var_ref.name)
      }
      codegen_collect_all_set_vars(value, set_vars)
    }
    IRExpr::Const(_) => ()
    IRExpr::Var(_) => ()
    IRExpr::GlobalVar(_) => ()
    IRExpr::GlobalSet(_, value) => codegen_collect_all_set_vars(value, set_vars)
    IRExpr::If(cond, then_branch, else_branch) => {
      codegen_collect_all_set_vars(cond, set_vars)
      codegen_collect_all_set_vars(then_branch, set_vars)
      codegen_collect_all_set_vars(else_branch, set_vars)
    }
    IRExpr::Begin(exprs) => {
      for e in exprs {
        codegen_collect_all_set_vars(e, set_vars)
      }
    }
    IRExpr::Lambda(info) => {
      // Recursively explore bodies of nested lambdas
      codegen_collect_all_set_vars(info.body, set_vars)
    }
    IRExpr::App(func, args) => {
      codegen_collect_all_set_vars(func, set_vars)
      for arg in args {
        codegen_collect_all_set_vars(arg, set_vars)
      }
    }
    IRExpr::TailApp(func, args) => {
      codegen_collect_all_set_vars(func, set_vars)
      for arg in args {
        codegen_collect_all_set_vars(arg, set_vars)
      }
    }
    IRExpr::Let(bindings, body) => {
      for binding in bindings {
        codegen_collect_all_set_vars(binding.init, set_vars)
      }
      codegen_collect_all_set_vars(body, set_vars)
    }
    IRExpr::Letrec(bindings, body) => {
      for binding in bindings {
        codegen_collect_all_set_vars(binding.init, set_vars)
      }
      codegen_collect_all_set_vars(body, set_vars)
    }
    IRExpr::PrimOp(_, args) => {
      for arg in args {
        codegen_collect_all_set_vars(arg, set_vars)
      }
    }
    IRExpr::CallCC(proc) => codegen_collect_all_set_vars(proc, set_vars)
    IRExpr::Quote(_) => ()
    IRExpr::Delay(body) => codegen_collect_all_set_vars(body, set_vars)
    IRExpr::And(exprs) => {
      for e in exprs {
        codegen_collect_all_set_vars(e, set_vars)
      }
    }
    IRExpr::Or(exprs) => {
      for e in exprs {
        codegen_collect_all_set_vars(e, set_vars)
      }
    }
  }
}

/// Generate code for let expressions
fn codegen_let(
  ctx : CodegenContext,
  bindings : Array[LetBinding],
  body : IRExpr
) -> Unit {
  let num_bindings = bindings.length()
  if num_bindings == 0 {
    // If there is no binding, only the body is evaluated
    codegen_expr(ctx, body)
    return
  }

  // Collect variables set! in body
  let set_vars = codegen_collect_set_vars(body)

  // Identify bindings that need to be boxed
  let needs_boxing : Array[Bool] = []
  for binding in bindings {
    let mut need = false
    for v in set_vars {
      if v == binding.name {
        need = true
        break
      }
    }
    needs_boxing.push(need)
  }

  // Reserve local variable slot
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))

  // Evaluate the initial value of each binding and store it in a local variable
  let mut i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    if needs_boxing[i] {
      // If boxing is required, MakeBox and then store
      ctx.builder.emit(Opcode::MakeBox)
      // Add to boxed_locals
      ctx.boxed_locals.push(bindings[i].name)
    }
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }

  // Evaluate the main unit
  codegen_expr(ctx, body)

  // Delete from boxed_locals as it goes out of scope
  for binding in bindings {
    let mut idx = -1
    for j in 0..<ctx.boxed_locals.length() {
      if ctx.boxed_locals[j] == binding.name {
        idx = j
        break
      }
    }
    if idx >= 0 {
      let _ = ctx.boxed_locals.remove(idx)
    }
  }
}

/// Generate code for letrec expressions
fn codegen_letrec(
  ctx : CodegenContext,
  bindings : Array[LetBinding],
  body : IRExpr
) -> Unit {
  let num_bindings = bindings.length()
  if num_bindings == 0 {
    codegen_expr(ctx, body)
    return
  }

  // Collect variables set! in body and init expressions
  let set_vars = codegen_collect_set_vars(body)
  for binding in bindings {
    let init_set_vars = codegen_collect_set_vars(binding.init)
    for v in init_set_vars {
      let mut found = false
      for sv in set_vars {
        if sv == v {
          found = true
          break
        }
      }
      if !found {
        set_vars.push(v)
      }
    }
  }

  // Identify bindings that need to be boxed
  let needs_boxing : Array[Bool] = []
  for binding in bindings {
    let mut need = false
    for v in set_vars {
      if v == binding.name {
        need = true
        break
      }
    }
    needs_boxing.push(need)
  }

  // First, reserve an uninitialized slot
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))

  // Add variables that need to be boxed to boxed_locals (to use BoxGet when referencing)
  let mut i = 0
  while i < num_bindings {
    if needs_boxing[i] {
      ctx.boxed_locals.push(bindings[i].name)
    }
    i = i + 1
  }

  // Initialize each binding
  i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    if needs_boxing[i] {
      // When boxing is required
      ctx.builder.emit(Opcode::MakeBox)
    }
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }

  // Evaluate the main unit
  codegen_expr(ctx, body)

  // Delete from boxed_locals as it goes out of scope
  for binding in bindings {
    let mut idx = -1
    for j in 0..<ctx.boxed_locals.length() {
      if ctx.boxed_locals[j] == binding.name {
        idx = j
        break
      }
    }
    if idx >= 0 {
      let _ = ctx.boxed_locals.remove(idx)
    }
  }
}

/// Generate code for set! expression
/// Note: The optimizer has adjusted the index of VarRef
fn codegen_set(ctx : CodegenContext, var_ref : VarRef, value : IRExpr) -> Unit {
  // Check if variable is boxed (applies to both depth=0 and depth>0)
  let is_boxed = {
    let mut found = false
    for idx in ctx.boxed_params {
      if idx == var_ref.index {
        found = true
        break
      }
    }
    if !found {
      for name in ctx.boxed_locals {
        if name == var_ref.name {
          found = true
          break
        }
      }
    }
    found
  }

  if is_boxed {
    // If boxed: use BoxSet
    ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))  // load box
    codegen_expr(ctx, value)  // evaluate new value
    ctx.builder.emit(Opcode::BoxSet)  // update box
    // set! returns void (R5RS)
    let void_idx = ctx.builder.add_const(BCValue::Nil)
    ctx.builder.emit(Opcode::Push(void_idx))
  } else {
    // If not boxed: regular assignment
    codegen_expr(ctx, value)
    ctx.builder.emit(Opcode::Dup)  // set! returns the assigned value
    ctx.builder.emit(Opcode::StoreLocal(var_ref.depth, var_ref.index))
  }
}

/// Generate code for global set!
fn codegen_global_set(ctx : CodegenContext, name : String, value : IRExpr) -> Unit {
  codegen_expr(ctx, value)
  ctx.builder.emit(Opcode::Dup)  // set! returns the assigned value
  let idx = ctx.builder.add_name(name)
  ctx.builder.emit(Opcode::StoreGlobal(idx))
}

/// Generate code for primitive operations
fn codegen_primop(
  ctx : CodegenContext,
  kind : PrimOpKind,
  args : Array[IRExpr]
) -> Unit {
  // evaluate arguments
  for arg in args {
    codegen_expr(ctx, arg)
  }
  // primitive call
  ctx.builder.emit(Opcode::PrimCall(kind, args.length()))
}

/// Generate code for call/cc
fn codegen_call_cc(ctx : CodegenContext, proc : IRExpr) -> Unit {
  // Evaluate the procedure
  codegen_expr(ctx, proc)
  // Capture and call a continuation
  ctx.builder.emit(Opcode::CaptureCC)
}

/// Generate code for quote
fn codegen_quote(ctx : CodegenContext, c : IRConst) -> Unit {
  codegen_const(ctx, c)
}

/// Generate code for delay
fn codegen_delay(ctx : CodegenContext, body : IRExpr) -> Unit {
  // Compile lazy body in new context
  let delay_ctx = new_context(None)
  delay_ctx.builder.arity = 0
  codegen_expr(delay_ctx, body)
  delay_ctx.builder.emit(Opcode::Return)

  // Add promise chunk
  let chunk = delay_ctx.builder.build()
  let chunk_idx = ctx.chunks.length()
  ctx.chunks.push(chunk)

  // Also added child context chunks
  for c in delay_ctx.chunks {
    ctx.chunks.push(c)
  }

  // Create a promise
  ctx.builder.emit(Opcode::MakePromise(chunk_idx))
}

/// Generate code for and expressions
fn codegen_and(ctx : CodegenContext, exprs : Array[IRExpr]) -> Unit {
  if exprs.length() == 0 {
    // (and) => #t
    let idx = ctx.builder.add_const(BCValue::Bool(true))
    ctx.builder.emit(Opcode::Push(idx))
    return
  }

  let jump_positions : Array[Int] = []
  let len = exprs.length()
  let mut i = 0

  while i < len - 1 {
    codegen_expr(ctx, exprs[i])
    // If false, return as result (jump)
    let jump_pos = ctx.builder.current_pos()
    ctx.builder.emit(Opcode::AndJump(0))  // patch later
    jump_positions.push(jump_pos)
    i = i + 1
  }

  // last expression
  codegen_expr(ctx, exprs[len - 1])

  // Patch jump destination (all point to end)
  let end_pos = ctx.builder.current_pos()
  for pos in jump_positions {
    ctx.builder.patch(pos, Opcode::AndJump(end_pos))
  }
}

/// Generate code for or expression
fn codegen_or(ctx : CodegenContext, exprs : Array[IRExpr]) -> Unit {
  if exprs.length() == 0 {
    // (or) => #f
    let idx = ctx.builder.add_const(BCValue::Bool(false))
    ctx.builder.emit(Opcode::Push(idx))
    return
  }

  let jump_positions : Array[Int] = []
  let len = exprs.length()
  let mut i = 0

  while i < len - 1 {
    codegen_expr(ctx, exprs[i])
    // If true, return as result (jump)
    let jump_pos = ctx.builder.current_pos()
    ctx.builder.emit(Opcode::OrJump(0))  // patch later
    jump_positions.push(jump_pos)
    i = i + 1
  }

  // last expression
  codegen_expr(ctx, exprs[len - 1])

  // Patch jump destination (all point to end)
  let end_pos = ctx.builder.current_pos()
  for pos in jump_positions {
    ctx.builder.patch(pos, Opcode::OrJump(end_pos))
  }
}

/// Convert IR to compiled module
pub fn generate(ir : IRExpr) -> CompiledModule {
  let ctx = new_context(Some("main"))
  codegen_expr(ctx, ir)
  ctx.builder.emit(Opcode::Halt)
  let main_chunk = ctx.builder.build()
  { main: main_chunk, chunks: ctx.chunks }
}

/// Convert SExpr directly to compiled module (with optimizations)
pub fn compile_to_module(expr : SExpr) -> Result[CompiledModule, CompileError] {
  match compile_toplevel(expr) {
    Ok(ir) => {
      let optimized = optimize(ir)
      Ok(generate(optimized))
    }
    Err(e) => Err(e)
  }
}

/// Convert SExpr to compiled module with optimizations
pub fn compile_to_module_optimized(expr : SExpr) -> Result[CompiledModule, CompileError] {
  match compile_toplevel(expr) {
    Ok(ir) => {
      let optimized = optimize(ir)
      Ok(generate(optimized))
    }
    Err(e) => Err(e)
  }
}
