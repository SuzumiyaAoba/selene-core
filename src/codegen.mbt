/// コード生成 (IR → バイトコード)
///
/// 中間表現からバイトコードを生成する

/// コード生成コンテキスト
struct CodegenContext {
  /// メインビルダー
  builder : CodeChunkBuilder
  /// 生成された子チャンク（ネストした関数）
  chunks : Array[CodeChunk]
  /// ボックス化されているパラメータのインデックス（depth=0）
  boxed_params : Array[Int]
  /// ボックス化されているローカル変数の名前（depth=0）
  boxed_locals : Array[String]
}

/// 新しいコンテキストを作成
fn new_context(debug_name : String?) -> CodegenContext {
  {
    builder: new_builder(debug_name),
    chunks: [],
    boxed_params: [],
    boxed_locals: [],
  }
}

/// ボックス化情報を含めて新しいコンテキストを作成
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

/// IR 式をバイトコードに変換
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

/// 定数をコード生成
fn codegen_const(ctx : CodegenContext, c : IRConst) -> Unit {
  match c {
    IRConst::Pair(car, cdr) => {
      // ペアは再帰的に構築
      codegen_const(ctx, car)
      codegen_const(ctx, cdr)
      ctx.builder.emit(Opcode::MakePair)
    }
    IRConst::Vector(items) => {
      // ベクトルは要素を順にプッシュして構築
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

/// ローカル変数参照をコード生成
/// 注: オプティマイザーが VarRef のインデックスを調整済み
/// - 自由変数: depth=0, index=キャプチャ位置
/// - パラメータ: depth=0, index=キャプチャ数+パラメータ位置
fn codegen_var(ctx : CodegenContext, var_ref : VarRef) -> Unit {
  ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))

  // depth=0 でボックス化されている場合、BoxGet を使って値を取り出す
  if var_ref.depth == 0 {
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
}

/// グローバル変数参照をコード生成
fn codegen_global_var(ctx : CodegenContext, name : String) -> Unit {
  let idx = ctx.builder.add_name(name)
  ctx.builder.emit(Opcode::LoadGlobal(idx))
}

/// if 式をコード生成
fn codegen_if(
  ctx : CodegenContext,
  cond_expr : IRExpr,
  then_branch : IRExpr,
  else_branch : IRExpr
) -> Unit {
  // cond_expr を評価
  codegen_expr(ctx, cond_expr)
  // false なら else にジャンプ
  let else_jump_pos = ctx.builder.current_pos()
  ctx.builder.emit(Opcode::JumpIfFalse(0))  // 後でパッチ
  // then 分岐
  codegen_expr(ctx, then_branch)
  // then の後で end にジャンプ
  let end_jump_pos = ctx.builder.current_pos()
  ctx.builder.emit(Opcode::Jump(0))  // 後でパッチ
  // else 分岐
  let else_pos = ctx.builder.current_pos()
  codegen_expr(ctx, else_branch)
  // end
  let end_pos = ctx.builder.current_pos()
  // ジャンプ先をパッチ
  ctx.builder.patch(else_jump_pos, Opcode::JumpIfFalse(else_pos))
  ctx.builder.patch(end_jump_pos, Opcode::Jump(end_pos))
}

/// begin 式をコード生成
fn codegen_begin(ctx : CodegenContext, exprs : Array[IRExpr]) -> Unit {
  if exprs.length() == 0 {
    // 空の begin は nil を返す
    let idx = ctx.builder.add_const(BCValue::Nil)
    ctx.builder.emit(Opcode::Push(idx))
    return
  }
  let len = exprs.length()
  let mut i = 0
  while i < len {
    codegen_expr(ctx, exprs[i])
    // 最後の式以外は結果を捨てる
    if i < len - 1 {
      ctx.builder.emit(Opcode::Pop)
    }
    i = i + 1
  }
}

/// lambda 式をコード生成
fn codegen_lambda(ctx : CodegenContext, info : LambdaInfo) -> Unit {
  // キャプチャした変数のうち、親スコープでボックス化されているものを特定
  // これらはボックス自体がキャプチャされるため、参照時に BoxGet が必要
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

  // パラメータのローカルインデックスを調整（キャプチャの後ろにある）
  let adjusted_boxed_params : Array[Int] = []
  // キャプチャしたボックスのインデックスを追加
  for idx in captured_boxed_indices {
    adjusted_boxed_params.push(idx)
  }
  // Lambda 自体のパラメータでボックス化が必要なものを追加
  for boxed_param_idx in info.boxed_params {
    adjusted_boxed_params.push(info.free_vars.length() + boxed_param_idx)
  }

  // 新しいコンテキストで関数本体をコンパイル（ボックス化情報とキャプチャ情報を含める）
  let func_ctx = new_context_with_boxing(None, adjusted_boxed_params, info.boxed_locals.copy())
  func_ctx.builder.arity = info.arity
  // ローカル変数数：キャプチャ数 + パラメータ数
  func_ctx.builder.num_locals = info.free_vars.length() + info.params.length()
  func_ctx.builder.num_free_vars = info.free_vars.length()

  // Lambda の開始時に、ボックス化が必要なパラメータをボックス化
  // 注：キャプチャしたボックスは既にボックス化されているのでスキップ
  for boxed_param_idx in info.boxed_params {
    let param_local_idx = info.free_vars.length() + boxed_param_idx
    func_ctx.builder.emit(Opcode::LoadLocal(0, param_local_idx))
    func_ctx.builder.emit(Opcode::MakeBox)
    func_ctx.builder.emit(Opcode::StoreLocal(0, param_local_idx))
  }

  // 本体をコンパイル
  codegen_expr(func_ctx, info.body)
  func_ctx.builder.emit(Opcode::Return)

  // 関数チャンクを追加
  let func_chunk = func_ctx.builder.build()
  let chunk_idx = ctx.chunks.length()

  // 子チャンクがある場合、func_chunk 内のチャンクインデックスをオフセット
  // func_chunk 内の MakeClosure/MakePromise が参照するチャンクは、
  // func_ctx.chunks[0], func_ctx.chunks[1], ... にあり、
  // これらは ctx.chunks に追加される際に chunk_idx+1, chunk_idx+2, ... の位置になる
  if func_ctx.chunks.length() > 0 {
    let offset = chunk_idx + 1  // 子チャンクが始まる位置
    offset_chunk_indices(func_chunk, offset)
  }

  ctx.chunks.push(func_chunk)

  // 子コンテキストのチャンクも追加（再帰的にオフセット済み）
  for chunk in func_ctx.chunks {
    ctx.chunks.push(chunk)
  }

  // 自由変数をスタックにプッシュ
  // 注: free_vars の VarRef は optimize で親スコープからの参照に調整済み
  // MakeClosure が pop して reverse するので、ここでは順番通りにプッシュ
  // 重要: ボックス化された変数はボックス自体をキャプチャする（BoxGet を呼ばない）
  for var_ref in info.free_vars {
    // この変数がボックス化されているか判定
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
      // ボックス化されている場合: ボックス自体をプッシュ（BoxGet を呼ばない）
      ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))
    } else {
      // ボックス化されていない場合: 通常の変数参照
      codegen_expr(ctx, IRExpr::Var(var_ref))
    }
  }

  // クロージャを作成（chunk_idx, キャプチャ数）
  ctx.builder.emit(Opcode::MakeClosure(chunk_idx, info.free_vars.length()))
}

/// チャンク内の MakeClosure/MakePromise のチャンクインデックスをオフセット
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

/// 関数適用をコード生成
fn codegen_app(
  ctx : CodegenContext,
  func : IRExpr,
  args : Array[IRExpr],
  is_tail : Bool
) -> Unit {
  // 関数を評価
  codegen_expr(ctx, func)
  // 引数を評価
  for arg in args {
    codegen_expr(ctx, arg)
  }
  // 呼び出し
  if is_tail {
    ctx.builder.emit(Opcode::TailCall(args.length()))
  } else {
    ctx.builder.emit(Opcode::Call(args.length()))
  }
}

/// IR 式内で set! される変数名を収集（外側のスコープの変数も含む）
fn codegen_collect_set_vars(expr : IRExpr) -> Array[String] {
  let set_vars : Array[String] = []
  codegen_collect_set_vars_inner(expr, set_vars, 0)
  set_vars
}

/// set! 変数収集の内部関数
/// current_depth: 現在のスコープ深度（letが増えるごとに+1）
fn codegen_collect_set_vars_inner(expr : IRExpr, set_vars : Array[String], current_depth : Int) -> Unit {
  match expr {
    IRExpr::Set(var_ref, value) => {
      // depth=0 の変数を収集（現在のスコープ）
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
      // Lambda 内でキャプチャした変数に対する set! を検出
      // 最適化後は、キャプチャした変数は depth=0 として参照される
      // free_vars に含まれる変数名で、body 内で set! されるものを収集
      let free_var_names : Array[String] = []
      for fv in info.free_vars {
        free_var_names.push(fv.name)
      }
      // Lambda body 内の全 set! を収集
      let lambda_set_vars : Array[String] = []
      codegen_collect_all_set_vars(info.body, lambda_set_vars)
      // free_vars と一致するものを外側のスコープの set_vars に追加
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
      // body は新しいスコープだが、外側のスコープの変数が set! される可能性はない
      // （depth > 0 でアクセスするため）
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

/// 式内の全ての set! される変数名を収集（深度を無視）
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
      // ネストした lambda の body も再帰的に探索
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

/// let 式をコード生成
fn codegen_let(
  ctx : CodegenContext,
  bindings : Array[LetBinding],
  body : IRExpr
) -> Unit {
  let num_bindings = bindings.length()
  if num_bindings == 0 {
    // バインディングがない場合は本体のみ評価
    codegen_expr(ctx, body)
    return
  }

  // body 内で set! される変数を収集
  let set_vars = codegen_collect_set_vars(body)

  // ボックス化が必要なバインディングを特定
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

  // ローカル変数スロットを確保
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))

  // 各バインディングの初期値を評価してローカル変数に格納
  let mut i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    if needs_boxing[i] {
      // ボックス化が必要な場合、MakeBox してから格納
      ctx.builder.emit(Opcode::MakeBox)
      // boxed_locals に追加
      ctx.boxed_locals.push(bindings[i].name)
    }
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }

  // 本体を評価
  codegen_expr(ctx, body)

  // スコープを抜けるので boxed_locals から削除
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

/// letrec 式をコード生成
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

  // body と init 式内で set! される変数を収集
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

  // ボックス化が必要なバインディングを特定
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

  // まず未初期化のスロットを確保
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))

  // ボックス化が必要な変数を boxed_locals に追加（参照時に BoxGet を使うため）
  let mut i = 0
  while i < num_bindings {
    if needs_boxing[i] {
      ctx.boxed_locals.push(bindings[i].name)
    }
    i = i + 1
  }

  // 各バインディングを初期化
  i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    if needs_boxing[i] {
      // ボックス化が必要な場合
      ctx.builder.emit(Opcode::MakeBox)
    }
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }

  // 本体を評価
  codegen_expr(ctx, body)

  // スコープを抜けるので boxed_locals から削除
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

/// set! 式をコード生成
/// 注: オプティマイザーが VarRef のインデックスを調整済み
fn codegen_set(ctx : CodegenContext, var_ref : VarRef, value : IRExpr) -> Unit {
  // depth=0 でボックス化されている場合の処理を判定
  let is_boxed = if var_ref.depth == 0 {
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
  } else {
    false
  }

  if is_boxed {
    // ボックス化されている場合
    ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))  // ボックスをロード
    codegen_expr(ctx, value)  // 新しい値を評価
    ctx.builder.emit(Opcode::BoxSet)  // ボックスを更新
    // set! は void を返す（R5RS）
    let void_idx = ctx.builder.add_const(BCValue::Nil)
    ctx.builder.emit(Opcode::Push(void_idx))
  } else {
    // ボックス化されていない場合
    codegen_expr(ctx, value)
    ctx.builder.emit(Opcode::Dup)  // set! は代入した値を返す
    ctx.builder.emit(Opcode::StoreLocal(var_ref.depth, var_ref.index))
  }
}

/// グローバル set! をコード生成
fn codegen_global_set(ctx : CodegenContext, name : String, value : IRExpr) -> Unit {
  codegen_expr(ctx, value)
  ctx.builder.emit(Opcode::Dup)  // set! は代入した値を返す
  let idx = ctx.builder.add_name(name)
  ctx.builder.emit(Opcode::StoreGlobal(idx))
}

/// プリミティブ操作をコード生成
fn codegen_primop(
  ctx : CodegenContext,
  kind : PrimOpKind,
  args : Array[IRExpr]
) -> Unit {
  // 引数を評価
  for arg in args {
    codegen_expr(ctx, arg)
  }
  // プリミティブ呼び出し
  ctx.builder.emit(Opcode::PrimCall(kind, args.length()))
}

/// call/cc をコード生成
fn codegen_call_cc(ctx : CodegenContext, proc : IRExpr) -> Unit {
  // 手続きを評価
  codegen_expr(ctx, proc)
  // 継続をキャプチャして呼び出す
  ctx.builder.emit(Opcode::CaptureCC)
}

/// quote をコード生成
fn codegen_quote(ctx : CodegenContext, c : IRConst) -> Unit {
  codegen_const(ctx, c)
}

/// delay をコード生成
fn codegen_delay(ctx : CodegenContext, body : IRExpr) -> Unit {
  // 新しいコンテキストで遅延本体をコンパイル
  let delay_ctx = new_context(None)
  delay_ctx.builder.arity = 0
  codegen_expr(delay_ctx, body)
  delay_ctx.builder.emit(Opcode::Return)

  // プロミスチャンクを追加
  let chunk = delay_ctx.builder.build()
  let chunk_idx = ctx.chunks.length()
  ctx.chunks.push(chunk)

  // 子コンテキストのチャンクも追加
  for c in delay_ctx.chunks {
    ctx.chunks.push(c)
  }

  // プロミスを作成
  ctx.builder.emit(Opcode::MakePromise(chunk_idx))
}

/// and 式をコード生成
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
    // false ならそのまま結果として返す（ジャンプ）
    let jump_pos = ctx.builder.current_pos()
    ctx.builder.emit(Opcode::AndJump(0))  // 後でパッチ
    jump_positions.push(jump_pos)
    i = i + 1
  }

  // 最後の式
  codegen_expr(ctx, exprs[len - 1])

  // ジャンプ先をパッチ（すべて end を指す）
  let end_pos = ctx.builder.current_pos()
  for pos in jump_positions {
    ctx.builder.patch(pos, Opcode::AndJump(end_pos))
  }
}

/// or 式をコード生成
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
    // true ならそのまま結果として返す（ジャンプ）
    let jump_pos = ctx.builder.current_pos()
    ctx.builder.emit(Opcode::OrJump(0))  // 後でパッチ
    jump_positions.push(jump_pos)
    i = i + 1
  }

  // 最後の式
  codegen_expr(ctx, exprs[len - 1])

  // ジャンプ先をパッチ（すべて end を指す）
  let end_pos = ctx.builder.current_pos()
  for pos in jump_positions {
    ctx.builder.patch(pos, Opcode::OrJump(end_pos))
  }
}

/// IR をコンパイル済みモジュールに変換
pub fn generate(ir : IRExpr) -> CompiledModule {
  let ctx = new_context(Some("main"))
  codegen_expr(ctx, ir)
  ctx.builder.emit(Opcode::Halt)
  let main_chunk = ctx.builder.build()
  { main: main_chunk, chunks: ctx.chunks }
}

/// SExpr を直接コンパイル済みモジュールに変換（最適化付き）
pub fn compile_to_module(expr : SExpr) -> Result[CompiledModule, CompileError] {
  match compile_toplevel(expr) {
    Ok(ir) => {
      let optimized = optimize(ir)
      Ok(generate(optimized))
    }
    Err(e) => Err(e)
  }
}

/// SExpr を最適化付きでコンパイル済みモジュールに変換
pub fn compile_to_module_optimized(expr : SExpr) -> Result[CompiledModule, CompileError] {
  match compile_toplevel(expr) {
    Ok(ir) => {
      let optimized = optimize(ir)
      Ok(generate(optimized))
    }
    Err(e) => Err(e)
  }
}
