/// Package-level imports for tests.
using @core {
  type Value,
  type Number,
  type SExpr,
  type Env,
  type EvalError,
  type Procedure,
  type Promise,
  type Port,
  type PortDirection,
  type Continuation,
  type ContinuationCall,
  type SyntaxRules,
  type SyntaxRule,
}
using @frontend { type Token, tokenize, parse, parse_one, parse_tokens, expand_quote }
using @runtime { eval, initial_env, create_initial_globals, new_vm_state, new_vm_state_with_globals, vm_run }
using @compiler {
  type IRExpr,
  type IRConst,
  type CodeChunk,
  type CompiledModule,
  type Opcode,
  compile_toplevel,
  compile_toplevel_with_globals,
  optimize,
  generate,
  compile_to_module,
  compile_to_module_optimized,
  initial_globals,
}
using @repl { new_repl_context, repl_eval, repl_eval_expr }
using @debug {
  new_debugger,
  debug_run,
  new_profiler,
  profiler_reset,
  profiler_enable,
  profiler_disable,
  profiler_record_instruction,
  profiler_record_call,
  profiler_record_return,
  profiler_instruction_report,
  profiler_function_report,
  profiler_hotspot_report,
  profiler_summary,
  profiler_full_report,
  serialize_module_to_string,
  deserialize_module_from_string,
  serialize_module_to_binary,
  deserialize_module_from_binary,
}
