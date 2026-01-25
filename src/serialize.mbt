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

/// 注: デシリアライズは将来の実装に委ねる
/// テキスト形式のパースは複雑なため、まずはシリアライズのみ実装
