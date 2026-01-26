/// バイトコードダンプツール
///
/// コンパイル済みモジュールを人間が読める形式で表示する:
/// - モジュール全体のダンプ
/// - チャンクごとの詳細表示
/// - 命令の逆アセンブル
/// - 定数プール・名前テーブルの表示

/// ダンプオプション
pub(all) struct DumpOptions {
  /// 詳細モード（定数プール、名前テーブルを含める）
  verbose : Bool
  /// 命令アドレスを16進数で表示
  hex_addresses : Bool
  /// 定数値をインラインで表示
  inline_constants : Bool
  /// インデント幅
  indent_width : Int
}

/// デフォルトのダンプオプション
pub fn default_dump_options() -> DumpOptions {
  {
    verbose: true,
    hex_addresses: false,
    inline_constants: true,
    indent_width: 2,
  }
}

/// 簡潔なダンプオプション
pub fn compact_dump_options() -> DumpOptions {
  {
    verbose: false,
    hex_addresses: false,
    inline_constants: true,
    indent_width: 2,
  }
}

/// モジュール全体をダンプ
pub fn dump_module(module : CompiledModule, options : DumpOptions) -> String {
  let mut result = "=".repeat(60) + "\n"
  result = result + "BYTECODE MODULE DUMP\n"
  result = result + "=".repeat(60) + "\n\n"

  // メインチャンク
  result = result + "MAIN CHUNK:\n"
  result = result + "-".repeat(40) + "\n"
  result = result + dump_chunk(module.main, -1, module, options)
  result = result + "\n"

  // 子チャンク
  if module.chunks.length() > 0 {
    result = result + "CHILD CHUNKS (" + module.chunks.length().to_string() + "):\n"
    result = result + "-".repeat(40) + "\n\n"

    let mut i = 0
    while i < module.chunks.length() {
      let chunk = module.chunks[i]
      result = result + "CHUNK #" + i.to_string()
      match chunk.debug_name {
        Some(name) => result = result + " (" + name + ")"
        None => ()
      }
      result = result + ":\n"
      result = result + dump_chunk(chunk, i, module, options)
      result = result + "\n"
      i = i + 1
    }
  }

  result = result + "=".repeat(60) + "\n"
  result = result + "END OF DUMP\n"
  result = result + "=".repeat(60) + "\n"

  result
}

/// 単一チャンクをダンプ
pub fn dump_chunk(
  chunk : CodeChunk,
  chunk_idx : Int,
  module : CompiledModule,
  options : DumpOptions
) -> String {
  let indent = " ".repeat(options.indent_width)
  let mut result = ""

  // 基本情報
  result = result + indent + "Arity: " + chunk.arity.to_string() + "\n"
  result = result + indent + "Locals: " + chunk.num_locals.to_string() + "\n"
  result = result + indent + "Free vars: " + chunk.num_free_vars.to_string() + "\n"
  match chunk.debug_name {
    Some(name) => result = result + indent + "Name: " + name + "\n"
    None => ()
  }
  result = result + "\n"

  // 詳細モードの場合、定数プールと名前テーブルを表示
  if options.verbose {
    result = result + dump_constants(chunk, options)
    result = result + dump_names(chunk, options)
  }

  // コード
  result = result + dump_code(chunk, chunk_idx, module, options)

  result
}

/// 定数プールをダンプ
fn dump_constants(chunk : CodeChunk, options : DumpOptions) -> String {
  if chunk.constants.length() == 0 {
    return ""
  }

  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Constants:\n"

  let mut i = 0
  while i < chunk.constants.length() {
    let const_val = chunk.constants[i]
    result = result + indent + indent + "[" + format_index(i, options) + "] " +
      dump_bc_value(const_val) + "\n"
    i = i + 1
  }
  result = result + "\n"

  result
}

/// 名前テーブルをダンプ
fn dump_names(chunk : CodeChunk, options : DumpOptions) -> String {
  if chunk.names.length() == 0 {
    return ""
  }

  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Names:\n"

  let mut i = 0
  while i < chunk.names.length() {
    result = result + indent + indent + "[" + format_index(i, options) + "] " +
      chunk.names[i] + "\n"
    i = i + 1
  }
  result = result + "\n"

  result
}

/// コードをダンプ（逆アセンブル）
fn dump_code(
  chunk : CodeChunk,
  _chunk_idx : Int,
  _module : CompiledModule,
  options : DumpOptions
) -> String {
  let indent = " ".repeat(options.indent_width)
  let mut result = indent + "Code:\n"

  let mut i = 0
  while i < chunk.code.length() {
    let opcode = chunk.code[i]
    result = result + indent + indent +
      format_address(i, options) + ": " +
      dump_opcode(opcode, chunk, options) + "\n"
    i = i + 1
  }

  result
}

/// インデックスをフォーマット
fn format_index(idx : Int, options : DumpOptions) -> String {
  if options.hex_addresses {
    "0x" + int_to_hex(idx)
  } else {
    idx.to_string()
  }
}

/// アドレスをフォーマット
fn format_address(addr : Int, options : DumpOptions) -> String {
  if options.hex_addresses {
    dump_pad_left("0x" + int_to_hex(addr), 8, ' ')
  } else {
    dump_pad_left(addr.to_string(), 4, ' ')
  }
}

/// 整数を16進数文字列に変換
fn int_to_hex(n : Int) -> String {
  if n == 0 {
    return "0"
  }

  let hex_chars = "0123456789ABCDEF"
  let chars = hex_chars.to_array()
  let mut result = ""
  let mut num = n

  while num > 0 {
    let digit = num % 16
    result = chars[digit].to_string() + result
    num = num / 16
  }

  result
}

/// BCValue をダンプ
fn dump_bc_value(value : BCValue) -> String {
  match value {
    BCValue::Nil => "nil"
    BCValue::Bool(true) => "#t"
    BCValue::Bool(false) => "#f"
    BCValue::Int(n) => "int(" + n.to_string() + ")"
    BCValue::Real(r) => "real(" + r.to_string() + ")"
    BCValue::Char(c) => "char(#\\" + c.to_string() + ")"
    BCValue::String(s) => "string(\"" + escape_string(s) + "\")"
    BCValue::Symbol(s) => "symbol(" + s + ")"
    BCValue::Closure(idx) => "closure(#" + idx.to_string() + ")"
  }
}

/// 文字列をエスケープ
fn escape_string(s : String) -> String {
  let mut result = ""
  let chars = s.to_array()
  for c in chars {
    if c == '\n' {
      result = result + "\\n"
    } else if c == '\t' {
      result = result + "\\t"
    } else if c == '\r' {
      result = result + "\\r"
    } else if c == '"' {
      result = result + "\\\""
    } else if c == '\\' {
      result = result + "\\\\"
    } else {
      result = result + c.to_string()
    }
  }
  result
}

/// オペコードをダンプ
fn dump_opcode(opcode : Opcode, chunk : CodeChunk, options : DumpOptions) -> String {
  match opcode {
    Opcode::Push(idx) => {
      let mut result = "PUSH " + idx.to_string()
      if options.inline_constants && idx < chunk.constants.length() {
        result = result + "  ; " + dump_bc_value(chunk.constants[idx])
      }
      result
    }

    Opcode::Pop => "POP"

    Opcode::LoadLocal(depth, index) =>
      "LOAD_LOCAL " + depth.to_string() + ", " + index.to_string()

    Opcode::StoreLocal(depth, index) =>
      "STORE_LOCAL " + depth.to_string() + ", " + index.to_string()

    Opcode::LoadGlobal(idx) => {
      let mut result = "LOAD_GLOBAL " + idx.to_string()
      if options.inline_constants && idx < chunk.names.length() {
        result = result + "  ; " + chunk.names[idx]
      }
      result
    }

    Opcode::StoreGlobal(idx) => {
      let mut result = "STORE_GLOBAL " + idx.to_string()
      if options.inline_constants && idx < chunk.names.length() {
        result = result + "  ; " + chunk.names[idx]
      }
      result
    }

    Opcode::MakeClosure(chunk_idx, num_captures) =>
      "MAKE_CLOSURE " + chunk_idx.to_string() + ", " + num_captures.to_string()

    Opcode::MakeBox => "MAKE_BOX"

    Opcode::BoxGet => "BOX_GET"

    Opcode::BoxSet => "BOX_SET"

    Opcode::Call(argc) => "CALL " + argc.to_string()

    Opcode::TailCall(argc) => "TAIL_CALL " + argc.to_string()

    Opcode::Return => "RETURN"

    Opcode::Jump(target) => "JUMP " + target.to_string()

    Opcode::JumpIfFalse(target) => "JUMP_IF_FALSE " + target.to_string()

    Opcode::PrimCall(kind, argc) =>
      "PRIM_CALL " + dump_primop_name(kind) + ", " + argc.to_string()

    Opcode::CaptureCC => "CAPTURE_CC"

    Opcode::Halt => "HALT"

    Opcode::MakePair => "MAKE_PAIR"

    Opcode::MakeList(n) => "MAKE_LIST " + n.to_string()

    Opcode::MakeVector(n) => "MAKE_VECTOR " + n.to_string()

    Opcode::MakePromise(chunk_idx) => "MAKE_PROMISE " + chunk_idx.to_string()

    Opcode::AndJump(target) => "AND_JUMP " + target.to_string()

    Opcode::OrJump(target) => "OR_JUMP " + target.to_string()

    Opcode::Dup => "DUP"

    Opcode::AllocateLocals(n) => "ALLOCATE_LOCALS " + n.to_string()

    Opcode::InitLocal(depth, index) =>
      "INIT_LOCAL " + depth.to_string() + ", " + index.to_string()
  }
}

/// PrimOpKind を文字列に変換
fn dump_primop_name(kind : PrimOpKind) -> String {
  match kind {
    // 算術演算
    PrimOpKind::Add => "ADD"
    PrimOpKind::Sub => "SUB"
    PrimOpKind::Mul => "MUL"
    PrimOpKind::Div => "DIV"
    PrimOpKind::Quotient => "QUOTIENT"
    PrimOpKind::Remainder => "REMAINDER"
    PrimOpKind::Modulo => "MODULO"
    PrimOpKind::Abs => "ABS"
    PrimOpKind::Max => "MAX"
    PrimOpKind::Min => "MIN"
    PrimOpKind::Gcd => "GCD"
    PrimOpKind::Lcm => "LCM"
    // 比較演算
    PrimOpKind::NumEq => "NUM_EQ"
    PrimOpKind::Lt => "LT"
    PrimOpKind::Gt => "GT"
    PrimOpKind::Le => "LE"
    PrimOpKind::Ge => "GE"
    PrimOpKind::Eq => "EQ"
    PrimOpKind::Eqv => "EQV"
    PrimOpKind::Equal => "EQUAL"
    // 数値述語
    PrimOpKind::ZeroP => "ZERO_P"
    PrimOpKind::PositiveP => "POSITIVE_P"
    PrimOpKind::NegativeP => "NEGATIVE_P"
    PrimOpKind::OddP => "ODD_P"
    PrimOpKind::EvenP => "EVEN_P"
    // 型述語
    PrimOpKind::PairP => "PAIR_P"
    PrimOpKind::NumberP => "NUMBER_P"
    PrimOpKind::IntegerP => "INTEGER_P"
    PrimOpKind::RealP => "REAL_P"
    PrimOpKind::BooleanP => "BOOLEAN_P"
    PrimOpKind::SymbolP => "SYMBOL_P"
    PrimOpKind::NullP => "NULL_P"
    PrimOpKind::ProcedureP => "PROCEDURE_P"
    PrimOpKind::ListP => "LIST_P"
    PrimOpKind::StringP => "STRING_P"
    PrimOpKind::CharP => "CHAR_P"
    PrimOpKind::VectorP => "VECTOR_P"
    PrimOpKind::PromiseP => "PROMISE_P"
    PrimOpKind::PortP => "PORT_P"
    // リスト操作
    PrimOpKind::Cons => "CONS"
    PrimOpKind::Car => "CAR"
    PrimOpKind::Cdr => "CDR"
    PrimOpKind::SetCar => "SET_CAR"
    PrimOpKind::SetCdr => "SET_CDR"
    PrimOpKind::List => "LIST"
    PrimOpKind::Length => "LENGTH"
    PrimOpKind::Append => "APPEND"
    PrimOpKind::Reverse => "REVERSE"
    PrimOpKind::ListRef => "LIST_REF"
    PrimOpKind::ListTail => "LIST_TAIL"
    // 文字操作
    PrimOpKind::CharEq => "CHAR_EQ"
    PrimOpKind::CharLt => "CHAR_LT"
    PrimOpKind::CharGt => "CHAR_GT"
    PrimOpKind::CharLe => "CHAR_LE"
    PrimOpKind::CharGe => "CHAR_GE"
    PrimOpKind::CharAlphabeticP => "CHAR_ALPHABETIC_P"
    PrimOpKind::CharNumericP => "CHAR_NUMERIC_P"
    PrimOpKind::CharWhitespaceP => "CHAR_WHITESPACE_P"
    PrimOpKind::CharUpperCaseP => "CHAR_UPPER_CASE_P"
    PrimOpKind::CharLowerCaseP => "CHAR_LOWER_CASE_P"
    PrimOpKind::CharUpcase => "CHAR_UPCASE"
    PrimOpKind::CharDowncase => "CHAR_DOWNCASE"
    PrimOpKind::CharToInteger => "CHAR_TO_INTEGER"
    PrimOpKind::IntegerToChar => "INTEGER_TO_CHAR"
    // 文字列操作
    PrimOpKind::StringLength => "STRING_LENGTH"
    PrimOpKind::StringRef => "STRING_REF"
    PrimOpKind::StringAppend => "STRING_APPEND"
    PrimOpKind::StringEq => "STRING_EQ"
    PrimOpKind::StringLt => "STRING_LT"
    PrimOpKind::StringGt => "STRING_GT"
    PrimOpKind::StringLe => "STRING_LE"
    PrimOpKind::StringGe => "STRING_GE"
    PrimOpKind::MakeString => "MAKE_STRING"
    PrimOpKind::Substring => "SUBSTRING"
    PrimOpKind::StringToList => "STRING_TO_LIST"
    PrimOpKind::ListToString => "LIST_TO_STRING"
    // ベクトル操作
    PrimOpKind::MakeVector => "MAKE_VECTOR"
    PrimOpKind::Vector => "VECTOR"
    PrimOpKind::VectorLength => "VECTOR_LENGTH"
    PrimOpKind::VectorRef => "VECTOR_REF"
    PrimOpKind::VectorSet => "VECTOR_SET"
    PrimOpKind::VectorToList => "VECTOR_TO_LIST"
    PrimOpKind::ListToVector => "LIST_TO_VECTOR"
    // 数学関数
    PrimOpKind::Floor => "FLOOR"
    PrimOpKind::Ceiling => "CEILING"
    PrimOpKind::Truncate => "TRUNCATE"
    PrimOpKind::Round => "ROUND"
    PrimOpKind::Sqrt => "SQRT"
    PrimOpKind::Expt => "EXPT"
    PrimOpKind::Sin => "SIN"
    PrimOpKind::Cos => "COS"
    PrimOpKind::Tan => "TAN"
    PrimOpKind::Asin => "ASIN"
    PrimOpKind::Acos => "ACOS"
    PrimOpKind::Atan => "ATAN"
    PrimOpKind::Exp => "EXP"
    PrimOpKind::Log => "LOG"
    // 変換
    PrimOpKind::NumberToString => "NUMBER_TO_STRING"
    PrimOpKind::StringToNumber => "STRING_TO_NUMBER"
    PrimOpKind::SymbolToString => "SYMBOL_TO_STRING"
    PrimOpKind::StringToSymbol => "STRING_TO_SYMBOL"
    // 論理演算
    PrimOpKind::Not => "NOT"
    // 複素数
    PrimOpKind::MakeRectangular => "MAKE_RECTANGULAR"
    PrimOpKind::MakePolar => "MAKE_POLAR"
    PrimOpKind::RealPart => "REAL_PART"
    PrimOpKind::ImagPart => "IMAG_PART"
    PrimOpKind::Magnitude => "MAGNITUDE"
    PrimOpKind::Angle => "ANGLE"
    PrimOpKind::ComplexP => "COMPLEX_P"
    // 有理数
    PrimOpKind::Numerator => "NUMERATOR"
    PrimOpKind::Denominator => "DENOMINATOR"
    PrimOpKind::RationalP => "RATIONAL_P"
    // 数値判定
    PrimOpKind::ExactP => "EXACT_P"
    PrimOpKind::InexactP => "INEXACT_P"
    // I/O
    PrimOpKind::Display => "DISPLAY"
    PrimOpKind::Newline => "NEWLINE"
    PrimOpKind::Write => "WRITE"
    PrimOpKind::Read => "READ"
    // ポート
    PrimOpKind::InputPortP => "INPUT_PORT_P"
    PrimOpKind::OutputPortP => "OUTPUT_PORT_P"
    PrimOpKind::OpenInputFile => "OPEN_INPUT_FILE"
    PrimOpKind::OpenOutputFile => "OPEN_OUTPUT_FILE"
    PrimOpKind::CloseInputPort => "CLOSE_INPUT_PORT"
    PrimOpKind::CloseOutputPort => "CLOSE_OUTPUT_PORT"
    PrimOpKind::ReadChar => "READ_CHAR"
    PrimOpKind::PeekChar => "PEEK_CHAR"
    PrimOpKind::WriteChar => "WRITE_CHAR"
    PrimOpKind::EofObjectP => "EOF_OBJECT_P"
    // 制御
    PrimOpKind::Apply => "APPLY"
    PrimOpKind::Map => "MAP"
    PrimOpKind::ForEach => "FOR_EACH"
    PrimOpKind::Filter => "FILTER"
    PrimOpKind::FoldLeft => "FOLD_LEFT"
    PrimOpKind::FoldRight => "FOLD_RIGHT"
    PrimOpKind::Force => "FORCE"
    PrimOpKind::Values => "VALUES"
    PrimOpKind::CallWithValues => "CALL_WITH_VALUES"
    PrimOpKind::DynamicWind => "DYNAMIC_WIND"
    // 連想リスト
    PrimOpKind::Assq => "ASSQ"
    PrimOpKind::Assv => "ASSV"
    PrimOpKind::Assoc => "ASSOC"
    // メンバーシップ
    PrimOpKind::Memq => "MEMQ"
    PrimOpKind::Memv => "MEMV"
    PrimOpKind::Member => "MEMBER"
    // cXXr アクセサ
    PrimOpKind::Caar => "CAAR"
    PrimOpKind::Cadr => "CADR"
    PrimOpKind::Cdar => "CDAR"
    PrimOpKind::Cddr => "CDDR"
    PrimOpKind::Caaar => "CAAAR"
    PrimOpKind::Caadr => "CAADR"
    PrimOpKind::Cadar => "CADAR"
    PrimOpKind::Caddr => "CADDR"
    PrimOpKind::Cdaar => "CDAAR"
    PrimOpKind::Cdadr => "CDADR"
    PrimOpKind::Cddar => "CDDAR"
    PrimOpKind::Cdddr => "CDDDR"
  }
}

/// 文字列を左パディング
fn dump_pad_left(s : String, width : Int, pad_char : Char) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let mut result = ""
  let mut i = 0
  while i < width - len {
    result = result + pad_char.to_string()
    i = i + 1
  }
  result + s
}

/// 文字列を繰り返し
fn repeat(self : String, n : Int) -> String {
  let mut result = ""
  let mut i = 0
  while i < n {
    result = result + self
    i = i + 1
  }
  result
}

/// S式をコンパイルしてダンプ
pub fn compile_and_dump(source : String, options : DumpOptions) -> Result[String, String] {
  let expr = parse_one(source)
  match compile_to_module(expr) {
    Ok(module) => Ok(dump_module(module, options))
    Err(e) => Err(e.to_string())
  }
}

/// S式をコンパイルしてデフォルトオプションでダンプ
pub fn compile_and_dump_default(source : String) -> Result[String, String] {
  compile_and_dump(source, default_dump_options())
}

/// モジュールの統計情報を取得
pub fn dump_module_stats(module : CompiledModule) -> String {
  let mut result = "Module Statistics:\n"
  result = result + "-".repeat(30) + "\n"

  // メインチャンク統計
  result = result + "Main chunk:\n"
  result = result + "  Code size: " + module.main.code.length().to_string() + " instructions\n"
  result = result + "  Constants: " + module.main.constants.length().to_string() + "\n"
  result = result + "  Names: " + module.main.names.length().to_string() + "\n"

  // 子チャンク統計
  result = result + "Child chunks: " + module.chunks.length().to_string() + "\n"

  let mut total_code = module.main.code.length()
  let mut total_constants = module.main.constants.length()
  let mut total_names = module.main.names.length()

  for chunk in module.chunks {
    total_code = total_code + chunk.code.length()
    total_constants = total_constants + chunk.constants.length()
    total_names = total_names + chunk.names.length()
  }

  result = result + "\nTotals:\n"
  result = result + "  Total code: " + total_code.to_string() + " instructions\n"
  result = result + "  Total constants: " + total_constants.to_string() + "\n"
  result = result + "  Total names: " + total_names.to_string() + "\n"

  // 命令種別の統計
  result = result + "\nInstruction breakdown:\n"
  let instr_counts = count_instructions(module)
  for entry in instr_counts {
    let (name, count) = entry
    if count > 0 {
      result = result + "  " + dump_pad_left(name, 20, ' ') + ": " + count.to_string() + "\n"
    }
  }

  result
}

/// モジュール内の命令をカウント
fn count_instructions(module : CompiledModule) -> Array[(String, Int)] {
  let counts : @hashmap.T[String, Int] = @hashmap.new()

  fn count_chunk(chunk : CodeChunk) {
    for opcode in chunk.code {
      let name = opcode_name(opcode)
      match counts.get(name) {
        Some(n) => counts.set(name, n + 1)
        None => counts.set(name, 1)
      }
    }
  }

  count_chunk(module.main)
  for chunk in module.chunks {
    count_chunk(chunk)
  }

  let result : Array[(String, Int)] = []
  counts.each(fn(name, count) { result.push((name, count)) })

  // 名前でソート
  sort_by_name(result)

  result
}

/// オペコードの名前を取得
fn opcode_name(opcode : Opcode) -> String {
  match opcode {
    Opcode::Push(_) => "Push"
    Opcode::Pop => "Pop"
    Opcode::LoadLocal(_, _) => "LoadLocal"
    Opcode::StoreLocal(_, _) => "StoreLocal"
    Opcode::LoadGlobal(_) => "LoadGlobal"
    Opcode::StoreGlobal(_) => "StoreGlobal"
    Opcode::MakeClosure(_, _) => "MakeClosure"
    Opcode::MakeBox => "MakeBox"
    Opcode::BoxGet => "BoxGet"
    Opcode::BoxSet => "BoxSet"
    Opcode::Call(_) => "Call"
    Opcode::TailCall(_) => "TailCall"
    Opcode::Return => "Return"
    Opcode::Jump(_) => "Jump"
    Opcode::JumpIfFalse(_) => "JumpIfFalse"
    Opcode::PrimCall(_, _) => "PrimCall"
    Opcode::CaptureCC => "CaptureCC"
    Opcode::Halt => "Halt"
    Opcode::MakePair => "MakePair"
    Opcode::MakeList(_) => "MakeList"
    Opcode::MakeVector(_) => "MakeVector"
    Opcode::MakePromise(_) => "MakePromise"
    Opcode::AndJump(_) => "AndJump"
    Opcode::OrJump(_) => "OrJump"
    Opcode::Dup => "Dup"
    Opcode::AllocateLocals(_) => "AllocateLocals"
    Opcode::InitLocal(_, _) => "InitLocal"
  }
}

/// 名前でソート
fn sort_by_name(list : Array[(String, Int)]) -> Unit {
  let n = list.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if list[j].0 > list[j + 1].0 {
        let temp = list[j]
        list[j] = list[j + 1]
        list[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
}
