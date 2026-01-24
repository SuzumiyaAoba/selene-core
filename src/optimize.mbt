/// IR 最適化パス
///
/// 中間表現に対して最適化を適用する。
/// - 定数畳み込み (constant folding)
/// - 定数条件の簡約 (constant conditional simplification)
/// - 不要コード除去 (dead code elimination)

/// IR 式を最適化する
pub fn optimize(expr : IRExpr) -> IRExpr {
  // 再帰的に最適化を適用
  let optimized = optimize_expr(expr)
  // 複数パスで収束するまで最適化（最大10回）
  let mut result = optimized
  let mut i = 0
  while i < 10 {
    let new_result = optimize_expr(result)
    // 変化がなければ終了（簡易的な等価性チェック）
    if ir_expr_equal(result, new_result) {
      break
    }
    result = new_result
    i = i + 1
  }
  result
}

/// IR 式を1パスで最適化する
fn optimize_expr(expr : IRExpr) -> IRExpr {
  match expr {
    IRExpr::Const(_) => expr
    IRExpr::Var(_) => expr
    IRExpr::GlobalVar(_) => expr
    IRExpr::Quote(_) => expr

    IRExpr::If(cond, then_branch, else_branch) =>
      optimize_if(cond, then_branch, else_branch)

    IRExpr::Begin(exprs) =>
      optimize_begin(exprs)

    IRExpr::Lambda(info) =>
      optimize_lambda(info)

    IRExpr::App(func, args) =>
      IRExpr::App(optimize_expr(func), optimize_exprs(args))

    IRExpr::TailApp(func, args) =>
      IRExpr::TailApp(optimize_expr(func), optimize_exprs(args))

    IRExpr::Let(bindings, body) =>
      optimize_let(bindings, body)

    IRExpr::Letrec(bindings, body) =>
      optimize_letrec(bindings, body)

    IRExpr::Set(var_ref, value) =>
      IRExpr::Set(var_ref, optimize_expr(value))

    IRExpr::GlobalSet(name, value) =>
      IRExpr::GlobalSet(name, optimize_expr(value))

    IRExpr::PrimOp(kind, args) =>
      optimize_primop(kind, args)

    IRExpr::CallCC(proc) =>
      IRExpr::CallCC(optimize_expr(proc))

    IRExpr::Delay(body) =>
      IRExpr::Delay(optimize_expr(body))

    IRExpr::And(exprs) =>
      optimize_and(exprs)

    IRExpr::Or(exprs) =>
      optimize_or(exprs)
  }
}

/// 式の配列を最適化する
fn optimize_exprs(exprs : Array[IRExpr]) -> Array[IRExpr] {
  let result : Array[IRExpr] = []
  for expr in exprs {
    result.push(optimize_expr(expr))
  }
  result
}

/// if 式を最適化する
fn optimize_if(cond : IRExpr, then_branch : IRExpr, else_branch : IRExpr) -> IRExpr {
  let opt_cond = optimize_expr(cond)
  let opt_then = optimize_expr(then_branch)
  let opt_else = optimize_expr(else_branch)

  // 定数条件の簡約
  match opt_cond {
    IRExpr::Const(IRConst::Bool(true)) => opt_then
    IRExpr::Const(IRConst::Bool(false)) => opt_else
    // #f 以外の値は真
    IRExpr::Const(_) => opt_then
    _ => IRExpr::If(opt_cond, opt_then, opt_else)
  }
}

/// begin 式を最適化する
fn optimize_begin(exprs : Array[IRExpr]) -> IRExpr {
  let optimized = optimize_exprs(exprs)

  // 空の begin は nil
  if optimized.length() == 0 {
    return IRExpr::Const(IRConst::Nil)
  }

  // 単一の式は begin を外す
  if optimized.length() == 1 {
    return optimized[0]
  }

  // ネストした begin をフラット化し、副作用のない中間式を除去
  let flattened : Array[IRExpr] = []
  let len = optimized.length()
  let mut i = 0
  while i < len {
    let expr = optimized[i]
    let is_last = i == len - 1
    match expr {
      // ネストした begin をフラット化
      IRExpr::Begin(inner_exprs) => {
        let inner_len = inner_exprs.length()
        let mut j = 0
        while j < inner_len {
          let inner_is_last = is_last && j == inner_len - 1
          if inner_is_last || has_side_effect(inner_exprs[j]) {
            flattened.push(inner_exprs[j])
          }
          j = j + 1
        }
      }
      // 最後の式または副作用のある式のみ保持
      _ => {
        if is_last || has_side_effect(expr) {
          flattened.push(expr)
        }
      }
    }
    i = i + 1
  }

  if flattened.length() == 0 {
    return IRExpr::Const(IRConst::Nil)
  }
  if flattened.length() == 1 {
    return flattened[0]
  }
  IRExpr::Begin(flattened)
}

/// lambda 式を最適化する
fn optimize_lambda(info : LambdaInfo) -> IRExpr {
  // Lambda 内の変数参照を調整
  // - 自由変数（free_vars に含まれる）: depth=0, index=free_vars リストでの位置
  // - パラメータ（depth=0）: index に num_captures を加える
  let adjusted_body = adjust_lambda_var_refs(
    info.body,
    info.params,
    info.free_vars
  )

  // free_vars の VarRef を親スコープから参照できる形に調整
  // 親スコープから見ると depth を 1 減らす必要がある
  let adjusted_free_vars : Array[VarRef] = []
  for var_ref in info.free_vars {
    adjusted_free_vars.push({
      name: var_ref.name,
      depth: if var_ref.depth > 0 { var_ref.depth - 1 } else { 0 },
      index: var_ref.index
    })
  }

  IRExpr::Lambda({
    params: info.params,
    arity: info.arity,
    body: optimize_expr(adjusted_body),
    free_vars: adjusted_free_vars,
    boxed_params: info.boxed_params,
    boxed_locals: info.boxed_locals,
  })
}

/// Lambda 内の変数参照を調整
fn adjust_lambda_var_refs(
  expr : IRExpr,
  params : Array[String],
  free_vars : Array[VarRef]
) -> IRExpr {
  match expr {
    IRExpr::Var(var_ref) => {
      // 自由変数リストに含まれるかチェック
      let mut free_var_index = -1
      for i in 0..<free_vars.length() {
        if free_vars[i].name == var_ref.name {
          free_var_index = i
          break
        }
      }

      if free_var_index >= 0 {
        // 自由変数：depth=0, index=free_vars リストでの位置
        IRExpr::Var({
          name: var_ref.name,
          depth: 0,
          index: free_var_index,
        })
      } else if var_ref.depth == 0 && var_ref.index < params.length() {
        // このスコープのパラメータ（まだ調整されていない場合のみ）
        // index に num_captures を加える
        // 注: 複数パスで重複調整しないよう、index < params.length() をチェック
        IRExpr::Var({
          name: var_ref.name,
          depth: 0,
          index: var_ref.index + free_vars.length(),
        })
      } else if var_ref.depth == 0 {
        // 既に調整済みのパラメータ（index >= params.length()）
        expr
      } else {
        // さらに外側のスコープの変数（ネストした lambda の場合）
        // そのまま保持（ネストした lambda で処理される）
        expr
      }
    }
    IRExpr::If(cond, then_branch, else_branch) =>
      IRExpr::If(
        adjust_lambda_var_refs(cond, params, free_vars),
        adjust_lambda_var_refs(then_branch, params, free_vars),
        adjust_lambda_var_refs(else_branch, params, free_vars)
      )
    IRExpr::Begin(exprs) => {
      let adjusted : Array[IRExpr] = []
      for e in exprs {
        adjusted.push(adjust_lambda_var_refs(e, params, free_vars))
      }
      IRExpr::Begin(adjusted)
    }
    IRExpr::Lambda(_lambda_info) =>
      // ネストされた lambda はそのまま残す
      // optimize_expr → optimize_lambda で独自に処理される
      expr
    IRExpr::App(func, args) => {
      let adjusted_args : Array[IRExpr] = []
      for arg in args {
        adjusted_args.push(adjust_lambda_var_refs(arg, params, free_vars))
      }
      IRExpr::App(adjust_lambda_var_refs(func, params, free_vars), adjusted_args)
    }
    IRExpr::TailApp(func, args) => {
      let adjusted_args : Array[IRExpr] = []
      for arg in args {
        adjusted_args.push(adjust_lambda_var_refs(arg, params, free_vars))
      }
      IRExpr::TailApp(adjust_lambda_var_refs(func, params, free_vars), adjusted_args)
    }
    IRExpr::Let(bindings, body) => {
      let adjusted_bindings : Array[LetBinding] = []
      for binding in bindings {
        adjusted_bindings.push({
          name: binding.name,
          init: adjust_lambda_var_refs(binding.init, params, free_vars)
        })
      }
      IRExpr::Let(adjusted_bindings, adjust_lambda_var_refs(body, params, free_vars))
    }
    IRExpr::Letrec(bindings, body) => {
      let adjusted_bindings : Array[LetBinding] = []
      for binding in bindings {
        adjusted_bindings.push({
          name: binding.name,
          init: adjust_lambda_var_refs(binding.init, params, free_vars)
        })
      }
      IRExpr::Letrec(adjusted_bindings, adjust_lambda_var_refs(body, params, free_vars))
    }
    IRExpr::Set(var_ref, value) => {
      // 自由変数リストに含まれるかチェック
      let mut free_var_index = -1
      for i in 0..<free_vars.length() {
        if free_vars[i].name == var_ref.name {
          free_var_index = i
          break
        }
      }

      let adjusted_var = if free_var_index >= 0 {
        // 自由変数
        { name: var_ref.name, depth: 0, index: free_var_index }
      } else if var_ref.depth == 0 {
        // このスコープの変数
        { name: var_ref.name, depth: 0, index: var_ref.index + free_vars.length() }
      } else {
        // さらに外側のスコープの変数
        var_ref
      }
      IRExpr::Set(adjusted_var, adjust_lambda_var_refs(value, params, free_vars))
    }
    IRExpr::GlobalSet(name, value) =>
      IRExpr::GlobalSet(name, adjust_lambda_var_refs(value, params, free_vars))
    IRExpr::PrimOp(kind, args) => {
      let adjusted_args : Array[IRExpr] = []
      for arg in args {
        adjusted_args.push(adjust_lambda_var_refs(arg, params, free_vars))
      }
      IRExpr::PrimOp(kind, adjusted_args)
    }
    IRExpr::CallCC(proc) =>
      IRExpr::CallCC(adjust_lambda_var_refs(proc, params, free_vars))
    IRExpr::Delay(body) =>
      IRExpr::Delay(adjust_lambda_var_refs(body, params, free_vars))
    IRExpr::And(exprs) => {
      let adjusted : Array[IRExpr] = []
      for e in exprs {
        adjusted.push(adjust_lambda_var_refs(e, params, free_vars))
      }
      IRExpr::And(adjusted)
    }
    IRExpr::Or(exprs) => {
      let adjusted : Array[IRExpr] = []
      for e in exprs {
        adjusted.push(adjust_lambda_var_refs(e, params, free_vars))
      }
      IRExpr::Or(adjusted)
    }
    _ => expr
  }
}

/// let 式を最適化する
fn optimize_let(bindings : Array[LetBinding], body : IRExpr) -> IRExpr {
  // バインディングの初期化式を最適化
  let opt_bindings : Array[LetBinding] = []
  for binding in bindings {
    opt_bindings.push({ name: binding.name, init: optimize_expr(binding.init) })
  }

  // ボディを最適化
  let opt_body = optimize_expr(body)

  // 空のバインディングは let を外す
  if opt_bindings.length() == 0 {
    return opt_body
  }

  IRExpr::Let(opt_bindings, opt_body)
}

/// letrec 式を最適化する
fn optimize_letrec(bindings : Array[LetBinding], body : IRExpr) -> IRExpr {
  let opt_bindings : Array[LetBinding] = []
  for binding in bindings {
    opt_bindings.push({ name: binding.name, init: optimize_expr(binding.init) })
  }

  let opt_body = optimize_expr(body)

  if opt_bindings.length() == 0 {
    return opt_body
  }

  IRExpr::Letrec(opt_bindings, opt_body)
}

/// プリミティブ操作を最適化する（定数畳み込み）
fn optimize_primop(kind : PrimOpKind, args : Array[IRExpr]) -> IRExpr {
  let opt_args = optimize_exprs(args)

  // すべての引数が定数かチェック
  if all_const(opt_args) {
    // 定数畳み込みを試行
    match fold_primop(kind, opt_args) {
      Some(result) => return result
      None => ()
    }
  }

  // 部分的な最適化
  match kind {
    // (+ 0 x) => x, (+ x 0) => x
    PrimOpKind::Add => {
      if opt_args.length() == 2 {
        if is_zero(opt_args[0]) {
          return opt_args[1]
        }
        if is_zero(opt_args[1]) {
          return opt_args[0]
        }
      }
    }
    // (* 1 x) => x, (* x 1) => x, (* 0 x) => 0, (* x 0) => 0
    PrimOpKind::Mul => {
      if opt_args.length() == 2 {
        if is_one(opt_args[0]) {
          return opt_args[1]
        }
        if is_one(opt_args[1]) {
          return opt_args[0]
        }
        if is_zero(opt_args[0]) {
          return IRExpr::Const(IRConst::Int(0))
        }
        if is_zero(opt_args[1]) {
          return IRExpr::Const(IRConst::Int(0))
        }
      }
    }
    // (- x 0) => x
    PrimOpKind::Sub => {
      if opt_args.length() == 2 && is_zero(opt_args[1]) {
        return opt_args[0]
      }
    }
    // (/ x 1) => x
    PrimOpKind::Div => {
      if opt_args.length() == 2 && is_one(opt_args[1]) {
        return opt_args[0]
      }
    }
    // (not #t) => #f, (not #f) => #t
    PrimOpKind::Not => {
      if opt_args.length() == 1 {
        match opt_args[0] {
          IRExpr::Const(IRConst::Bool(b)) =>
            return IRExpr::Const(IRConst::Bool(not(b)))
          _ => ()
        }
      }
    }
    _ => ()
  }

  IRExpr::PrimOp(kind, opt_args)
}

/// and 式を最適化する
fn optimize_and(exprs : Array[IRExpr]) -> IRExpr {
  let opt_exprs = optimize_exprs(exprs)

  if opt_exprs.length() == 0 {
    return IRExpr::Const(IRConst::Bool(true))
  }

  // 定数の簡約
  let filtered : Array[IRExpr] = []
  for expr in opt_exprs {
    match expr {
      // #f があれば全体が #f
      IRExpr::Const(IRConst::Bool(false)) =>
        return IRExpr::Const(IRConst::Bool(false))
      // #t は除去可能（最後以外）
      IRExpr::Const(IRConst::Bool(true)) => {
        // 最後の式以外の #t は除去
        ()
      }
      _ => filtered.push(expr)
    }
  }

  // すべて #t だった場合
  if filtered.length() == 0 {
    // 最後の式が #t なら #t を返す
    let last_expr = opt_exprs[opt_exprs.length() - 1]
    match last_expr {
      IRExpr::Const(c) => return IRExpr::Const(c)
      _ => return IRExpr::Const(IRConst::Bool(true))
    }
  }

  if filtered.length() == 1 {
    return filtered[0]
  }

  IRExpr::And(filtered)
}

/// or 式を最適化する
fn optimize_or(exprs : Array[IRExpr]) -> IRExpr {
  let opt_exprs = optimize_exprs(exprs)

  if opt_exprs.length() == 0 {
    return IRExpr::Const(IRConst::Bool(false))
  }

  // 定数の簡約
  let filtered : Array[IRExpr] = []
  for expr in opt_exprs {
    match expr {
      // #t があれば全体が #t（他の真値も同様）
      IRExpr::Const(IRConst::Bool(true)) =>
        return IRExpr::Const(IRConst::Bool(true))
      // 非#f定数は真値
      IRExpr::Const(IRConst::Bool(false)) => {
        // #f は除去
        ()
      }
      IRExpr::Const(c) =>
        // 他の定数は真値なので即座にそれを返す
        return IRExpr::Const(c)
      _ => filtered.push(expr)
    }
  }

  if filtered.length() == 0 {
    return IRExpr::Const(IRConst::Bool(false))
  }

  if filtered.length() == 1 {
    return filtered[0]
  }

  IRExpr::Or(filtered)
}

/// すべての引数が定数かチェック
fn all_const(exprs : Array[IRExpr]) -> Bool {
  for expr in exprs {
    match expr {
      IRExpr::Const(_) => ()
      _ => return false
    }
  }
  true
}

/// 式が 0 かどうか
fn is_zero(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(IRConst::Int(0)) => true
    IRExpr::Const(IRConst::Real(r)) => r == 0.0
    _ => false
  }
}

/// 式が 1 かどうか
fn is_one(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(IRConst::Int(1)) => true
    IRExpr::Const(IRConst::Real(r)) => r == 1.0
    _ => false
  }
}

/// 式に副作用があるかどうか（簡易判定）
fn has_side_effect(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(_) => false
    IRExpr::Var(_) => false
    IRExpr::GlobalVar(_) => false
    IRExpr::Quote(_) => false
    IRExpr::Lambda(_) => false
    // set! は副作用
    IRExpr::Set(_, _) => true
    IRExpr::GlobalSet(_, _) => true
    // 関数呼び出しは副作用の可能性
    IRExpr::App(_, _) => true
    IRExpr::TailApp(_, _) => true
    IRExpr::CallCC(_) => true
    // 一部の PrimOp は副作用
    IRExpr::PrimOp(kind, _) =>
      match kind {
        PrimOpKind::Display => true
        PrimOpKind::Newline => true
        PrimOpKind::Write => true
        PrimOpKind::Read => true
        PrimOpKind::SetCar => true
        PrimOpKind::SetCdr => true
        PrimOpKind::VectorSet => true
        PrimOpKind::OpenInputFile => true
        PrimOpKind::OpenOutputFile => true
        PrimOpKind::CloseInputPort => true
        PrimOpKind::CloseOutputPort => true
        PrimOpKind::ReadChar => true
        PrimOpKind::PeekChar => true
        PrimOpKind::WriteChar => true
        _ => false
      }
    // if, begin, let 等は子要素を見る必要があるが、保守的に副作用ありとする
    _ => true
  }
}

/// プリミティブ操作の定数畳み込み
fn fold_primop(kind : PrimOpKind, args : Array[IRExpr]) -> IRExpr? {
  match kind {
    // 算術演算
    PrimOpKind::Add => fold_add(args)
    PrimOpKind::Sub => fold_sub(args)
    PrimOpKind::Mul => fold_mul(args)
    PrimOpKind::Div => fold_div(args)
    PrimOpKind::Quotient => fold_quotient(args)
    PrimOpKind::Remainder => fold_remainder(args)
    PrimOpKind::Modulo => fold_modulo(args)
    PrimOpKind::Abs => fold_abs(args)

    // 比較演算
    PrimOpKind::NumEq => fold_num_eq(args)
    PrimOpKind::Lt => fold_lt(args)
    PrimOpKind::Gt => fold_gt(args)
    PrimOpKind::Le => fold_le(args)
    PrimOpKind::Ge => fold_ge(args)

    // 数値述語
    PrimOpKind::ZeroP => fold_zero_p(args)
    PrimOpKind::PositiveP => fold_positive_p(args)
    PrimOpKind::NegativeP => fold_negative_p(args)
    PrimOpKind::OddP => fold_odd_p(args)
    PrimOpKind::EvenP => fold_even_p(args)

    // 型述語
    PrimOpKind::NullP => fold_null_p(args)
    PrimOpKind::BooleanP => fold_boolean_p(args)
    PrimOpKind::NumberP => fold_number_p(args)
    PrimOpKind::IntegerP => fold_integer_p(args)
    PrimOpKind::PairP => fold_pair_p(args)
    PrimOpKind::SymbolP => fold_symbol_p(args)
    PrimOpKind::StringP => fold_string_p(args)
    PrimOpKind::CharP => fold_char_p(args)

    // 論理演算
    PrimOpKind::Not => fold_not(args)

    // 文字列
    PrimOpKind::StringLength => fold_string_length(args)

    // リスト
    PrimOpKind::Car => fold_car(args)
    PrimOpKind::Cdr => fold_cdr(args)
    PrimOpKind::Cons => fold_cons(args)
    PrimOpKind::Length => fold_length(args)

    _ => None
  }
}

/// 加算の定数畳み込み
fn fold_add(args : Array[IRExpr]) -> IRExpr? {
  if args.length() == 0 {
    return Some(IRExpr::Const(IRConst::Int(0)))
  }
  let mut sum = 0
  let mut has_real = false
  let mut real_sum = 0.0

  for arg in args {
    match arg {
      IRExpr::Const(IRConst::Int(n)) => {
        if has_real {
          real_sum = real_sum + n.to_double()
        } else {
          sum = sum + n
        }
      }
      IRExpr::Const(IRConst::Real(r)) => {
        if not(has_real) {
          real_sum = sum.to_double()
          has_real = true
        }
        real_sum = real_sum + r
      }
      _ => return None
    }
  }

  if has_real {
    Some(IRExpr::Const(IRConst::Real(real_sum)))
  } else {
    Some(IRExpr::Const(IRConst::Int(sum)))
  }
}

/// 減算の定数畳み込み
fn fold_sub(args : Array[IRExpr]) -> IRExpr? {
  if args.length() == 0 {
    return None
  }
  if args.length() == 1 {
    // 単項マイナス
    match args[0] {
      IRExpr::Const(IRConst::Int(n)) => return Some(IRExpr::Const(IRConst::Int(-n)))
      IRExpr::Const(IRConst::Real(r)) => return Some(IRExpr::Const(IRConst::Real(-r)))
      _ => return None
    }
  }

  // 二項以上
  let mut result = 0
  let mut has_real = false
  let mut real_result = 0.0
  let mut first = true

  for arg in args {
    match arg {
      IRExpr::Const(IRConst::Int(n)) => {
        if first {
          if has_real {
            real_result = n.to_double()
          } else {
            result = n
          }
          first = false
        } else {
          if has_real {
            real_result = real_result - n.to_double()
          } else {
            result = result - n
          }
        }
      }
      IRExpr::Const(IRConst::Real(r)) => {
        if not(has_real) {
          real_result = result.to_double()
          has_real = true
        }
        if first {
          real_result = r
          first = false
        } else {
          real_result = real_result - r
        }
      }
      _ => return None
    }
  }

  if has_real {
    Some(IRExpr::Const(IRConst::Real(real_result)))
  } else {
    Some(IRExpr::Const(IRConst::Int(result)))
  }
}

/// 乗算の定数畳み込み
fn fold_mul(args : Array[IRExpr]) -> IRExpr? {
  if args.length() == 0 {
    return Some(IRExpr::Const(IRConst::Int(1)))
  }
  let mut product = 1
  let mut has_real = false
  let mut real_product = 1.0

  for arg in args {
    match arg {
      IRExpr::Const(IRConst::Int(n)) => {
        if has_real {
          real_product = real_product * n.to_double()
        } else {
          product = product * n
        }
      }
      IRExpr::Const(IRConst::Real(r)) => {
        if not(has_real) {
          real_product = product.to_double()
          has_real = true
        }
        real_product = real_product * r
      }
      _ => return None
    }
  }

  if has_real {
    Some(IRExpr::Const(IRConst::Real(real_product)))
  } else {
    Some(IRExpr::Const(IRConst::Int(product)))
  }
}

/// 除算の定数畳み込み
fn fold_div(args : Array[IRExpr]) -> IRExpr? {
  if args.length() < 2 {
    return None
  }

  let first = match args[0] {
    IRExpr::Const(IRConst::Int(n)) => n.to_double()
    IRExpr::Const(IRConst::Real(r)) => r
    _ => return None
  }

  let mut result = first
  let mut i = 1
  while i < args.length() {
    let divisor = match args[i] {
      IRExpr::Const(IRConst::Int(n)) => n.to_double()
      IRExpr::Const(IRConst::Real(r)) => r
      _ => return None
    }
    if divisor == 0.0 {
      return None  // 0 除算は畳み込まない
    }
    result = result / divisor
    i = i + 1
  }

  Some(IRExpr::Const(IRConst::Real(result)))
}

/// 整数除算の定数畳み込み
fn fold_quotient(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 2 {
    return None
  }
  match (args[0], args[1]) {
    (IRExpr::Const(IRConst::Int(a)), IRExpr::Const(IRConst::Int(b))) => {
      if b == 0 {
        return None
      }
      Some(IRExpr::Const(IRConst::Int(a / b)))
    }
    _ => None
  }
}

/// 剰余の定数畳み込み
fn fold_remainder(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 2 {
    return None
  }
  match (args[0], args[1]) {
    (IRExpr::Const(IRConst::Int(a)), IRExpr::Const(IRConst::Int(b))) => {
      if b == 0 {
        return None
      }
      Some(IRExpr::Const(IRConst::Int(a % b)))
    }
    _ => None
  }
}

/// modulo の定数畳み込み
fn fold_modulo(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 2 {
    return None
  }
  match (args[0], args[1]) {
    (IRExpr::Const(IRConst::Int(a)), IRExpr::Const(IRConst::Int(b))) => {
      if b == 0 {
        return None
      }
      let r = a % b
      // modulo は常に b と同符号
      if (r < 0 && b > 0) || (r > 0 && b < 0) {
        Some(IRExpr::Const(IRConst::Int(r + b)))
      } else {
        Some(IRExpr::Const(IRConst::Int(r)))
      }
    }
    _ => None
  }
}

/// 絶対値の定数畳み込み
fn fold_abs(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(n)) => {
      if n < 0 {
        Some(IRExpr::Const(IRConst::Int(-n)))
      } else {
        Some(IRExpr::Const(IRConst::Int(n)))
      }
    }
    IRExpr::Const(IRConst::Real(r)) => {
      if r < 0.0 {
        Some(IRExpr::Const(IRConst::Real(-r)))
      } else {
        Some(IRExpr::Const(IRConst::Real(r)))
      }
    }
    _ => None
  }
}

/// 数値等価の定数畳み込み
fn fold_num_eq(args : Array[IRExpr]) -> IRExpr? {
  if args.length() < 2 {
    return Some(IRExpr::Const(IRConst::Bool(true)))
  }

  let first = extract_number(args[0])
  match first {
    None => return None
    Some(n) => {
      let mut i = 1
      while i < args.length() {
        match extract_number(args[i]) {
          None => return None
          Some(m) => {
            if n != m {
              return Some(IRExpr::Const(IRConst::Bool(false)))
            }
          }
        }
        i = i + 1
      }
      Some(IRExpr::Const(IRConst::Bool(true)))
    }
  }
}

/// 小なりの定数畳み込み
fn fold_lt(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a < b })
}

/// 大なりの定数畳み込み
fn fold_gt(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a > b })
}

/// 小なりイコールの定数畳み込み
fn fold_le(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a <= b })
}

/// 大なりイコールの定数畳み込み
fn fold_ge(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a >= b })
}

/// 比較操作の汎用定数畳み込み
fn fold_comparison(args : Array[IRExpr], cmp : (Double, Double) -> Bool) -> IRExpr? {
  if args.length() < 2 {
    return Some(IRExpr::Const(IRConst::Bool(true)))
  }

  let mut prev = match extract_number(args[0]) {
    Some(n) => n
    None => return None
  }

  let mut i = 1
  while i < args.length() {
    match extract_number(args[i]) {
      None => return None
      Some(curr) => {
        if not(cmp(prev, curr)) {
          return Some(IRExpr::Const(IRConst::Bool(false)))
        }
        prev = curr
      }
    }
    i = i + 1
  }
  Some(IRExpr::Const(IRConst::Bool(true)))
}

/// 数値を抽出
fn extract_number(expr : IRExpr) -> Double? {
  match expr {
    IRExpr::Const(IRConst::Int(n)) => Some(n.to_double())
    IRExpr::Const(IRConst::Real(r)) => Some(r)
    _ => None
  }
}

/// zero? の定数畳み込み
fn fold_zero_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n == 0.0)))
    None => None
  }
}

/// positive? の定数畳み込み
fn fold_positive_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n > 0.0)))
    None => None
  }
}

/// negative? の定数畳み込み
fn fold_negative_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n < 0.0)))
    None => None
  }
}

/// odd? の定数畳み込み
fn fold_odd_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(n)) => Some(IRExpr::Const(IRConst::Bool(n % 2 != 0)))
    _ => None
  }
}

/// even? の定数畳み込み
fn fold_even_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(n)) => Some(IRExpr::Const(IRConst::Bool(n % 2 == 0)))
    _ => None
  }
}

/// null? の定数畳み込み
fn fold_null_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Nil) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// boolean? の定数畳み込み
fn fold_boolean_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Bool(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// number? の定数畳み込み
fn fold_number_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(IRConst::Real(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// integer? の定数畳み込み
fn fold_integer_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// pair? の定数畳み込み
fn fold_pair_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Pair(_, _)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// symbol? の定数畳み込み
fn fold_symbol_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Symbol(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// string? の定数畳み込み
fn fold_string_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::String(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// char? の定数畳み込み
fn fold_char_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Char(_)) => Some(IRExpr::Const(IRConst::Bool(true)))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))
    _ => None
  }
}

/// not の定数畳み込み
fn fold_not(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Bool(b)) => Some(IRExpr::Const(IRConst::Bool(not(b))))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))  // #f 以外は真
    _ => None
  }
}

/// string-length の定数畳み込み
fn fold_string_length(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::String(s)) => Some(IRExpr::Const(IRConst::Int(s.length())))
    _ => None
  }
}

/// car の定数畳み込み
fn fold_car(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Pair(car, _)) => Some(IRExpr::Const(car))
    _ => None
  }
}

/// cdr の定数畳み込み
fn fold_cdr(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Pair(_, cdr)) => Some(IRExpr::Const(cdr))
    _ => None
  }
}

/// cons の定数畳み込み
fn fold_cons(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 2 {
    return None
  }
  match (args[0], args[1]) {
    (IRExpr::Const(car), IRExpr::Const(cdr)) =>
      Some(IRExpr::Const(IRConst::Pair(car, cdr)))
    _ => None
  }
}

/// length の定数畳み込み
fn fold_length(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(c) => {
      match ir_const_length(c) {
        Some(len) => Some(IRExpr::Const(IRConst::Int(len)))
        None => None
      }
    }
    _ => None
  }
}

/// IRConst のリスト長を計算
fn ir_const_length(c : IRConst) -> Int? {
  let mut len = 0
  let mut current = c
  while true {
    match current {
      IRConst::Nil => return Some(len)
      IRConst::Pair(_, cdr) => {
        len = len + 1
        current = cdr
      }
      _ => return None  // proper list でない
    }
  }
  Some(len)
}

/// IRExpr の等価性チェック（簡易版）
fn ir_expr_equal(a : IRExpr, b : IRExpr) -> Bool {
  match (a, b) {
    (IRExpr::Const(c1), IRExpr::Const(c2)) => ir_const_equal(c1, c2)
    (IRExpr::Var(v1), IRExpr::Var(v2)) => v1 == v2
    (IRExpr::GlobalVar(n1), IRExpr::GlobalVar(n2)) => n1 == n2
    (IRExpr::Quote(c1), IRExpr::Quote(c2)) => ir_const_equal(c1, c2)
    (IRExpr::If(c1, t1, e1), IRExpr::If(c2, t2, e2)) =>
      ir_expr_equal(c1, c2) && ir_expr_equal(t1, t2) && ir_expr_equal(e1, e2)
    (IRExpr::Begin(es1), IRExpr::Begin(es2)) => ir_exprs_equal(es1, es2)
    (IRExpr::App(f1, as1), IRExpr::App(f2, as2)) =>
      ir_expr_equal(f1, f2) && ir_exprs_equal(as1, as2)
    (IRExpr::TailApp(f1, as1), IRExpr::TailApp(f2, as2)) =>
      ir_expr_equal(f1, f2) && ir_exprs_equal(as1, as2)
    (IRExpr::PrimOp(k1, as1), IRExpr::PrimOp(k2, as2)) =>
      primop_equal(k1, k2) && ir_exprs_equal(as1, as2)
    (IRExpr::And(es1), IRExpr::And(es2)) => ir_exprs_equal(es1, es2)
    (IRExpr::Or(es1), IRExpr::Or(es2)) => ir_exprs_equal(es1, es2)
    (IRExpr::Set(v1, e1), IRExpr::Set(v2, e2)) =>
      v1 == v2 && ir_expr_equal(e1, e2)
    (IRExpr::GlobalSet(n1, e1), IRExpr::GlobalSet(n2, e2)) =>
      n1 == n2 && ir_expr_equal(e1, e2)
    (IRExpr::CallCC(p1), IRExpr::CallCC(p2)) => ir_expr_equal(p1, p2)
    (IRExpr::Delay(e1), IRExpr::Delay(e2)) => ir_expr_equal(e1, e2)
    // Lambda, Let, Letrec は構造が複雑なので保守的に false
    _ => false
  }
}

/// IRExpr 配列の等価性チェック
fn ir_exprs_equal(as1 : Array[IRExpr], as2 : Array[IRExpr]) -> Bool {
  if as1.length() != as2.length() {
    return false
  }
  let mut i = 0
  while i < as1.length() {
    if not(ir_expr_equal(as1[i], as2[i])) {
      return false
    }
    i = i + 1
  }
  true
}

/// IRConst の等価性チェック
fn ir_const_equal(a : IRConst, b : IRConst) -> Bool {
  match (a, b) {
    (IRConst::Nil, IRConst::Nil) => true
    (IRConst::Bool(b1), IRConst::Bool(b2)) => b1 == b2
    (IRConst::Int(n1), IRConst::Int(n2)) => n1 == n2
    (IRConst::Real(r1), IRConst::Real(r2)) => r1 == r2
    (IRConst::Char(c1), IRConst::Char(c2)) => c1 == c2
    (IRConst::String(s1), IRConst::String(s2)) => s1 == s2
    (IRConst::Symbol(s1), IRConst::Symbol(s2)) => s1 == s2
    (IRConst::Pair(a1, d1), IRConst::Pair(a2, d2)) =>
      ir_const_equal(a1, a2) && ir_const_equal(d1, d2)
    (IRConst::Vector(vs1), IRConst::Vector(vs2)) => {
      if vs1.length() != vs2.length() {
        return false
      }
      let mut i = 0
      while i < vs1.length() {
        if not(ir_const_equal(vs1[i], vs2[i])) {
          return false
        }
        i = i + 1
      }
      true
    }
    _ => false
  }
}

/// PrimOpKind の等価性チェック
fn primop_equal(a : PrimOpKind, b : PrimOpKind) -> Bool {
  // MoonBit では enum の等価性は自動的にサポートされる場合がある
  // 保守的に文字列化して比較
  a.to_string() == b.to_string()
}
