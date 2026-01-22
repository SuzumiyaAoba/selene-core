/// コード生成 (IR → バイトコード)
///
/// 中間表現からバイトコードを生成する

/// コード生成コンテキスト
struct CodegenContext {
  /// メインビルダー
  builder : CodeChunkBuilder
  /// 生成された子チャンク（ネストした関数）
  chunks : Array[CodeChunk]
}

/// 新しいコンテキストを作成
fn new_context(debug_name : String?) -> CodegenContext {
  { builder: new_builder(debug_name), chunks: [] }
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
fn codegen_var(ctx : CodegenContext, var_ref : VarRef) -> Unit {
  ctx.builder.emit(Opcode::LoadLocal(var_ref.depth, var_ref.index))
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
  // 新しいコンテキストで関数本体をコンパイル
  let func_ctx = new_context(None)
  func_ctx.builder.arity = info.arity
  func_ctx.builder.num_locals = info.params.length()

  // 本体をコンパイル
  codegen_expr(func_ctx, info.body)
  func_ctx.builder.emit(Opcode::Return)

  // 関数チャンクを追加
  let func_chunk = func_ctx.builder.build()
  let chunk_idx = ctx.chunks.length()
  ctx.chunks.push(func_chunk)

  // 子コンテキストのチャンクも追加
  for chunk in func_ctx.chunks {
    ctx.chunks.push(chunk)
  }

  // クロージャを作成
  ctx.builder.emit(Opcode::MakeClosure(chunk_idx))
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
  // 各バインディングの初期値を評価してスタックに積む
  for binding in bindings {
    codegen_expr(ctx, binding.init)
  }
  // 本体を評価
  codegen_expr(ctx, body)
  // バインディングの数だけローカル変数を解放（スタックから除去）
  // 注: 実際の VM では環境フレームを使うため、ここでは特に何もしない
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
fn codegen_set(ctx : CodegenContext, var_ref : VarRef, value : IRExpr) -> Unit {
  codegen_expr(ctx, value)
  ctx.builder.emit(Opcode::Dup)  // set! は代入した値を返す
  ctx.builder.emit(Opcode::StoreLocal(var_ref.depth, var_ref.index))
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

/// SExpr を直接コンパイル済みモジュールに変換
pub fn compile_to_module(expr : SExpr) -> Result[CompiledModule, CompileError] {
  match compile_toplevel(expr) {
    Ok(ir) => Ok(generate(ir))
    Err(e) => Err(e)
  }
}
