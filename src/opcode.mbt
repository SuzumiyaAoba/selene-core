/// バイトコード定義
///
/// スタックベース仮想マシンの命令セット

/// バイトコード値（定数プールに格納される値）
pub(all) enum BCValue {
  Nil
  Bool(Bool)
  Int(Int)
  Real(Double)
  Char(Char)
  String(String)
  Symbol(String)
  /// コンパイル済みの手続き（クロージャテンプレート）
  Closure(Int)  // 定数プール内のコードチャンクインデックス
} derive(Show)

/// バイトコード命令
pub(all) enum Opcode {
  /// 定数をスタックにプッシュ
  Push(Int)  // 定数プールインデックス

  /// スタックトップをポップ
  Pop

  /// ローカル変数をロード (depth, index)
  LoadLocal(Int, Int)

  /// ローカル変数にストア (depth, index)
  StoreLocal(Int, Int)

  /// グローバル変数をロード
  LoadGlobal(Int)  // 名前テーブルインデックス

  /// グローバル変数にストア
  StoreGlobal(Int)  // 名前テーブルインデックス

  /// クロージャを作成
  MakeClosure(Int)  // 定数プール内のコードチャンクインデックス

  /// 関数呼び出し (引数の数)
  Call(Int)

  /// 末尾呼び出し (引数の数)
  TailCall(Int)

  /// 関数からリターン
  Return

  /// 無条件ジャンプ
  Jump(Int)  // 命令オフセット

  /// 条件付きジャンプ（falseの場合）
  JumpIfFalse(Int)  // 命令オフセット

  /// プリミティブ操作を呼び出し
  PrimCall(PrimOpKind, Int)  // 操作種類, 引数の数

  /// 継続をキャプチャ
  CaptureCC

  /// プログラム終了
  Halt

  /// ペアを作成（スタックから2つポップ）
  MakePair

  /// リストを作成（スタックからn個ポップ）
  MakeList(Int)

  /// ベクトルを作成（スタックからn個ポップ）
  MakeVector(Int)

  /// プロミスを作成（遅延評価）
  MakePromise(Int)  // コードチャンクインデックス

  /// and 特殊形式用：falseならジャンプ、そうでなければポップして継続
  AndJump(Int)

  /// or 特殊形式用：trueならジャンプ、そうでなければポップして継続
  OrJump(Int)

  /// スタックトップを複製
  Dup

  /// letrec 用：未初期化スロットを作成
  AllocateLocals(Int)

  /// letrec 用：スロットを初期化
  InitLocal(Int, Int)  // depth, index
} derive(Show)

/// コードチャンク（コンパイル済みの手続き）
pub(all) struct CodeChunk {
  /// 命令列
  code : Array[Opcode]
  /// 定数プール
  constants : Array[BCValue]
  /// グローバル名テーブル
  names : Array[String]
  /// パラメータ数（-1はトップレベル）
  arity : Int
  /// 自由変数の数
  num_free_vars : Int
  /// ローカル変数の数
  num_locals : Int
  /// デバッグ情報（オプション）
  debug_name : String?
} derive(Show)

/// コンパイル済みモジュール
pub(all) struct CompiledModule {
  /// メインのコードチャンク
  main : CodeChunk
  /// 子チャンク（ネストした関数など）
  chunks : Array[CodeChunk]
} derive(Show)

/// 新しいコードチャンクを作成
pub fn new_code_chunk() -> CodeChunk {
  {
    code: [],
    constants: [],
    names: [],
    arity: -1,
    num_free_vars: 0,
    num_locals: 0,
    debug_name: None,
  }
}

/// コードチャンクビルダー
pub(all) struct CodeChunkBuilder {
  /// 命令列
  code : Array[Opcode]
  /// 定数プール
  constants : Array[BCValue]
  /// 定数の重複チェック用マップ
  const_map : @hashmap.T[String, Int]
  /// グローバル名テーブル
  names : Array[String]
  /// 名前の重複チェック用マップ
  name_map : @hashmap.T[String, Int]
  /// パラメータ数
  mut arity : Int
  /// 自由変数の数
  mut num_free_vars : Int
  /// ローカル変数の数
  mut num_locals : Int
  /// デバッグ名
  debug_name : String?
}

/// 新しいビルダーを作成
pub fn new_builder(debug_name : String?) -> CodeChunkBuilder {
  {
    code: [],
    constants: [],
    const_map: @hashmap.new(),
    names: [],
    name_map: @hashmap.new(),
    arity: -1,
    num_free_vars: 0,
    num_locals: 0,
    debug_name,
  }
}

/// 命令を追加
pub fn emit(self : CodeChunkBuilder, op : Opcode) -> Unit {
  self.code.push(op)
}

/// 現在の命令位置を取得
pub fn current_pos(self : CodeChunkBuilder) -> Int {
  self.code.length()
}

/// 命令を特定の位置で更新（ジャンプ先パッチング用）
pub fn patch(self : CodeChunkBuilder, pos : Int, op : Opcode) -> Unit {
  self.code[pos] = op
}

/// 定数を追加して定数プールインデックスを返す
pub fn add_const(self : CodeChunkBuilder, value : BCValue) -> Int {
  // 重複チェック用のキーを生成
  let key = bc_value_to_key(value)
  match self.const_map.get(key) {
    Some(idx) => idx
    None => {
      let idx = self.constants.length()
      self.constants.push(value)
      self.const_map.set(key, idx)
      idx
    }
  }
}

/// BCValue をキー文字列に変換
fn bc_value_to_key(value : BCValue) -> String {
  match value {
    BCValue::Nil => "nil"
    BCValue::Bool(b) => "bool:" + b.to_string()
    BCValue::Int(n) => "int:" + n.to_string()
    BCValue::Real(r) => "real:" + r.to_string()
    BCValue::Char(c) => "char:" + c.to_int().to_string()
    BCValue::String(s) => "string:" + s
    BCValue::Symbol(s) => "symbol:" + s
    BCValue::Closure(idx) => "closure:" + idx.to_string()
  }
}

/// グローバル名を追加して名前テーブルインデックスを返す
pub fn add_name(self : CodeChunkBuilder, name : String) -> Int {
  match self.name_map.get(name) {
    Some(idx) => idx
    None => {
      let idx = self.names.length()
      self.names.push(name)
      self.name_map.set(name, idx)
      idx
    }
  }
}

/// ビルダーからコードチャンクを生成
pub fn build(self : CodeChunkBuilder) -> CodeChunk {
  {
    code: self.code,
    constants: self.constants,
    names: self.names,
    arity: self.arity,
    num_free_vars: self.num_free_vars,
    num_locals: self.num_locals,
    debug_name: self.debug_name,
  }
}

/// IRConst を BCValue に変換
pub fn ir_const_to_bc_value(c : IRConst) -> BCValue {
  match c {
    IRConst::Nil => BCValue::Nil
    IRConst::Bool(b) => BCValue::Bool(b)
    IRConst::Int(n) => BCValue::Int(n)
    IRConst::Real(r) => BCValue::Real(r)
    IRConst::Char(c) => BCValue::Char(c)
    IRConst::String(s) => BCValue::String(s)
    IRConst::Symbol(s) => BCValue::Symbol(s)
    // Pair と Vector は別途処理が必要
    IRConst::Pair(_, _) => BCValue::Nil  // TODO: 構造体として扱う
    IRConst::Vector(_) => BCValue::Nil   // TODO: 構造体として扱う
  }
}

/// BCValue を Value に変換
pub fn bc_value_to_value(v : BCValue) -> Value {
  match v {
    BCValue::Nil => Value::Nil
    BCValue::Bool(b) => Value::Bool(b)
    BCValue::Int(n) => Value::Number(Number::Int(n))
    BCValue::Real(r) => Value::Number(Number::Real(r))
    BCValue::Char(c) => Value::Char(c)
    BCValue::String(s) => Value::String(s)
    BCValue::Symbol(s) => Value::Symbol(s)
    BCValue::Closure(_) => Value::Nil  // クロージャは VM で別途処理
  }
}
