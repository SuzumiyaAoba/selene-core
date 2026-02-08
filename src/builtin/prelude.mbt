/// Package-level imports for builtin functions.
using @core {
  type Value,
  type Number,
  type EvalError,
  type Procedure,
  type Promise,
  type Port,
  type PortDirection,
  type Continuation,
  type ContinuationCall,
  type SyntaxRules,
  type SyntaxRule,
  normalize_rational,
  new_port_id,
  sexpr_to_value,
  values_eqv,
  make_pair,
}
using @frontend { parse_one }
using @ffi {
  read_line,
  open_input_file,
  open_output_file,
  read_char_from_port,
  peek_char_from_port,
  write_char_to_port,
  close_port,
}
