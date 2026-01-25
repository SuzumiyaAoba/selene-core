/// バイトコードのシリアライズ/デシリアライズ
///
/// テキスト形式でコンパイル済みモジュールを保存・読み込み
/// (バイナリ形式は将来の実装に委ねる)

/// シリアライズエラー
pub(all) enum SerializeError {
  InvalidFormat(String)
  UnexpectedEnd
  InvalidOpcode(String)
  InvalidBCValueType(String)
  InvalidPrimOpKind(String)
} derive(Show)

/// PrimOpKind を文字列に変換
fn primop_to_string(kind : PrimOpKind) -> String {
  kind.to_string()
}

/// 文字列から PrimOpKind に変換
fn string_to_primop(s : String) -> Result[PrimOpKind, SerializeError] {
  match s {
    "Add" => Ok(PrimOpKind::Add)
    "Sub" => Ok(PrimOpKind::Sub)
    "Mul" => Ok(PrimOpKind::Mul)
    "Div" => Ok(PrimOpKind::Div)
    "Quotient" => Ok(PrimOpKind::Quotient)
    "Remainder" => Ok(PrimOpKind::Remainder)
    "Modulo" => Ok(PrimOpKind::Modulo)
    "Abs" => Ok(PrimOpKind::Abs)
    "Max" => Ok(PrimOpKind::Max)
    "Min" => Ok(PrimOpKind::Min)
    "Gcd" => Ok(PrimOpKind::Gcd)
    "Lcm" => Ok(PrimOpKind::Lcm)
    "NumEq" => Ok(PrimOpKind::NumEq)
    "Lt" => Ok(PrimOpKind::Lt)
    "Gt" => Ok(PrimOpKind::Gt)
    "Le" => Ok(PrimOpKind::Le)
    "Ge" => Ok(PrimOpKind::Ge)
    "Eq" => Ok(PrimOpKind::Eq)
    "Eqv" => Ok(PrimOpKind::Eqv)
    "Equal" => Ok(PrimOpKind::Equal)
    "ZeroP" => Ok(PrimOpKind::ZeroP)
    "PositiveP" => Ok(PrimOpKind::PositiveP)
    "NegativeP" => Ok(PrimOpKind::NegativeP)
    "OddP" => Ok(PrimOpKind::OddP)
    "EvenP" => Ok(PrimOpKind::EvenP)
    "PairP" => Ok(PrimOpKind::PairP)
    "NumberP" => Ok(PrimOpKind::NumberP)
    "IntegerP" => Ok(PrimOpKind::IntegerP)
    "RealP" => Ok(PrimOpKind::RealP)
    "BooleanP" => Ok(PrimOpKind::BooleanP)
    "SymbolP" => Ok(PrimOpKind::SymbolP)
    "NullP" => Ok(PrimOpKind::NullP)
    "ProcedureP" => Ok(PrimOpKind::ProcedureP)
    "ListP" => Ok(PrimOpKind::ListP)
    "StringP" => Ok(PrimOpKind::StringP)
    "CharP" => Ok(PrimOpKind::CharP)
    "VectorP" => Ok(PrimOpKind::VectorP)
    "PromiseP" => Ok(PrimOpKind::PromiseP)
    "PortP" => Ok(PrimOpKind::PortP)
    "Cons" => Ok(PrimOpKind::Cons)
    "Car" => Ok(PrimOpKind::Car)
    "Cdr" => Ok(PrimOpKind::Cdr)
    "SetCar" => Ok(PrimOpKind::SetCar)
    "SetCdr" => Ok(PrimOpKind::SetCdr)
    "List" => Ok(PrimOpKind::List)
    "Length" => Ok(PrimOpKind::Length)
    "Append" => Ok(PrimOpKind::Append)
    "Reverse" => Ok(PrimOpKind::Reverse)
    "ListRef" => Ok(PrimOpKind::ListRef)
    "ListTail" => Ok(PrimOpKind::ListTail)
    "CharEq" => Ok(PrimOpKind::CharEq)
    "CharLt" => Ok(PrimOpKind::CharLt)
    "CharGt" => Ok(PrimOpKind::CharGt)
    "CharLe" => Ok(PrimOpKind::CharLe)
    "CharGe" => Ok(PrimOpKind::CharGe)
    "CharAlphabeticP" => Ok(PrimOpKind::CharAlphabeticP)
    "CharNumericP" => Ok(PrimOpKind::CharNumericP)
    "CharWhitespaceP" => Ok(PrimOpKind::CharWhitespaceP)
    "CharUpperCaseP" => Ok(PrimOpKind::CharUpperCaseP)
    "CharLowerCaseP" => Ok(PrimOpKind::CharLowerCaseP)
    "CharUpcase" => Ok(PrimOpKind::CharUpcase)
    "CharDowncase" => Ok(PrimOpKind::CharDowncase)
    "CharToInteger" => Ok(PrimOpKind::CharToInteger)
    "IntegerToChar" => Ok(PrimOpKind::IntegerToChar)
    "StringLength" => Ok(PrimOpKind::StringLength)
    "StringRef" => Ok(PrimOpKind::StringRef)
    "StringAppend" => Ok(PrimOpKind::StringAppend)
    "StringEq" => Ok(PrimOpKind::StringEq)
    "StringLt" => Ok(PrimOpKind::StringLt)
    "StringGt" => Ok(PrimOpKind::StringGt)
    "StringLe" => Ok(PrimOpKind::StringLe)
    "StringGe" => Ok(PrimOpKind::StringGe)
    "MakeString" => Ok(PrimOpKind::MakeString)
    "Substring" => Ok(PrimOpKind::Substring)
    "StringToList" => Ok(PrimOpKind::StringToList)
    "ListToString" => Ok(PrimOpKind::ListToString)
    "MakeVector" => Ok(PrimOpKind::MakeVector)
    "Vector" => Ok(PrimOpKind::Vector)
    "VectorLength" => Ok(PrimOpKind::VectorLength)
    "VectorRef" => Ok(PrimOpKind::VectorRef)
    "VectorSet" => Ok(PrimOpKind::VectorSet)
    "VectorToList" => Ok(PrimOpKind::VectorToList)
    "ListToVector" => Ok(PrimOpKind::ListToVector)
    "Floor" => Ok(PrimOpKind::Floor)
    "Ceiling" => Ok(PrimOpKind::Ceiling)
    "Truncate" => Ok(PrimOpKind::Truncate)
    "Round" => Ok(PrimOpKind::Round)
    "Sqrt" => Ok(PrimOpKind::Sqrt)
    "Expt" => Ok(PrimOpKind::Expt)
    "Sin" => Ok(PrimOpKind::Sin)
    "Cos" => Ok(PrimOpKind::Cos)
    "Tan" => Ok(PrimOpKind::Tan)
    "Asin" => Ok(PrimOpKind::Asin)
    "Acos" => Ok(PrimOpKind::Acos)
    "Atan" => Ok(PrimOpKind::Atan)
    "Exp" => Ok(PrimOpKind::Exp)
    "Log" => Ok(PrimOpKind::Log)
    "NumberToString" => Ok(PrimOpKind::NumberToString)
    "StringToNumber" => Ok(PrimOpKind::StringToNumber)
    "SymbolToString" => Ok(PrimOpKind::SymbolToString)
    "StringToSymbol" => Ok(PrimOpKind::StringToSymbol)
    "Not" => Ok(PrimOpKind::Not)
    "MakeRectangular" => Ok(PrimOpKind::MakeRectangular)
    "MakePolar" => Ok(PrimOpKind::MakePolar)
    "RealPart" => Ok(PrimOpKind::RealPart)
    "ImagPart" => Ok(PrimOpKind::ImagPart)
    "Magnitude" => Ok(PrimOpKind::Magnitude)
    "Angle" => Ok(PrimOpKind::Angle)
    "ComplexP" => Ok(PrimOpKind::ComplexP)
    "Numerator" => Ok(PrimOpKind::Numerator)
    "Denominator" => Ok(PrimOpKind::Denominator)
    "RationalP" => Ok(PrimOpKind::RationalP)
    "ExactP" => Ok(PrimOpKind::ExactP)
    "InexactP" => Ok(PrimOpKind::InexactP)
    "Display" => Ok(PrimOpKind::Display)
    "Newline" => Ok(PrimOpKind::Newline)
    "Write" => Ok(PrimOpKind::Write)
    "Read" => Ok(PrimOpKind::Read)
    "InputPortP" => Ok(PrimOpKind::InputPortP)
    "OutputPortP" => Ok(PrimOpKind::OutputPortP)
    "OpenInputFile" => Ok(PrimOpKind::OpenInputFile)
    "OpenOutputFile" => Ok(PrimOpKind::OpenOutputFile)
    "CloseInputPort" => Ok(PrimOpKind::CloseInputPort)
    "CloseOutputPort" => Ok(PrimOpKind::CloseOutputPort)
    "ReadChar" => Ok(PrimOpKind::ReadChar)
    "PeekChar" => Ok(PrimOpKind::PeekChar)
    "WriteChar" => Ok(PrimOpKind::WriteChar)
    "EofObjectP" => Ok(PrimOpKind::EofObjectP)
    "Apply" => Ok(PrimOpKind::Apply)
    "Map" => Ok(PrimOpKind::Map)
    "ForEach" => Ok(PrimOpKind::ForEach)
    "Filter" => Ok(PrimOpKind::Filter)
    "FoldLeft" => Ok(PrimOpKind::FoldLeft)
    "FoldRight" => Ok(PrimOpKind::FoldRight)
    "Force" => Ok(PrimOpKind::Force)
    "Values" => Ok(PrimOpKind::Values)
    "CallWithValues" => Ok(PrimOpKind::CallWithValues)
    "DynamicWind" => Ok(PrimOpKind::DynamicWind)
    "Assq" => Ok(PrimOpKind::Assq)
    "Assv" => Ok(PrimOpKind::Assv)
    "Assoc" => Ok(PrimOpKind::Assoc)
    "Memq" => Ok(PrimOpKind::Memq)
    "Memv" => Ok(PrimOpKind::Memv)
    "Member" => Ok(PrimOpKind::Member)
    "Caar" => Ok(PrimOpKind::Caar)
    "Cadr" => Ok(PrimOpKind::Cadr)
    "Cdar" => Ok(PrimOpKind::Cdar)
    "Cddr" => Ok(PrimOpKind::Cddr)
    "Caaar" => Ok(PrimOpKind::Caaar)
    "Caadr" => Ok(PrimOpKind::Caadr)
    "Cadar" => Ok(PrimOpKind::Cadar)
    "Caddr" => Ok(PrimOpKind::Caddr)
    "Cdaar" => Ok(PrimOpKind::Cdaar)
    "Cdadr" => Ok(PrimOpKind::Cdadr)
    "Cddar" => Ok(PrimOpKind::Cddar)
    "Cdddr" => Ok(PrimOpKind::Cdddr)
    _ => Err(SerializeError::InvalidPrimOpKind(s))
  }
}

/// BCValue を文字列に変換
fn bc_value_to_str(v : BCValue) -> String {
  v.to_string()
}

/// Opcode を文字列に変換
fn opcode_to_str(op : Opcode) -> String {
  op.to_string()
}

/// CodeChunk を文字列に変換
fn chunk_to_str(chunk : CodeChunk) -> String {
  let mut result = ""
  result = result + "arity:" + chunk.arity.to_string() + "\n"
  result = result + "num_free_vars:" + chunk.num_free_vars.to_string() + "\n"
  result = result + "num_locals:" + chunk.num_locals.to_string() + "\n"
  match chunk.debug_name {
    Some(name) => result = result + "debug_name:" + name + "\n"
    None => result = result + "debug_name:\n"
  }

  // 定数
  result = result + "constants:" + chunk.constants.length().to_string() + "\n"
  for c in chunk.constants {
    result = result + bc_value_to_str(c) + "\n"
  }

  // 名前
  result = result + "names:" + chunk.names.length().to_string() + "\n"
  for name in chunk.names {
    result = result + name + "\n"
  }

  // コード
  result = result + "code:" + chunk.code.length().to_string() + "\n"
  for op in chunk.code {
    result = result + opcode_to_str(op) + "\n"
  }

  result
}

/// CompiledModule を文字列にシリアライズ
pub fn serialize_module_to_string(m : CompiledModule) -> String {
  let mut result = "SELENE_BYTECODE_V1\n"

  // メインチャンク
  result = result + "main_chunk:\n"
  result = result + chunk_to_str(m.main)

  // 子チャンク
  result = result + "chunks:" + m.chunks.length().to_string() + "\n"
  for chunk in m.chunks {
    result = result + "chunk:\n"
    result = result + chunk_to_str(chunk)
  }

  result
}

/// ========================================
/// デシリアライズ
/// ========================================

/// 文字列のスライスを取得
fn str_slice(s : String, start : Int, end : Int) -> String {
  let chars : Array[Char] = s.iter().collect()
  let mut result = ""
  let mut i = start
  while i < end && i < chars.length() {
    result = result + chars[i].to_string()
    i = i + 1
  }
  result
}

/// 安全に整数をパース
fn safe_parse_int(s : String) -> Result[Int, SerializeError] {
  let result = try? @strconv.parse_int(s)
  match result {
    Ok(n) => Ok(n)
    Err(_) => Err(SerializeError::InvalidFormat("Cannot parse int: " + s))
  }
}

/// 安全に実数をパース
fn safe_parse_double(s : String) -> Result[Double, SerializeError] {
  let result = try? @strconv.parse_double(s)
  match result {
    Ok(d) => Ok(d)
    Err(_) => Err(SerializeError::InvalidFormat("Cannot parse double: " + s))
  }
}

/// 文字列から BCValue に変換
fn string_to_bc_value(s : String) -> Result[BCValue, SerializeError] {
  if s == "Nil" {
    return Ok(BCValue::Nil)
  }
  if s.has_prefix("Bool(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    match inner {
      "true" => return Ok(BCValue::Bool(true))
      "false" => return Ok(BCValue::Bool(false))
      _ => return Err(SerializeError::InvalidBCValueType(s))
    }
  }
  if s.has_prefix("Int(") && s.has_suffix(")") {
    let inner = str_slice(s, 4, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(BCValue::Int(n))
      Err(_) => return Err(SerializeError::InvalidBCValueType(s))
    }
  }
  if s.has_prefix("Real(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    match safe_parse_double(inner) {
      Ok(r) => return Ok(BCValue::Real(r))
      Err(_) => return Err(SerializeError::InvalidBCValueType(s))
    }
  }
  if s.has_prefix("Char(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    // 'x' 形式
    if inner.length() >= 3 && inner.has_prefix("'") && inner.has_suffix("'") {
      let char_str = str_slice(inner, 1, inner.length() - 1)
      if char_str.length() == 1 {
        let chars : Array[Char] = char_str.iter().collect()
        if chars.length() > 0 {
          return Ok(BCValue::Char(chars[0]))
        }
      }
    }
    return Err(SerializeError::InvalidBCValueType(s))
  }
  if s.has_prefix("String(") && s.has_suffix(")") {
    let inner = str_slice(s, 7, s.length() - 1)
    // "xxx" 形式
    if inner.length() >= 2 && inner.has_prefix("\"") && inner.has_suffix("\"") {
      let str_content = str_slice(inner, 1, inner.length() - 1)
      return Ok(BCValue::String(str_content))
    }
    return Err(SerializeError::InvalidBCValueType(s))
  }
  if s.has_prefix("Symbol(") && s.has_suffix(")") {
    let inner = str_slice(s, 7, s.length() - 1)
    return Ok(BCValue::Symbol(inner))
  }
  if s.has_prefix("Closure(") && s.has_suffix(")") {
    let inner = str_slice(s, 8, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(BCValue::Closure(n))
      Err(_) => return Err(SerializeError::InvalidBCValueType(s))
    }
  }
  Err(SerializeError::InvalidBCValueType(s))
}

/// 文字列から Opcode に変換
fn string_to_opcode(s : String) -> Result[Opcode, SerializeError] {
  // 引数なしのオペコード
  match s {
    "Pop" => return Ok(Opcode::Pop)
    "MakeBox" => return Ok(Opcode::MakeBox)
    "BoxGet" => return Ok(Opcode::BoxGet)
    "BoxSet" => return Ok(Opcode::BoxSet)
    "Return" => return Ok(Opcode::Return)
    "CaptureCC" => return Ok(Opcode::CaptureCC)
    "Halt" => return Ok(Opcode::Halt)
    "MakePair" => return Ok(Opcode::MakePair)
    "Dup" => return Ok(Opcode::Dup)
    _ => ()
  }

  // 1引数のオペコード
  if s.has_prefix("Push(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::Push(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("LoadGlobal(") && s.has_suffix(")") {
    let inner = str_slice(s, 11, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::LoadGlobal(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("StoreGlobal(") && s.has_suffix(")") {
    let inner = str_slice(s, 12, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::StoreGlobal(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("Call(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::Call(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("TailCall(") && s.has_suffix(")") {
    let inner = str_slice(s, 9, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::TailCall(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("Jump(") && s.has_suffix(")") {
    let inner = str_slice(s, 5, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::Jump(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("JumpIfFalse(") && s.has_suffix(")") {
    let inner = str_slice(s, 12, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::JumpIfFalse(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("MakeList(") && s.has_suffix(")") {
    let inner = str_slice(s, 9, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::MakeList(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("MakeVector(") && s.has_suffix(")") {
    let inner = str_slice(s, 11, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::MakeVector(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("MakePromise(") && s.has_suffix(")") {
    let inner = str_slice(s, 12, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::MakePromise(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("AndJump(") && s.has_suffix(")") {
    let inner = str_slice(s, 8, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::AndJump(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("OrJump(") && s.has_suffix(")") {
    let inner = str_slice(s, 7, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::OrJump(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }
  if s.has_prefix("AllocateLocals(") && s.has_suffix(")") {
    let inner = str_slice(s, 15, s.length() - 1)
    match safe_parse_int(inner) {
      Ok(n) => return Ok(Opcode::AllocateLocals(n))
      Err(_) => return Err(SerializeError::InvalidOpcode(s))
    }
  }

  // 2引数のオペコード
  if s.has_prefix("LoadLocal(") && s.has_suffix(")") {
    let inner = str_slice(s, 10, s.length() - 1)
    match parse_two_ints(inner) {
      Ok((a, b)) => return Ok(Opcode::LoadLocal(a, b))
      Err(e) => return Err(e)
    }
  }
  if s.has_prefix("StoreLocal(") && s.has_suffix(")") {
    let inner = str_slice(s, 11, s.length() - 1)
    match parse_two_ints(inner) {
      Ok((a, b)) => return Ok(Opcode::StoreLocal(a, b))
      Err(e) => return Err(e)
    }
  }
  if s.has_prefix("MakeClosure(") && s.has_suffix(")") {
    let inner = str_slice(s, 12, s.length() - 1)
    match parse_two_ints(inner) {
      Ok((a, b)) => return Ok(Opcode::MakeClosure(a, b))
      Err(e) => return Err(e)
    }
  }
  if s.has_prefix("InitLocal(") && s.has_suffix(")") {
    let inner = str_slice(s, 10, s.length() - 1)
    match parse_two_ints(inner) {
      Ok((a, b)) => return Ok(Opcode::InitLocal(a, b))
      Err(e) => return Err(e)
    }
  }

  // PrimCall
  if s.has_prefix("PrimCall(") && s.has_suffix(")") {
    let inner = str_slice(s, 9, s.length() - 1)
    match parse_primcall(inner) {
      Ok((kind, arity)) => return Ok(Opcode::PrimCall(kind, arity))
      Err(e) => return Err(e)
    }
  }

  Err(SerializeError::InvalidOpcode(s))
}

/// 空白を除去
fn trim_spaces(s : String) -> String {
  let chars : Array[Char] = s.iter().collect()
  // 先頭の空白をスキップ
  let mut start = 0
  while start < chars.length() && chars[start] == ' ' {
    start = start + 1
  }
  // 末尾の空白をスキップ
  let mut end = chars.length()
  while end > start && chars[end - 1] == ' ' {
    end = end - 1
  }
  // 結果を構築
  let mut result = ""
  let mut i = start
  while i < end {
    result = result + chars[i].to_string()
    i = i + 1
  }
  result
}

/// "a, b" 形式の文字列から2つの整数をパース
fn parse_two_ints(s : String) -> Result[(Int, Int), SerializeError] {
  let parts = split_by_comma(s)
  if parts.length() != 2 {
    return Err(SerializeError::InvalidFormat("Expected 2 integers: " + s))
  }
  let a_str = trim_spaces(parts[0])
  let b_str = trim_spaces(parts[1])
  match (safe_parse_int(a_str), safe_parse_int(b_str)) {
    (Ok(a), Ok(b)) => Ok((a, b))
    _ => Err(SerializeError::InvalidFormat("Cannot parse integers: " + s))
  }
}

/// "PrimOpKind, arity" 形式の文字列をパース
fn parse_primcall(s : String) -> Result[(PrimOpKind, Int), SerializeError] {
  let parts = split_by_comma(s)
  if parts.length() != 2 {
    return Err(SerializeError::InvalidFormat("Expected PrimOpKind and arity: " + s))
  }
  let kind_str = trim_spaces(parts[0])
  let arity_str = trim_spaces(parts[1])
  match string_to_primop(kind_str) {
    Ok(kind) => {
      match safe_parse_int(arity_str) {
        Ok(arity) => Ok((kind, arity))
        Err(_) => Err(SerializeError::InvalidFormat("Cannot parse arity: " + arity_str))
      }
    }
    Err(e) => Err(e)
  }
}

/// カンマで文字列を分割
fn split_by_comma(s : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  for c in s {
    if c == ',' {
      result.push(current)
      current = ""
    } else {
      current = current + c.to_string()
    }
  }
  result.push(current)
  result
}

/// パーサ状態
struct DeserializeState {
  lines : Array[String]
  mut pos : Int
}

/// 次の行を取得
fn next_line(state : DeserializeState) -> Result[String, SerializeError] {
  if state.pos >= state.lines.length() {
    return Err(SerializeError::UnexpectedEnd)
  }
  let line = state.lines[state.pos]
  state.pos = state.pos + 1
  Ok(line)
}

/// 行をピーク
fn peek_line(state : DeserializeState) -> String? {
  if state.pos >= state.lines.length() {
    None
  } else {
    Some(state.lines[state.pos])
  }
}

/// "key:value" 形式の行からvalueを取得
fn parse_key_value(line : String, expected_key : String) -> Result[String, SerializeError] {
  let colon_idx = find_char(line, ':')
  if colon_idx < 0 {
    return Err(SerializeError::InvalidFormat("Expected key:value format: " + line))
  }
  let key = str_slice(line, 0, colon_idx)
  if key != expected_key {
    return Err(SerializeError::InvalidFormat("Expected key '" + expected_key + "' but got '" + key + "'"))
  }
  Ok(str_slice(line, colon_idx + 1, line.length()))
}

/// 文字列内で文字を検索
fn find_char(s : String, target : Char) -> Int {
  let mut i = 0
  for c in s {
    if c == target {
      return i
    }
    i = i + 1
  }
  -1
}

/// 定数リストをデシリアライズ
fn deserialize_constants(state : DeserializeState, count : Int) -> Result[Array[BCValue], SerializeError] {
  let constants : Array[BCValue] = []
  let mut i = 0
  while i < count {
    match next_line(state) {
      Ok(line) => {
        match string_to_bc_value(line) {
          Ok(v) => constants.push(v)
          Err(e) => return Err(e)
        }
      }
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  Ok(constants)
}

/// 名前リストをデシリアライズ
fn deserialize_names(state : DeserializeState, count : Int) -> Result[Array[String], SerializeError] {
  let names : Array[String] = []
  let mut i = 0
  while i < count {
    match next_line(state) {
      Ok(line) => names.push(line)
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  Ok(names)
}

/// オペコードリストをデシリアライズ
fn deserialize_opcodes(state : DeserializeState, count : Int) -> Result[Array[Opcode], SerializeError] {
  let code : Array[Opcode] = []
  let mut i = 0
  while i < count {
    match next_line(state) {
      Ok(line) => {
        match string_to_opcode(line) {
          Ok(op) => code.push(op)
          Err(e) => return Err(e)
        }
      }
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  Ok(code)
}

/// CodeChunk をデシリアライズ
fn deserialize_chunk(state : DeserializeState) -> Result[CodeChunk, SerializeError] {
  // arity
  let arity_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let arity_str = match parse_key_value(arity_line, "arity") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let arity = match safe_parse_int(arity_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse arity: " + arity_str))
  }

  // num_free_vars
  let nfv_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let nfv_str = match parse_key_value(nfv_line, "num_free_vars") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let num_free_vars = match safe_parse_int(nfv_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse num_free_vars: " + nfv_str))
  }

  // num_locals
  let nl_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let nl_str = match parse_key_value(nl_line, "num_locals") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let num_locals = match safe_parse_int(nl_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse num_locals: " + nl_str))
  }

  // debug_name
  let dn_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let dn_str = match parse_key_value(dn_line, "debug_name") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let debug_name : String? = if dn_str == "" { None } else { Some(dn_str) }

  // constants
  let const_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let const_count_str = match parse_key_value(const_line, "constants") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let const_count = match safe_parse_int(const_count_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse constants count: " + const_count_str))
  }
  let constants = match deserialize_constants(state, const_count) {
    Ok(c) => c
    Err(e) => return Err(e)
  }

  // names
  let names_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let names_count_str = match parse_key_value(names_line, "names") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let names_count = match safe_parse_int(names_count_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse names count: " + names_count_str))
  }
  let names = match deserialize_names(state, names_count) {
    Ok(n) => n
    Err(e) => return Err(e)
  }

  // code
  let code_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let code_count_str = match parse_key_value(code_line, "code") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let code_count = match safe_parse_int(code_count_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse code count: " + code_count_str))
  }
  let code = match deserialize_opcodes(state, code_count) {
    Ok(c) => c
    Err(e) => return Err(e)
  }

  Ok({
    code,
    constants,
    names,
    arity,
    num_free_vars,
    num_locals,
    debug_name,
  })
}

/// 子チャンクリストをデシリアライズ
fn deserialize_chunks(state : DeserializeState, count : Int) -> Result[Array[CodeChunk], SerializeError] {
  let chunks : Array[CodeChunk] = []
  let mut i = 0
  while i < count {
    // chunk:
    match next_line(state) {
      Ok(chunk_marker) => {
        if chunk_marker != "chunk:" {
          return Err(SerializeError::InvalidFormat("Expected 'chunk:' but got: " + chunk_marker))
        }
      }
      Err(e) => return Err(e)
    }
    match deserialize_chunk(state) {
      Ok(chunk) => chunks.push(chunk)
      Err(e) => return Err(e)
    }
    i = i + 1
  }
  Ok(chunks)
}

/// 文字列から CompiledModule をデシリアライズ
pub fn deserialize_module_from_string(s : String) -> Result[CompiledModule, SerializeError] {
  let lines = split_lines(s)
  let state : DeserializeState = { lines, pos: 0 }

  // ヘッダー確認
  let header = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  if header != "SELENE_BYTECODE_V1" {
    return Err(SerializeError::InvalidFormat("Invalid header: " + header))
  }

  // main_chunk:
  let main_marker = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  if main_marker != "main_chunk:" {
    return Err(SerializeError::InvalidFormat("Expected 'main_chunk:' but got: " + main_marker))
  }

  let main = match deserialize_chunk(state) {
    Ok(chunk) => chunk
    Err(e) => return Err(e)
  }

  // chunks:
  let chunks_line = match next_line(state) {
    Ok(line) => line
    Err(e) => return Err(e)
  }
  let chunks_count_str = match parse_key_value(chunks_line, "chunks") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let chunks_count = match safe_parse_int(chunks_count_str) {
    Ok(n) => n
    Err(_) => return Err(SerializeError::InvalidFormat("Cannot parse chunks count: " + chunks_count_str))
  }

  let chunks = match deserialize_chunks(state, chunks_count) {
    Ok(c) => c
    Err(e) => return Err(e)
  }

  Ok({ main, chunks })
}

/// 文字列を行に分割
fn split_lines(s : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  for c in s {
    if c == '\n' {
      result.push(current)
      current = ""
    } else {
      current = current + c.to_string()
    }
  }
  // 最後の行（改行なし）
  if current != "" {
    result.push(current)
  }
  result
}

/// ========================================
/// バイナリ形式のシリアライズ/デシリアライズ
/// ========================================

/// マジックナンバー: "SLNB" (Selene Binary)
fn binary_magic() -> Array[Int] {
  [0x53, 0x4C, 0x4E, 0x42]
}

/// バージョン
fn binary_version() -> Int {
  1
}

/// BCValue タグ
fn tag_nil() -> Int { 0 }
fn tag_bool() -> Int { 1 }
fn tag_int() -> Int { 2 }
fn tag_real() -> Int { 3 }
fn tag_char() -> Int { 4 }
fn tag_string() -> Int { 5 }
fn tag_symbol() -> Int { 6 }
fn tag_closure() -> Int { 7 }

/// Opcode タグ
fn op_push() -> Int { 0 }
fn op_pop() -> Int { 1 }
fn op_load_local() -> Int { 2 }
fn op_store_local() -> Int { 3 }
fn op_load_global() -> Int { 4 }
fn op_store_global() -> Int { 5 }
fn op_make_closure() -> Int { 6 }
fn op_make_box() -> Int { 7 }
fn op_box_get() -> Int { 8 }
fn op_box_set() -> Int { 9 }
fn op_call() -> Int { 10 }
fn op_tail_call() -> Int { 11 }
fn op_return() -> Int { 12 }
fn op_jump() -> Int { 13 }
fn op_jump_if_false() -> Int { 14 }
fn op_prim_call() -> Int { 15 }
fn op_capture_cc() -> Int { 16 }
fn op_halt() -> Int { 17 }
fn op_make_pair() -> Int { 18 }
fn op_make_list() -> Int { 19 }
fn op_make_vector() -> Int { 20 }
fn op_make_promise() -> Int { 21 }
fn op_and_jump() -> Int { 22 }
fn op_or_jump() -> Int { 23 }
fn op_dup() -> Int { 24 }
fn op_allocate_locals() -> Int { 25 }
fn op_init_local() -> Int { 26 }

/// バイナリバッファ
struct BinaryBuffer {
  data : Array[Int]
}

/// 新しいバッファを作成
fn new_binary_buffer() -> BinaryBuffer {
  { data: [] }
}

/// バイトを書き込み
fn write_byte(buf : BinaryBuffer, b : Int) -> Unit {
  buf.data.push(b & 0xFF)
}

/// 32ビット整数を書き込み (リトルエンディアン)
fn write_int32(buf : BinaryBuffer, n : Int) -> Unit {
  buf.data.push(n & 0xFF)
  buf.data.push((n >> 8) & 0xFF)
  buf.data.push((n >> 16) & 0xFF)
  buf.data.push((n >> 24) & 0xFF)
}

/// 64ビット浮動小数点を書き込み
fn write_double(buf : BinaryBuffer, d : Double) -> Unit {
  // 浮動小数点数を文字列経由で保存 (簡易実装)
  let s = d.to_string()
  write_string(buf, s)
}

/// 文字列を書き込み (長さプレフィックス)
fn write_string(buf : BinaryBuffer, s : String) -> Unit {
  let chars : Array[Char] = s.iter().collect()
  write_int32(buf, chars.length())
  for c in chars {
    // UTF-8として書き込み (簡易実装: ASCII範囲のみ)
    let code = c.to_int()
    if code < 128 {
      write_byte(buf, code)
    } else if code < 0x800 {
      write_byte(buf, 0xC0 | (code >> 6))
      write_byte(buf, 0x80 | (code & 0x3F))
    } else {
      write_byte(buf, 0xE0 | (code >> 12))
      write_byte(buf, 0x80 | ((code >> 6) & 0x3F))
      write_byte(buf, 0x80 | (code & 0x3F))
    }
  }
}

/// BCValue をバイナリで書き込み
fn write_bc_value(buf : BinaryBuffer, v : BCValue) -> Unit {
  match v {
    BCValue::Nil => write_byte(buf, tag_nil())
    BCValue::Bool(b) => {
      write_byte(buf, tag_bool())
      write_byte(buf, if b { 1 } else { 0 })
    }
    BCValue::Int(n) => {
      write_byte(buf, tag_int())
      write_int32(buf, n)
    }
    BCValue::Real(r) => {
      write_byte(buf, tag_real())
      write_double(buf, r)
    }
    BCValue::Char(c) => {
      write_byte(buf, tag_char())
      write_int32(buf, c.to_int())
    }
    BCValue::String(s) => {
      write_byte(buf, tag_string())
      write_string(buf, s)
    }
    BCValue::Symbol(s) => {
      write_byte(buf, tag_symbol())
      write_string(buf, s)
    }
    BCValue::Closure(idx) => {
      write_byte(buf, tag_closure())
      write_int32(buf, idx)
    }
  }
}

/// PrimOpKind を数値に変換
fn primop_to_int(kind : PrimOpKind) -> Int {
  match kind {
    PrimOpKind::Add => 0
    PrimOpKind::Sub => 1
    PrimOpKind::Mul => 2
    PrimOpKind::Div => 3
    PrimOpKind::Quotient => 4
    PrimOpKind::Remainder => 5
    PrimOpKind::Modulo => 6
    PrimOpKind::Abs => 7
    PrimOpKind::Max => 8
    PrimOpKind::Min => 9
    PrimOpKind::Gcd => 10
    PrimOpKind::Lcm => 11
    PrimOpKind::NumEq => 12
    PrimOpKind::Lt => 13
    PrimOpKind::Gt => 14
    PrimOpKind::Le => 15
    PrimOpKind::Ge => 16
    PrimOpKind::Eq => 17
    PrimOpKind::Eqv => 18
    PrimOpKind::Equal => 19
    PrimOpKind::ZeroP => 20
    PrimOpKind::PositiveP => 21
    PrimOpKind::NegativeP => 22
    PrimOpKind::OddP => 23
    PrimOpKind::EvenP => 24
    PrimOpKind::PairP => 25
    PrimOpKind::NumberP => 26
    PrimOpKind::IntegerP => 27
    PrimOpKind::RealP => 28
    PrimOpKind::BooleanP => 29
    PrimOpKind::SymbolP => 30
    PrimOpKind::NullP => 31
    PrimOpKind::ProcedureP => 32
    PrimOpKind::ListP => 33
    PrimOpKind::StringP => 34
    PrimOpKind::CharP => 35
    PrimOpKind::VectorP => 36
    PrimOpKind::PromiseP => 37
    PrimOpKind::PortP => 38
    PrimOpKind::Cons => 39
    PrimOpKind::Car => 40
    PrimOpKind::Cdr => 41
    PrimOpKind::SetCar => 42
    PrimOpKind::SetCdr => 43
    PrimOpKind::List => 44
    PrimOpKind::Length => 45
    PrimOpKind::Append => 46
    PrimOpKind::Reverse => 47
    PrimOpKind::ListRef => 48
    PrimOpKind::ListTail => 49
    PrimOpKind::CharEq => 50
    PrimOpKind::CharLt => 51
    PrimOpKind::CharGt => 52
    PrimOpKind::CharLe => 53
    PrimOpKind::CharGe => 54
    PrimOpKind::CharAlphabeticP => 55
    PrimOpKind::CharNumericP => 56
    PrimOpKind::CharWhitespaceP => 57
    PrimOpKind::CharUpperCaseP => 58
    PrimOpKind::CharLowerCaseP => 59
    PrimOpKind::CharUpcase => 60
    PrimOpKind::CharDowncase => 61
    PrimOpKind::CharToInteger => 62
    PrimOpKind::IntegerToChar => 63
    PrimOpKind::StringLength => 64
    PrimOpKind::StringRef => 65
    PrimOpKind::StringAppend => 66
    PrimOpKind::StringEq => 67
    PrimOpKind::StringLt => 68
    PrimOpKind::StringGt => 69
    PrimOpKind::StringLe => 70
    PrimOpKind::StringGe => 71
    PrimOpKind::MakeString => 72
    PrimOpKind::Substring => 73
    PrimOpKind::StringToList => 74
    PrimOpKind::ListToString => 75
    PrimOpKind::MakeVector => 76
    PrimOpKind::Vector => 77
    PrimOpKind::VectorLength => 78
    PrimOpKind::VectorRef => 79
    PrimOpKind::VectorSet => 80
    PrimOpKind::VectorToList => 81
    PrimOpKind::ListToVector => 82
    PrimOpKind::Floor => 83
    PrimOpKind::Ceiling => 84
    PrimOpKind::Truncate => 85
    PrimOpKind::Round => 86
    PrimOpKind::Sqrt => 87
    PrimOpKind::Expt => 88
    PrimOpKind::Sin => 89
    PrimOpKind::Cos => 90
    PrimOpKind::Tan => 91
    PrimOpKind::Asin => 92
    PrimOpKind::Acos => 93
    PrimOpKind::Atan => 94
    PrimOpKind::Exp => 95
    PrimOpKind::Log => 96
    PrimOpKind::NumberToString => 97
    PrimOpKind::StringToNumber => 98
    PrimOpKind::SymbolToString => 99
    PrimOpKind::StringToSymbol => 100
    PrimOpKind::Not => 101
    PrimOpKind::MakeRectangular => 102
    PrimOpKind::MakePolar => 103
    PrimOpKind::RealPart => 104
    PrimOpKind::ImagPart => 105
    PrimOpKind::Magnitude => 106
    PrimOpKind::Angle => 107
    PrimOpKind::ComplexP => 108
    PrimOpKind::Numerator => 109
    PrimOpKind::Denominator => 110
    PrimOpKind::RationalP => 111
    PrimOpKind::ExactP => 112
    PrimOpKind::InexactP => 113
    PrimOpKind::Display => 114
    PrimOpKind::Newline => 115
    PrimOpKind::Write => 116
    PrimOpKind::Read => 117
    PrimOpKind::InputPortP => 118
    PrimOpKind::OutputPortP => 119
    PrimOpKind::OpenInputFile => 120
    PrimOpKind::OpenOutputFile => 121
    PrimOpKind::CloseInputPort => 122
    PrimOpKind::CloseOutputPort => 123
    PrimOpKind::ReadChar => 124
    PrimOpKind::PeekChar => 125
    PrimOpKind::WriteChar => 126
    PrimOpKind::EofObjectP => 127
    PrimOpKind::Apply => 128
    PrimOpKind::Map => 129
    PrimOpKind::ForEach => 130
    PrimOpKind::Filter => 131
    PrimOpKind::FoldLeft => 132
    PrimOpKind::FoldRight => 133
    PrimOpKind::Force => 134
    PrimOpKind::Values => 135
    PrimOpKind::CallWithValues => 136
    PrimOpKind::DynamicWind => 137
    PrimOpKind::Assq => 138
    PrimOpKind::Assv => 139
    PrimOpKind::Assoc => 140
    PrimOpKind::Memq => 141
    PrimOpKind::Memv => 142
    PrimOpKind::Member => 143
    PrimOpKind::Caar => 144
    PrimOpKind::Cadr => 145
    PrimOpKind::Cdar => 146
    PrimOpKind::Cddr => 147
    PrimOpKind::Caaar => 148
    PrimOpKind::Caadr => 149
    PrimOpKind::Cadar => 150
    PrimOpKind::Caddr => 151
    PrimOpKind::Cdaar => 152
    PrimOpKind::Cdadr => 153
    PrimOpKind::Cddar => 154
    PrimOpKind::Cdddr => 155
  }
}

/// Opcode をバイナリで書き込み
fn write_opcode(buf : BinaryBuffer, op : Opcode) -> Unit {
  match op {
    Opcode::Push(idx) => {
      write_byte(buf, op_push())
      write_int32(buf, idx)
    }
    Opcode::Pop => write_byte(buf, op_pop())
    Opcode::LoadLocal(depth, idx) => {
      write_byte(buf, op_load_local())
      write_int32(buf, depth)
      write_int32(buf, idx)
    }
    Opcode::StoreLocal(depth, idx) => {
      write_byte(buf, op_store_local())
      write_int32(buf, depth)
      write_int32(buf, idx)
    }
    Opcode::LoadGlobal(idx) => {
      write_byte(buf, op_load_global())
      write_int32(buf, idx)
    }
    Opcode::StoreGlobal(idx) => {
      write_byte(buf, op_store_global())
      write_int32(buf, idx)
    }
    Opcode::MakeClosure(chunk_idx, num_captures) => {
      write_byte(buf, op_make_closure())
      write_int32(buf, chunk_idx)
      write_int32(buf, num_captures)
    }
    Opcode::MakeBox => write_byte(buf, op_make_box())
    Opcode::BoxGet => write_byte(buf, op_box_get())
    Opcode::BoxSet => write_byte(buf, op_box_set())
    Opcode::Call(argc) => {
      write_byte(buf, op_call())
      write_int32(buf, argc)
    }
    Opcode::TailCall(argc) => {
      write_byte(buf, op_tail_call())
      write_int32(buf, argc)
    }
    Opcode::Return => write_byte(buf, op_return())
    Opcode::Jump(offset) => {
      write_byte(buf, op_jump())
      write_int32(buf, offset)
    }
    Opcode::JumpIfFalse(offset) => {
      write_byte(buf, op_jump_if_false())
      write_int32(buf, offset)
    }
    Opcode::PrimCall(kind, argc) => {
      write_byte(buf, op_prim_call())
      write_int32(buf, primop_to_int(kind))
      write_int32(buf, argc)
    }
    Opcode::CaptureCC => write_byte(buf, op_capture_cc())
    Opcode::Halt => write_byte(buf, op_halt())
    Opcode::MakePair => write_byte(buf, op_make_pair())
    Opcode::MakeList(n) => {
      write_byte(buf, op_make_list())
      write_int32(buf, n)
    }
    Opcode::MakeVector(n) => {
      write_byte(buf, op_make_vector())
      write_int32(buf, n)
    }
    Opcode::MakePromise(chunk_idx) => {
      write_byte(buf, op_make_promise())
      write_int32(buf, chunk_idx)
    }
    Opcode::AndJump(offset) => {
      write_byte(buf, op_and_jump())
      write_int32(buf, offset)
    }
    Opcode::OrJump(offset) => {
      write_byte(buf, op_or_jump())
      write_int32(buf, offset)
    }
    Opcode::Dup => write_byte(buf, op_dup())
    Opcode::AllocateLocals(n) => {
      write_byte(buf, op_allocate_locals())
      write_int32(buf, n)
    }
    Opcode::InitLocal(depth, idx) => {
      write_byte(buf, op_init_local())
      write_int32(buf, depth)
      write_int32(buf, idx)
    }
  }
}

/// CodeChunk をバイナリで書き込み
fn write_chunk(buf : BinaryBuffer, chunk : CodeChunk) -> Unit {
  write_int32(buf, chunk.arity)
  write_int32(buf, chunk.num_free_vars)
  write_int32(buf, chunk.num_locals)

  // debug_name
  match chunk.debug_name {
    Some(name) => {
      write_byte(buf, 1)
      write_string(buf, name)
    }
    None => write_byte(buf, 0)
  }

  // constants
  write_int32(buf, chunk.constants.length())
  for c in chunk.constants {
    write_bc_value(buf, c)
  }

  // names
  write_int32(buf, chunk.names.length())
  for name in chunk.names {
    write_string(buf, name)
  }

  // code
  write_int32(buf, chunk.code.length())
  for op in chunk.code {
    write_opcode(buf, op)
  }
}

/// CompiledModule をバイナリにシリアライズ
pub fn serialize_module_to_binary(m : CompiledModule) -> Array[Int] {
  let buf = new_binary_buffer()

  // マジックナンバー
  for b in binary_magic() {
    write_byte(buf, b)
  }

  // バージョン
  write_int32(buf, binary_version())

  // メインチャンク
  write_chunk(buf, m.main)

  // 子チャンク
  write_int32(buf, m.chunks.length())
  for chunk in m.chunks {
    write_chunk(buf, chunk)
  }

  buf.data
}

/// ========================================
/// バイナリデシリアライズ
/// ========================================

/// バイナリリーダー
struct BinaryReader {
  data : Array[Int]
  mut pos : Int
}

/// バイトを読み込み
fn read_byte(r : BinaryReader) -> Result[Int, SerializeError] {
  if r.pos >= r.data.length() {
    return Err(SerializeError::UnexpectedEnd)
  }
  let b = r.data[r.pos]
  r.pos = r.pos + 1
  Ok(b)
}

/// 32ビット整数を読み込み (リトルエンディアン)
fn read_int32(r : BinaryReader) -> Result[Int, SerializeError] {
  let b0 = match read_byte(r) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  let b1 = match read_byte(r) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  let b2 = match read_byte(r) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  let b3 = match read_byte(r) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  // 符号拡張を考慮
  let value = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
  Ok(value)
}

/// 文字列を読み込み
fn read_string_binary(r : BinaryReader) -> Result[String, SerializeError] {
  let len = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut result = ""
  let mut i = 0
  while i < len {
    let b = match read_byte(r) {
      Ok(b) => b
      Err(e) => return Err(e)
    }
    // UTF-8 デコード (簡易実装)
    if b < 128 {
      result = result + Char::from_int(b).to_string()
    } else if (b & 0xE0) == 0xC0 {
      let b2 = match read_byte(r) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      let code = ((b & 0x1F) << 6) | (b2 & 0x3F)
      result = result + Char::from_int(code).to_string()
    } else if (b & 0xF0) == 0xE0 {
      let b2 = match read_byte(r) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      let b3 = match read_byte(r) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      let code = ((b & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
      result = result + Char::from_int(code).to_string()
    }
    i = i + 1
  }
  Ok(result)
}

/// Double を読み込み
fn read_double(r : BinaryReader) -> Result[Double, SerializeError] {
  let s = match read_string_binary(r) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  safe_parse_double(s)
}

/// BCValue を読み込み
fn read_bc_value(r : BinaryReader) -> Result[BCValue, SerializeError] {
  let tag = match read_byte(r) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  match tag {
    0 => Ok(BCValue::Nil)  // tag_nil()
    1 => {  // tag_bool()
      let b = match read_byte(r) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
      Ok(BCValue::Bool(b != 0))
    }
    2 => {  // tag_int()
      let n = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(BCValue::Int(n))
    }
    3 => {  // tag_real()
      let d = match read_double(r) {
        Ok(d) => d
        Err(e) => return Err(e)
      }
      Ok(BCValue::Real(d))
    }
    4 => {  // tag_char()
      let code = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(BCValue::Char(Char::from_int(code)))
    }
    5 => {  // tag_string()
      let s = match read_string_binary(r) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
      Ok(BCValue::String(s))
    }
    6 => {  // tag_symbol()
      let s = match read_string_binary(r) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
      Ok(BCValue::Symbol(s))
    }
    7 => {  // tag_closure()
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(BCValue::Closure(idx))
    }
    _ => Err(SerializeError::InvalidBCValueType("Unknown tag: " + tag.to_string()))
  }
}

/// 数値から PrimOpKind に変換
fn int_to_primop(n : Int) -> Result[PrimOpKind, SerializeError] {
  match n {
    0 => Ok(PrimOpKind::Add)
    1 => Ok(PrimOpKind::Sub)
    2 => Ok(PrimOpKind::Mul)
    3 => Ok(PrimOpKind::Div)
    4 => Ok(PrimOpKind::Quotient)
    5 => Ok(PrimOpKind::Remainder)
    6 => Ok(PrimOpKind::Modulo)
    7 => Ok(PrimOpKind::Abs)
    8 => Ok(PrimOpKind::Max)
    9 => Ok(PrimOpKind::Min)
    10 => Ok(PrimOpKind::Gcd)
    11 => Ok(PrimOpKind::Lcm)
    12 => Ok(PrimOpKind::NumEq)
    13 => Ok(PrimOpKind::Lt)
    14 => Ok(PrimOpKind::Gt)
    15 => Ok(PrimOpKind::Le)
    16 => Ok(PrimOpKind::Ge)
    17 => Ok(PrimOpKind::Eq)
    18 => Ok(PrimOpKind::Eqv)
    19 => Ok(PrimOpKind::Equal)
    20 => Ok(PrimOpKind::ZeroP)
    21 => Ok(PrimOpKind::PositiveP)
    22 => Ok(PrimOpKind::NegativeP)
    23 => Ok(PrimOpKind::OddP)
    24 => Ok(PrimOpKind::EvenP)
    25 => Ok(PrimOpKind::PairP)
    26 => Ok(PrimOpKind::NumberP)
    27 => Ok(PrimOpKind::IntegerP)
    28 => Ok(PrimOpKind::RealP)
    29 => Ok(PrimOpKind::BooleanP)
    30 => Ok(PrimOpKind::SymbolP)
    31 => Ok(PrimOpKind::NullP)
    32 => Ok(PrimOpKind::ProcedureP)
    33 => Ok(PrimOpKind::ListP)
    34 => Ok(PrimOpKind::StringP)
    35 => Ok(PrimOpKind::CharP)
    36 => Ok(PrimOpKind::VectorP)
    37 => Ok(PrimOpKind::PromiseP)
    38 => Ok(PrimOpKind::PortP)
    39 => Ok(PrimOpKind::Cons)
    40 => Ok(PrimOpKind::Car)
    41 => Ok(PrimOpKind::Cdr)
    42 => Ok(PrimOpKind::SetCar)
    43 => Ok(PrimOpKind::SetCdr)
    44 => Ok(PrimOpKind::List)
    45 => Ok(PrimOpKind::Length)
    46 => Ok(PrimOpKind::Append)
    47 => Ok(PrimOpKind::Reverse)
    48 => Ok(PrimOpKind::ListRef)
    49 => Ok(PrimOpKind::ListTail)
    50 => Ok(PrimOpKind::CharEq)
    51 => Ok(PrimOpKind::CharLt)
    52 => Ok(PrimOpKind::CharGt)
    53 => Ok(PrimOpKind::CharLe)
    54 => Ok(PrimOpKind::CharGe)
    55 => Ok(PrimOpKind::CharAlphabeticP)
    56 => Ok(PrimOpKind::CharNumericP)
    57 => Ok(PrimOpKind::CharWhitespaceP)
    58 => Ok(PrimOpKind::CharUpperCaseP)
    59 => Ok(PrimOpKind::CharLowerCaseP)
    60 => Ok(PrimOpKind::CharUpcase)
    61 => Ok(PrimOpKind::CharDowncase)
    62 => Ok(PrimOpKind::CharToInteger)
    63 => Ok(PrimOpKind::IntegerToChar)
    64 => Ok(PrimOpKind::StringLength)
    65 => Ok(PrimOpKind::StringRef)
    66 => Ok(PrimOpKind::StringAppend)
    67 => Ok(PrimOpKind::StringEq)
    68 => Ok(PrimOpKind::StringLt)
    69 => Ok(PrimOpKind::StringGt)
    70 => Ok(PrimOpKind::StringLe)
    71 => Ok(PrimOpKind::StringGe)
    72 => Ok(PrimOpKind::MakeString)
    73 => Ok(PrimOpKind::Substring)
    74 => Ok(PrimOpKind::StringToList)
    75 => Ok(PrimOpKind::ListToString)
    76 => Ok(PrimOpKind::MakeVector)
    77 => Ok(PrimOpKind::Vector)
    78 => Ok(PrimOpKind::VectorLength)
    79 => Ok(PrimOpKind::VectorRef)
    80 => Ok(PrimOpKind::VectorSet)
    81 => Ok(PrimOpKind::VectorToList)
    82 => Ok(PrimOpKind::ListToVector)
    83 => Ok(PrimOpKind::Floor)
    84 => Ok(PrimOpKind::Ceiling)
    85 => Ok(PrimOpKind::Truncate)
    86 => Ok(PrimOpKind::Round)
    87 => Ok(PrimOpKind::Sqrt)
    88 => Ok(PrimOpKind::Expt)
    89 => Ok(PrimOpKind::Sin)
    90 => Ok(PrimOpKind::Cos)
    91 => Ok(PrimOpKind::Tan)
    92 => Ok(PrimOpKind::Asin)
    93 => Ok(PrimOpKind::Acos)
    94 => Ok(PrimOpKind::Atan)
    95 => Ok(PrimOpKind::Exp)
    96 => Ok(PrimOpKind::Log)
    97 => Ok(PrimOpKind::NumberToString)
    98 => Ok(PrimOpKind::StringToNumber)
    99 => Ok(PrimOpKind::SymbolToString)
    100 => Ok(PrimOpKind::StringToSymbol)
    101 => Ok(PrimOpKind::Not)
    102 => Ok(PrimOpKind::MakeRectangular)
    103 => Ok(PrimOpKind::MakePolar)
    104 => Ok(PrimOpKind::RealPart)
    105 => Ok(PrimOpKind::ImagPart)
    106 => Ok(PrimOpKind::Magnitude)
    107 => Ok(PrimOpKind::Angle)
    108 => Ok(PrimOpKind::ComplexP)
    109 => Ok(PrimOpKind::Numerator)
    110 => Ok(PrimOpKind::Denominator)
    111 => Ok(PrimOpKind::RationalP)
    112 => Ok(PrimOpKind::ExactP)
    113 => Ok(PrimOpKind::InexactP)
    114 => Ok(PrimOpKind::Display)
    115 => Ok(PrimOpKind::Newline)
    116 => Ok(PrimOpKind::Write)
    117 => Ok(PrimOpKind::Read)
    118 => Ok(PrimOpKind::InputPortP)
    119 => Ok(PrimOpKind::OutputPortP)
    120 => Ok(PrimOpKind::OpenInputFile)
    121 => Ok(PrimOpKind::OpenOutputFile)
    122 => Ok(PrimOpKind::CloseInputPort)
    123 => Ok(PrimOpKind::CloseOutputPort)
    124 => Ok(PrimOpKind::ReadChar)
    125 => Ok(PrimOpKind::PeekChar)
    126 => Ok(PrimOpKind::WriteChar)
    127 => Ok(PrimOpKind::EofObjectP)
    128 => Ok(PrimOpKind::Apply)
    129 => Ok(PrimOpKind::Map)
    130 => Ok(PrimOpKind::ForEach)
    131 => Ok(PrimOpKind::Filter)
    132 => Ok(PrimOpKind::FoldLeft)
    133 => Ok(PrimOpKind::FoldRight)
    134 => Ok(PrimOpKind::Force)
    135 => Ok(PrimOpKind::Values)
    136 => Ok(PrimOpKind::CallWithValues)
    137 => Ok(PrimOpKind::DynamicWind)
    138 => Ok(PrimOpKind::Assq)
    139 => Ok(PrimOpKind::Assv)
    140 => Ok(PrimOpKind::Assoc)
    141 => Ok(PrimOpKind::Memq)
    142 => Ok(PrimOpKind::Memv)
    143 => Ok(PrimOpKind::Member)
    144 => Ok(PrimOpKind::Caar)
    145 => Ok(PrimOpKind::Cadr)
    146 => Ok(PrimOpKind::Cdar)
    147 => Ok(PrimOpKind::Cddr)
    148 => Ok(PrimOpKind::Caaar)
    149 => Ok(PrimOpKind::Caadr)
    150 => Ok(PrimOpKind::Cadar)
    151 => Ok(PrimOpKind::Caddr)
    152 => Ok(PrimOpKind::Cdaar)
    153 => Ok(PrimOpKind::Cdadr)
    154 => Ok(PrimOpKind::Cddar)
    155 => Ok(PrimOpKind::Cdddr)
    _ => Err(SerializeError::InvalidPrimOpKind("Unknown primop: " + n.to_string()))
  }
}

/// Opcode を読み込み
fn read_opcode(r : BinaryReader) -> Result[Opcode, SerializeError] {
  let tag = match read_byte(r) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  match tag {
    0 => {  // op_push()
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::Push(idx))
    }
    1 => Ok(Opcode::Pop)  // op_pop()
    2 => {  // op_load_local()
      let depth = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::LoadLocal(depth, idx))
    }
    3 => {  // op_store_local()
      let depth = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::StoreLocal(depth, idx))
    }
    4 => {  // op_load_global()
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::LoadGlobal(idx))
    }
    5 => {  // op_store_global()
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::StoreGlobal(idx))
    }
    6 => {  // op_make_closure()
      let chunk_idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let num_captures = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::MakeClosure(chunk_idx, num_captures))
    }
    7 => Ok(Opcode::MakeBox)  // op_make_box()
    8 => Ok(Opcode::BoxGet)  // op_box_get()
    9 => Ok(Opcode::BoxSet)  // op_box_set()
    10 => {  // op_call()
      let argc = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::Call(argc))
    }
    11 => {  // op_tail_call()
      let argc = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::TailCall(argc))
    }
    12 => Ok(Opcode::Return)  // op_return()
    13 => {  // op_jump()
      let offset = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::Jump(offset))
    }
    14 => {  // op_jump_if_false()
      let offset = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::JumpIfFalse(offset))
    }
    15 => {  // op_prim_call()
      let kind_int = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let kind = match int_to_primop(kind_int) {
        Ok(k) => k
        Err(e) => return Err(e)
      }
      let argc = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::PrimCall(kind, argc))
    }
    16 => Ok(Opcode::CaptureCC)  // op_capture_cc()
    17 => Ok(Opcode::Halt)  // op_halt()
    18 => Ok(Opcode::MakePair)  // op_make_pair()
    19 => {  // op_make_list()
      let n = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::MakeList(n))
    }
    20 => {  // op_make_vector()
      let n = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::MakeVector(n))
    }
    21 => {  // op_make_promise()
      let chunk_idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::MakePromise(chunk_idx))
    }
    22 => {  // op_and_jump()
      let offset = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::AndJump(offset))
    }
    23 => {  // op_or_jump()
      let offset = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::OrJump(offset))
    }
    24 => Ok(Opcode::Dup)  // op_dup()
    25 => {  // op_allocate_locals()
      let n = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::AllocateLocals(n))
    }
    26 => {  // op_init_local()
      let depth = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let idx = match read_int32(r) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      Ok(Opcode::InitLocal(depth, idx))
    }
    _ => Err(SerializeError::InvalidOpcode("Unknown opcode tag: " + tag.to_string()))
  }
}

/// CodeChunk を読み込み
fn read_chunk(r : BinaryReader) -> Result[CodeChunk, SerializeError] {
  let arity = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let num_free_vars = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let num_locals = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }

  // debug_name
  let has_name = match read_byte(r) {
    Ok(b) => b
    Err(e) => return Err(e)
  }
  let debug_name : String? = if has_name != 0 {
    match read_string_binary(r) {
      Ok(s) => Some(s)
      Err(e) => return Err(e)
    }
  } else {
    None
  }

  // constants
  let const_count = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let constants : Array[BCValue] = []
  let mut i = 0
  while i < const_count {
    match read_bc_value(r) {
      Ok(v) => constants.push(v)
      Err(e) => return Err(e)
    }
    i = i + 1
  }

  // names
  let names_count = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let names : Array[String] = []
  i = 0
  while i < names_count {
    match read_string_binary(r) {
      Ok(s) => names.push(s)
      Err(e) => return Err(e)
    }
    i = i + 1
  }

  // code
  let code_count = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let code : Array[Opcode] = []
  i = 0
  while i < code_count {
    match read_opcode(r) {
      Ok(op) => code.push(op)
      Err(e) => return Err(e)
    }
    i = i + 1
  }

  Ok({
    code,
    constants,
    names,
    arity,
    num_free_vars,
    num_locals,
    debug_name,
  })
}

/// バイナリから CompiledModule をデシリアライズ
pub fn deserialize_module_from_binary(data : Array[Int]) -> Result[CompiledModule, SerializeError] {
  let r : BinaryReader = { data, pos: 0 }

  // マジックナンバー確認
  let mut i = 0
  while i < binary_magic().length() {
    let b = match read_byte(r) {
      Ok(b) => b
      Err(e) => return Err(e)
    }
    if b != binary_magic()[i] {
      return Err(SerializeError::InvalidFormat("Invalid magic number"))
    }
    i = i + 1
  }

  // バージョン確認
  let version = match read_int32(r) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if version != binary_version() {
    return Err(SerializeError::InvalidFormat("Unsupported version: " + version.to_string()))
  }

  // メインチャンク
  let main = match read_chunk(r) {
    Ok(c) => c
    Err(e) => return Err(e)
  }

  // 子チャンク
  let chunks_count = match read_int32(r) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let chunks : Array[CodeChunk] = []
  i = 0
  while i < chunks_count {
    match read_chunk(r) {
      Ok(chunk) => chunks.push(chunk)
      Err(e) => return Err(e)
    }
    i = i + 1
  }

  Ok({ main, chunks })
}
