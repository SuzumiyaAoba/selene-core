/// VM REPL コンテキスト
///
/// 複数の式を順次実行し、グローバル環境とチャンクを共有する

/// REPL コンテキスト
pub(all) struct VMReplContext {
  /// グローバル変数（値）
  globals : @hashmap.T[String, Value]
  /// コンパイラ用グローバル変数（名前のみ）
  compiler_globals : @hashmap.T[String, Unit]
  /// 累積されたチャンク
  chunks : Array[CodeChunk]
}

/// 新しい REPL コンテキストを作成
pub fn new_repl_context() -> VMReplContext {
  {
    globals: create_initial_globals(),
    compiler_globals: initial_globals(),
    chunks: [],
  }
}

/// REPL コンテキストで式を評価
pub fn repl_eval(ctx : VMReplContext, input : String) -> Result[Value, String] {
  let expr = parse_one(input)
  repl_eval_expr(ctx, expr)
}

/// REPL コンテキストで SExpr を評価
pub fn repl_eval_expr(ctx : VMReplContext, expr : SExpr) -> Result[Value, String] {
  // コンパイル
  match compile_toplevel_with_globals(expr, ctx.compiler_globals) {
    Ok(ir) => {
      // 最適化
      let optimized = optimize(ir)
      // コード生成
      let compiled_module = generate(optimized)

      // チャンクのオフセットを計算（既存のチャンク数）
      let chunk_offset = ctx.chunks.length()

      // 新しいチャンクを累積リストに追加（オフセット調整付き）
      for chunk in compiled_module.chunks {
        let adjusted = adjust_chunk_refs(chunk, chunk_offset)
        ctx.chunks.push(adjusted)
      }

      // メインチャンクのチャンク参照をオフセット調整
      let adjusted_main = adjust_chunk_refs(compiled_module.main, chunk_offset)

      // VM 用のモジュールを構築（累積チャンクを使用）
      let vm_module : CompiledModule = {
        main: adjusted_main,
        chunks: ctx.chunks,
      }

      // VM で実行
      let vm = new_vm_state_with_globals(vm_module, ctx.globals)
      match vm_run(vm) {
        Ok(value) => {
          // GlobalSet の場合はグローバル変数を登録
          match optimized {
            IRExpr::GlobalSet(name, _) => {
              ctx.compiler_globals.set(name, ())
            }
            _ => ()
          }
          Ok(value)
        }
        Err(e) => Err("VM Error: " + e.to_string())
      }
    }
    Err(e) => Err("Compile Error: " + e.to_string())
  }
}

/// チャンク内のチャンク参照をオフセット調整
fn adjust_chunk_refs(chunk : CodeChunk, offset : Int) -> CodeChunk {
  if offset == 0 {
    return chunk
  }

  let new_code : Array[Opcode] = []
  for op in chunk.code {
    let adjusted = match op {
      Opcode::MakeClosure(idx) => Opcode::MakeClosure(idx + offset)
      Opcode::MakePromise(idx) => Opcode::MakePromise(idx + offset)
      other => other
    }
    new_code.push(adjusted)
  }

  {
    code: new_code,
    constants: chunk.constants,
    names: chunk.names,
    arity: chunk.arity,
    num_free_vars: chunk.num_free_vars,
    num_locals: chunk.num_locals,
    debug_name: chunk.debug_name,
  }
}

