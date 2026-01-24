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
  // パラメータのローカルインデックスを調整（キャプチャの後ろにある）
  let adjusted_boxed_params : Array[Int] = []
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
  for param_local_idx in adjusted_boxed_params {
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
  for var_ref in info.free_vars {
    codegen_expr(ctx, IRExpr::Var(var_ref))
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

  // ローカル変数スロットを確保
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))

  // 各バインディングの初期値を評価してローカル変数に格納
  let mut i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }

  // 本体を評価
  codegen_expr(ctx, body)
}

/// letrec 式をコード生成
fn codegen_letrec(
  ctx : CodegenContext,
  bindings : Array[LetBinding],
  body : IRExpr
) -> Unit {
  let num_bindings = bindings.length()
  // まず未初期化のスロットを確保
  ctx.builder.emit(Opcode::AllocateLocals(num_bindings))
  // 各バインディングを初期化
  let mut i = 0
  while i < num_bindings {
    codegen_expr(ctx, bindings[i].init)
    ctx.builder.emit(Opcode::InitLocal(0, i))
    i = i + 1
  }
  // 本体を評価
  codegen_expr(ctx, body)
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
