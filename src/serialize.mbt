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
