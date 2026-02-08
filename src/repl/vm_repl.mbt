/// VM REPL context
///
/// Run multiple expressions sequentially and share chunks with the global environment

/// REPL context
pub(all) struct VMReplContext {
  /// global variable (value)
  globals : @hashmap.T[String, Value]
  /// Global variables for compiler (name only)
  compiler_globals : @hashmap.T[String, Unit]
  /// accumulated chunks
  chunks : Array[CodeChunk]
  /// Macro environment
  macro_env : MacroEnv
}

/// Create a new REPL context
pub fn new_repl_context() -> VMReplContext {
  let ctx : VMReplContext = {
    globals: create_initial_globals(),
    compiler_globals: initial_globals(),
    chunks: [],
    macro_env: new_macro_env(),
  }
  init_prelude(ctx)
  ctx
}

/// Initialize Scheme prelude (define map/for-each as Scheme functions
/// so they run in the main VM and call/cc works correctly inside them)
fn init_prelude(ctx : VMReplContext) -> Unit {
  let prelude = [
    // map: single-list and multi-list support
    "(define (map f . lsts) (if (null? (cdr lsts)) (let loop ((lst (car lsts))) (if (null? lst) '() (cons (f (car lst)) (loop (cdr lst))))) (let loop ((lsts lsts)) (if (null? (car lsts)) '() (cons (apply f (map car lsts)) (loop (map cdr lsts)))))))",
    // for-each: same structure as map but discards results
    "(define (for-each f . lsts) (if (null? (cdr lsts)) (let loop ((lst (car lsts))) (if (not (null? lst)) (begin (f (car lst)) (loop (cdr lst))))) (let loop ((lsts lsts)) (if (not (null? (car lsts))) (begin (apply f (map car lsts)) (loop (map cdr lsts)))))))",
  ]
  for code in prelude {
    match repl_eval(ctx, code) {
      Ok(_) => ()
      Err(_) => ()
    }
  }
}

/// Evaluate expressions in REPL context
pub fn repl_eval(ctx : VMReplContext, input : String) -> Result[Value, String] {
  let expr = parse_one(input)
  repl_eval_expr(ctx, expr)
}

/// Evaluate SExpr in REPL context
pub fn repl_eval_expr(ctx : VMReplContext, expr : SExpr) -> Result[Value, String] {
  // Expand macros first
  let expanded_expr = match expand_toplevel(expr, ctx.macro_env) {
    Ok(result) => {
      match result.expr {
        Some(e) => e
        None =>
          // define-syntax only, return Void
          return Ok(Value::Nil)
      }
    }
    Err(e) => return Err("Macro Error: " + e.to_string())
  }

  // compile
  match compile_toplevel_with_globals(expanded_expr, ctx.compiler_globals) {
    Ok(ir) => {
      // optimization
      let optimized = optimize(ir)
      // code generation
      let compiled_module = generate(optimized)

      // Calculate chunk offset (number of existing chunks)
      let chunk_offset = ctx.chunks.length()

      // Add new chunk to cumulative list (with offset adjustment)
      for chunk in compiled_module.chunks {
        let adjusted = adjust_chunk_refs(chunk, chunk_offset)
        ctx.chunks.push(adjusted)
      }

      // Offset adjustment of chunk reference of main chunk
      let adjusted_main = adjust_chunk_refs(compiled_module.main, chunk_offset)

      // Build module for VM (using cumulative chunks)
      let vm_module : CompiledModule = {
        main: adjusted_main,
        chunks: ctx.chunks,
      }

      // Run in VM
      let vm = new_vm_state_with_globals(vm_module, ctx.globals)
      match vm_run(vm) {
        Ok(value) => {
          // For GlobalSet, register global variables
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

/// Offset adjustment of chunk references within chunks
fn adjust_chunk_refs(chunk : CodeChunk, offset : Int) -> CodeChunk {
  if offset == 0 {
    return chunk
  }

  let new_code : Array[Opcode] = []
  for op in chunk.code {
    let adjusted = match op {
      Opcode::MakeClosure(chunk_idx, num_captures) => Opcode::MakeClosure(chunk_idx + offset, num_captures)
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
    has_rest_param: chunk.has_rest_param,
    num_free_vars: chunk.num_free_vars,
    num_locals: chunk.num_locals,
    debug_name: chunk.debug_name,
  }
}
