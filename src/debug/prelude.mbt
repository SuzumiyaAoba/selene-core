/// Package-level imports for debug utilities.
using @core { type Value, type Number, type Procedure, type VMCallFrame, type SExpr }
using @compiler { type CodeChunk, type Opcode, type BCValue, type CompiledModule, type PrimOpKind, compile_to_module }
using @runtime { type VMState, type VMError, vm_step, get_gc_stats, new_vm_state }
