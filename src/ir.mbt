/// 中間表現 (IR) の型定義
///
/// SExpr (AST) からコンパイルされた中間表現。
/// レキシカルアドレッシングと末尾呼び出し最適化の情報を含む。

/// 変数参照（レキシカルアドレッシング）
pub(all) struct VarRef {
  /// 変数名（デバッグ用）
  name : String
  /// レキシカル深度（0 = 現在のフレーム、1 = 親フレーム、...）
  depth : Int
  /// フレーム内インデックス
  index : Int
} derive(Show, Eq)

/// 定数値（コンパイル時に決定される値）
pub(all) enum IRConst {
  Nil
  Bool(Bool)
  Int(Int)
  Real(Double)
  Char(Char)
  String(String)
  Symbol(String)
  /// 複合データ（quote されたリストやベクトル）
  Pair(IRConst, IRConst)
  Vector(Array[IRConst])
} derive(Show)

/// プリミティブ操作の種類
pub(all) enum PrimOpKind {
  // 算術演算
  Add
  Sub
  Mul
  Div
  Quotient
  Remainder
  Modulo
  Abs
  Max
  Min
  Gcd
  Lcm

  // 比較演算
  NumEq
  Lt
  Gt
  Le
  Ge
  Eq
  Eqv
  Equal

  // 数値述語
  ZeroP
  PositiveP
  NegativeP
  OddP
  EvenP

  // 型述語
  PairP
  NumberP
  IntegerP
  RealP
  BooleanP
  SymbolP
  NullP
  ProcedureP
  ListP
  StringP
  CharP
  VectorP
  PromiseP
  PortP

  // リスト操作
  Cons
  Car
  Cdr
  SetCar
  SetCdr
  List
  Length
  Append
  Reverse
  ListRef
  ListTail

  // 文字操作
  CharEq
  CharLt
  CharGt
  CharLe
  CharGe
  CharAlphabeticP
  CharNumericP
  CharWhitespaceP
  CharUpperCaseP
  CharLowerCaseP
  CharUpcase
  CharDowncase
  CharToInteger
  IntegerToChar

  // 文字列操作
  StringLength
  StringRef
  StringAppend
  StringEq
  StringLt
  StringGt
  StringLe
  StringGe
  MakeString
  Substring
  StringToList
  ListToString

  // ベクトル操作
  MakeVector
  Vector
  VectorLength
  VectorRef
  VectorSet
  VectorToList
  ListToVector

  // 数学関数
  Floor
  Ceiling
  Truncate
  Round
  Sqrt
  Expt
  Sin
  Cos
  Tan
  Asin
  Acos
  Atan
  Exp
  Log

  // 変換
  NumberToString
  StringToNumber
  SymbolToString
  StringToSymbol

  // 論理演算
  Not

  // 複素数
  MakeRectangular
  MakePolar
  RealPart
  ImagPart
  Magnitude
  Angle
  ComplexP

  // 有理数
  Numerator
  Denominator
  RationalP

  // 数値判定
  ExactP
  InexactP

  // I/O
  Display
  Newline
  Write
  Read

  // ポート
  InputPortP
  OutputPortP
  OpenInputFile
  OpenOutputFile
  CloseInputPort
  CloseOutputPort
  ReadChar
  PeekChar
  WriteChar
  EofObjectP

  // 制御
  Apply
  Map
  ForEach
  Filter
  FoldLeft
  FoldRight
  Force
  Values
  CallWithValues
  DynamicWind

  // 連想リスト
  Assq
  Assv
  Assoc

  // メンバーシップ
  Memq
  Memv
  Member

  // cXXr アクセサ
  Caar
  Cadr
  Cdar
  Cddr
  Caaar
  Caadr
  Cadar
  Caddr
  Cdaar
  Cdadr
  Cddar
  Cdddr
} derive(Show)

/// let バインディング
pub(all) struct LetBinding {
  /// 変数名
  name : String
  /// 初期化式
  init : IRExpr
} derive(Show)

/// ラムダ情報
pub(all) struct LambdaInfo {
  /// パラメータ名（デバッグ用）
  params : Array[String]
  /// パラメータ数
  arity : Int
  /// 関数本体
  body : IRExpr
  /// 自由変数のリスト（クロージャ生成に使用）
  free_vars : Array[VarRef]
} derive(Show)

/// 中間表現の式
pub(all) enum IRExpr {
  /// 定数
  Const(IRConst)
  /// ローカル変数参照
  Var(VarRef)
  /// グローバル変数参照
  GlobalVar(String)
  /// 条件分岐: (if test then else)
  If(IRExpr, IRExpr, IRExpr)
  /// 逐次実行: (begin expr ...)
  Begin(Array[IRExpr])
  /// ラムダ式
  Lambda(LambdaInfo)
  /// 関数適用: (app func args...)
  App(IRExpr, Array[IRExpr])
  /// 末尾呼び出し: (tail-app func args...)
  TailApp(IRExpr, Array[IRExpr])
  /// let 束縛: (let ((var init) ...) body)
  Let(Array[LetBinding], IRExpr)
  /// letrec 束縛: (letrec ((var init) ...) body)
  Letrec(Array[LetBinding], IRExpr)
  /// 代入: (set! var value)
  Set(VarRef, IRExpr)
  /// グローバル代入: (set! global-var value)
  GlobalSet(String, IRExpr)
  /// プリミティブ操作: (prim-op kind args...)
  PrimOp(PrimOpKind, Array[IRExpr])
  /// 継続のキャプチャ: (call/cc proc)
  CallCC(IRExpr)
  /// クォート: 'datum
  Quote(IRConst)
  /// 遅延評価: (delay expr)
  Delay(IRExpr)
  /// and 特殊形式: (and expr ...)
  And(Array[IRExpr])
  /// or 特殊形式: (or expr ...)
  Or(Array[IRExpr])
} derive(Show)

/// コンパイルエラー
pub(all) enum CompileError {
  /// 未束縛変数
  UnboundVariable(String)
  /// 構文エラー
  SyntaxError(String)
  /// サポートされていない機能
  Unsupported(String)
} derive(Show)

/// IRConst を Value に変換する
pub fn ir_const_to_value(c : IRConst) -> Value {
  match c {
    IRConst::Nil => Value::Nil
    IRConst::Bool(b) => Value::Bool(b)
    IRConst::Int(n) => Value::Number(Number::Int(n))
    IRConst::Real(r) => Value::Number(Number::Real(r))
    IRConst::Char(c) => Value::Char(c)
    IRConst::String(s) => Value::String(s)
    IRConst::Symbol(s) => Value::Symbol(s)
    IRConst::Pair(car, cdr) =>
      Value::Pair(ir_const_to_value(car), ir_const_to_value(cdr))
    IRConst::Vector(items) => {
      let values : Array[Value] = []
      for item in items {
        values.push(ir_const_to_value(item))
      }
      Value::Vector(values)
    }
  }
}

/// SExpr を IRConst に変換する（quote されたデータ用）
pub fn sexpr_to_ir_const(sexpr : SExpr) -> IRConst {
  match sexpr {
    SExpr::Nil => IRConst::Nil
    SExpr::Bool(b) => IRConst::Bool(b)
    SExpr::Number(n) => IRConst::Int(n)
    SExpr::Char(c) => IRConst::Char(c)
    SExpr::String(s) => IRConst::String(s)
    SExpr::Symbol(s) => IRConst::Symbol(s)
    SExpr::Pair(car, cdr) =>
      IRConst::Pair(sexpr_to_ir_const(car), sexpr_to_ir_const(cdr))
    SExpr::Vector(items) => {
      let ir_items : Array[IRConst] = []
      for item in items {
        ir_items.push(sexpr_to_ir_const(item))
      }
      IRConst::Vector(ir_items)
    }
    SExpr::Quote(inner) => sexpr_to_ir_const(inner)
    SExpr::Quasiquote(inner) =>
      IRConst::Pair(IRConst::Symbol("quasiquote"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
    SExpr::Unquote(inner) =>
      IRConst::Pair(IRConst::Symbol("unquote"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
    SExpr::UnquoteSplicing(inner) =>
      IRConst::Pair(IRConst::Symbol("unquote-splicing"), IRConst::Pair(sexpr_to_ir_const(inner), IRConst::Nil))
  }
}
