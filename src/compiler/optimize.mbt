/// IR optimization pass
///
/// Apply optimization to the intermediate representation.
/// - constant folding
/// - constant conditional simplification
/// - Dead code elimination

/// Optimize IR expressions
pub fn optimize(expr : IRExpr) -> IRExpr {
  // Apply optimization recursively
  let optimized = optimize_expr(expr)
  // Optimize in multiple passes until convergence (up to 10 times)
  let mut result = optimized
  let mut i = 0
  while i < 10 {
    let new_result = optimize_expr(result)
    // End if there is no change (simple equality check)
    if ir_expr_equal(result, new_result) {
      break
    }
    result = new_result
    i = i + 1
  }
  result
}

/// Optimize IR expression in one pass
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
      optimize_app(func, args, false)

    IRExpr::TailApp(func, args) =>
      optimize_app(func, args, true)

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

/// Optimize arrays of expressions
fn optimize_exprs(exprs : Array[IRExpr]) -> Array[IRExpr] {
  let result : Array[IRExpr] = []
  for expr in exprs {
    result.push(optimize_expr(expr))
  }
  result
}

/// Optimize function application (including inline expansion)
fn optimize_app(func : IRExpr, args : Array[IRExpr], is_tail : Bool) -> IRExpr {
  let opt_func = optimize_expr(func)
  let opt_args = optimize_exprs(args)

  // Inline direct Lambda calls
  // ((lambda (x) body) arg) => (let ((x arg)) body)
  match opt_func {
    IRExpr::Lambda(info) => {
      // Inline only if number of arguments match
      if info.arity >= 0 && opt_args.length() == info.arity {
        // Inline only if there are no free variables (avoid complex closures)
        if info.free_vars.length() == 0 && info.boxed_params.length() == 0 {
          // Inline only when body size is small
          if ir_expr_size(info.body) <= 20 {
            // Convert to let binding
            let bindings : Array[LetBinding] = []
            let mut i = 0
            while i < info.params.length() {
              bindings.push({ name: info.params[i], init: opt_args[i] })
              i = i + 1
            }
            // The variable reference index in body should already be correct
            return optimize_expr(IRExpr::Let(bindings, info.body))
          }
        }
      }
    }
    _ => ()
  }

  // If inlining is not possible, normal function call
  if is_tail {
    IRExpr::TailApp(opt_func, opt_args)
  } else {
    IRExpr::App(opt_func, opt_args)
  }
}

/// Calculate size (number of nodes) of IR expression
fn ir_expr_size(expr : IRExpr) -> Int {
  match expr {
    IRExpr::Const(_) => 1
    IRExpr::Var(_) => 1
    IRExpr::GlobalVar(_) => 1
    IRExpr::Quote(_) => 1
    IRExpr::If(cond, then_branch, else_branch) =>
      1 + ir_expr_size(cond) + ir_expr_size(then_branch) + ir_expr_size(else_branch)
    IRExpr::Begin(exprs) => {
      let mut size = 1
      for e in exprs {
        size = size + ir_expr_size(e)
      }
      size
    }
    IRExpr::Lambda(info) => 1 + ir_expr_size(info.body)
    IRExpr::App(func, args) => {
      let mut size = 1 + ir_expr_size(func)
      for arg in args {
        size = size + ir_expr_size(arg)
      }
      size
    }
    IRExpr::TailApp(func, args) => {
      let mut size = 1 + ir_expr_size(func)
      for arg in args {
        size = size + ir_expr_size(arg)
      }
      size
    }
    IRExpr::Let(bindings, body) => {
      let mut size = 1 + ir_expr_size(body)
      for binding in bindings {
        size = size + ir_expr_size(binding.init)
      }
      size
    }
    IRExpr::Letrec(bindings, body) => {
      let mut size = 1 + ir_expr_size(body)
      for binding in bindings {
        size = size + ir_expr_size(binding.init)
      }
      size
    }
    IRExpr::Set(_, value) => 1 + ir_expr_size(value)
    IRExpr::GlobalSet(_, value) => 1 + ir_expr_size(value)
    IRExpr::PrimOp(_, args) => {
      let mut size = 1
      for arg in args {
        size = size + ir_expr_size(arg)
      }
      size
    }
    IRExpr::CallCC(proc) => 1 + ir_expr_size(proc)
    IRExpr::Delay(body) => 1 + ir_expr_size(body)
    IRExpr::And(exprs) => {
      let mut size = 1
      for e in exprs {
        size = size + ir_expr_size(e)
      }
      size
    }
    IRExpr::Or(exprs) => {
      let mut size = 1
      for e in exprs {
        size = size + ir_expr_size(e)
      }
      size
    }
  }
}

/// Optimize if expressions
fn optimize_if(cond : IRExpr, then_branch : IRExpr, else_branch : IRExpr) -> IRExpr {
  let opt_cond = optimize_expr(cond)
  let opt_then = optimize_expr(then_branch)
  let opt_else = optimize_expr(else_branch)

  // Constant condition reduction
  match opt_cond {
    IRExpr::Const(IRConst::Bool(true)) => opt_then
    IRExpr::Const(IRConst::Bool(false)) => opt_else
    // Values ​​other than #f are true
    IRExpr::Const(_) => opt_then
    _ => IRExpr::If(opt_cond, opt_then, opt_else)
  }
}

/// Optimize the begin expression
fn optimize_begin(exprs : Array[IRExpr]) -> IRExpr {
  let optimized = optimize_exprs(exprs)

  // Empty begin is nil
  if optimized.length() == 0 {
    return IRExpr::Const(IRConst::Nil)
  }

  // Single expressions remove begin
  if optimized.length() == 1 {
    return optimized[0]
  }

  // Flatten nested begin and remove intermediate expressions without side effects
  let flattened : Array[IRExpr] = []
  let len = optimized.length()
  let mut i = 0
  while i < len {
    let expr = optimized[i]
    let is_last = i == len - 1
    match expr {
      // Flatten nested begin
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
      // Keep only the last expression or expressions with side effects
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

/// Optimize lambda expressions
fn optimize_lambda(info : LambdaInfo) -> IRExpr {
  // Adjust variable references in Lambda
  // - Free variables (contained in free_vars): depth=0, index=free_vars position in list
  // - Parameter (depth=0): add num_captures to index
  let adjusted_body = adjust_lambda_var_refs(
    info.body,
    info.params,
    info.free_vars
  )

  // Adjust VarRef of free_vars so that it can be referenced from the parent scope.
  // From the perspective of the parent scope, depth needs to be decreased by 1
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
    rest_param: info.rest_param,
    body: optimize_expr(adjusted_body),
    free_vars: adjusted_free_vars,
    boxed_params: info.boxed_params,
    boxed_locals: info.boxed_locals,
    boxed_free_vars: info.boxed_free_vars,
  })
}

/// Adjust variable references in Lambda
fn adjust_lambda_var_refs(
  expr : IRExpr,
  params : Array[String],
  free_vars : Array[VarRef]
) -> IRExpr {
  match expr {
    IRExpr::Var(var_ref) => {
      // Check whether it is included in the free variable list
      let mut free_var_index = -1
      for i in 0..<free_vars.length() {
        if free_vars[i].name == var_ref.name {
          free_var_index = i
          break
        }
      }

      if free_var_index >= 0 {
        // Free variables: depth=0, index=free_vars Position in list
        IRExpr::Var({
          name: var_ref.name,
          depth: 0,
          index: free_var_index,
        })
      } else if var_ref.depth == 0 {
        // Check if this is a parameter (by checking if name is in params)
        let mut is_param = false
        for p in params {
          if p == var_ref.name {
            is_param = true
            break
          }
        }
        if is_param {
          // Parameter: check if already adjusted (index >= params.length())
          if var_ref.index < params.length() {
            // Not yet adjusted: add num_captures to index
            IRExpr::Var({
              name: var_ref.name,
              depth: 0,
              index: var_ref.index + free_vars.length(),
            })
          } else {
            // Already adjusted
            expr
          }
        } else {
          // Let binding: check if already adjusted (index >= free_vars.length() + params.length())
          if var_ref.index < free_vars.length() + params.length() {
            // Not yet adjusted: add num_captures to index
            IRExpr::Var({
              name: var_ref.name,
              depth: 0,
              index: var_ref.index + free_vars.length(),
            })
          } else {
            // Already adjusted
            expr
          }
        }
      } else {
        // Variables in further outer scope (for nested lambdas)
        // Keep as is (processed by nested lambda)
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
      // Leave nested lambdas alone
      // optimize_expr → processed independently by optimize_lambda
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
      // Check whether it is included in the free variable list
      let mut free_var_index = -1
      for i in 0..<free_vars.length() {
        if free_vars[i].name == var_ref.name {
          free_var_index = i
          break
        }
      }

      let adjusted_var = if free_var_index >= 0 {
        // free variable
        { name: var_ref.name, depth: 0, index: free_var_index }
      } else if var_ref.depth == 0 {
        // Check if this is a parameter
        let mut is_param = false
        for p in params {
          if p == var_ref.name {
            is_param = true
            break
          }
        }
        if is_param {
          // Parameter: check if already adjusted
          if var_ref.index < params.length() {
            { name: var_ref.name, depth: 0, index: var_ref.index + free_vars.length() }
          } else {
            var_ref
          }
        } else {
          // Let binding: check if already adjusted
          if var_ref.index < free_vars.length() + params.length() {
            { name: var_ref.name, depth: 0, index: var_ref.index + free_vars.length() }
          } else {
            var_ref
          }
        }
      } else {
        // variables in further outer scopes
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

/// Optimize let expressions
fn optimize_let(bindings : Array[LetBinding], body : IRExpr) -> IRExpr {
  // Optimize binding initialization expressions
  let opt_bindings : Array[LetBinding] = []
  for binding in bindings {
    opt_bindings.push({ name: binding.name, init: optimize_expr(binding.init) })
  }

  // Optimize the body
  let opt_body = optimize_expr(body)

  // Empty binding removes let
  if opt_bindings.length() == 0 {
    return opt_body
  }

  // Eliminate unnecessary code: remove unused bindings
  let used_vars = collect_used_vars(opt_body)
  let live_bindings : Array[LetBinding] = []
  let side_effect_exprs : Array[IRExpr] = []
  let removed_indices : Array[Int] = []

  let mut idx = 0
  for binding in opt_bindings {
    if used_vars.contains(binding.name) {
      // Retain if variable is used
      live_bindings.push(binding)
    } else if has_side_effect(binding.init) {
      // Execute only the expression if there are side effects
      side_effect_exprs.push(binding.init)
      removed_indices.push(idx)
    } else {
      // Remove if not used and have no side effects
      removed_indices.push(idx)
    }
    idx = idx + 1
  }

  // If all bindings are removed
  if live_bindings.length() == 0 {
    if side_effect_exprs.length() == 0 {
      // Adjust body's VarRef indices before returning
      return adjust_var_indices_after_removal(opt_body, removed_indices)
    }
    // Wrapping expressions with side effects in begin
    let adjusted_body = adjust_var_indices_after_removal(opt_body, removed_indices)
    side_effect_exprs.push(adjusted_body)
    return IRExpr::Begin(side_effect_exprs)
  }

  // Adjust VarRef indices in live_bindings and body if any bindings were removed
  if removed_indices.length() > 0 {
    let adjusted_bindings : Array[LetBinding] = []
    for binding in live_bindings {
      adjusted_bindings.push({
        name: binding.name,
        init: adjust_var_indices_after_removal(binding.init, removed_indices),
      })
    }
    let adjusted_body = adjust_var_indices_after_removal(opt_body, removed_indices)

    // If you have a removed expression with side effects
    if side_effect_exprs.length() > 0 {
      // Execute side effects before body of let
      side_effect_exprs.push(adjusted_body)
      return IRExpr::Let(adjusted_bindings, IRExpr::Begin(side_effect_exprs))
    }

    return IRExpr::Let(adjusted_bindings, adjusted_body)
  }

  // If you have a removed expression with side effects
  if side_effect_exprs.length() > 0 {
    // Execute side effects before body of let
    side_effect_exprs.push(opt_body)
    return IRExpr::Let(live_bindings, IRExpr::Begin(side_effect_exprs))
  }

  IRExpr::Let(live_bindings, opt_body)
}

/// Optimize letrec expressions
fn optimize_letrec(bindings : Array[LetBinding], body : IRExpr) -> IRExpr {
  let opt_bindings : Array[LetBinding] = []
  for binding in bindings {
    opt_bindings.push({ name: binding.name, init: optimize_expr(binding.init) })
  }

  let opt_body = optimize_expr(body)

  if opt_bindings.length() == 0 {
    return opt_body
  }

  // Eliminate unnecessary code: remove unused bindings
  // Since letrec has mutual references, consider using it in initialization expressions.
  let used_in_body = collect_used_vars(opt_body)
  let used_in_inits : Array[String] = []
  for binding in opt_bindings {
    let init_vars = collect_used_vars(binding.init)
    for v in init_vars {
      if not(used_in_inits.contains(v)) {
        used_in_inits.push(v)
      }
    }
  }

  // Build a dependency graph and keep only bindings reachable from body
  let reachable = compute_reachable_bindings(opt_bindings, used_in_body)

  let live_bindings : Array[LetBinding] = []
  let side_effect_exprs : Array[IRExpr] = []
  let removed_indices : Array[Int] = []

  let mut idx = 0
  for binding in opt_bindings {
    if reachable.contains(binding.name) {
      live_bindings.push(binding)
    } else if has_side_effect(binding.init) {
      side_effect_exprs.push(binding.init)
      removed_indices.push(idx)
    } else {
      removed_indices.push(idx)
    }
    idx = idx + 1
  }

  if live_bindings.length() == 0 {
    if side_effect_exprs.length() == 0 {
      return adjust_var_indices_after_removal(opt_body, removed_indices)
    }
    let adjusted_body = adjust_var_indices_after_removal(opt_body, removed_indices)
    side_effect_exprs.push(adjusted_body)
    return IRExpr::Begin(side_effect_exprs)
  }

  // Adjust VarRef indices if any bindings were removed
  if removed_indices.length() > 0 {
    let adjusted_bindings : Array[LetBinding] = []
    for binding in live_bindings {
      adjusted_bindings.push({
        name: binding.name,
        init: adjust_var_indices_after_removal(binding.init, removed_indices),
      })
    }
    let adjusted_body = adjust_var_indices_after_removal(opt_body, removed_indices)

    if side_effect_exprs.length() > 0 {
      side_effect_exprs.push(adjusted_body)
      return IRExpr::Letrec(adjusted_bindings, IRExpr::Begin(side_effect_exprs))
    }

    return IRExpr::Letrec(adjusted_bindings, adjusted_body)
  }

  if side_effect_exprs.length() > 0 {
    side_effect_exprs.push(opt_body)
    return IRExpr::Letrec(live_bindings, IRExpr::Begin(side_effect_exprs))
  }

  IRExpr::Letrec(live_bindings, opt_body)
}

/// Optimize primitive operations (constant folding)
fn optimize_primop(kind : PrimOpKind, args : Array[IRExpr]) -> IRExpr {
  let opt_args = optimize_exprs(args)

  // Check if all arguments are constants
  if all_const(opt_args) {
    // Try constant folding
    match fold_primop(kind, opt_args) {
      Some(result) => return result
      None => ()
    }
  }

  // Partial optimization
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

/// Optimize and expressions
fn optimize_and(exprs : Array[IRExpr]) -> IRExpr {
  let opt_exprs = optimize_exprs(exprs)

  if opt_exprs.length() == 0 {
    return IRExpr::Const(IRConst::Bool(true))
  }

  // Constant reduction
  let filtered : Array[IRExpr] = []
  for expr in opt_exprs {
    match expr {
      // If there is #f then the whole is #f
      IRExpr::Const(IRConst::Bool(false)) =>
        return IRExpr::Const(IRConst::Bool(false))
      // #t can be removed (except at the end)
      IRExpr::Const(IRConst::Bool(true)) => {
        // #t except the last expression is removed
        ()
      }
      _ => filtered.push(expr)
    }
  }

  // If all #t
  if filtered.length() == 0 {
    // If the last expression is #t, return #t
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

/// Optimize the or expression
fn optimize_or(exprs : Array[IRExpr]) -> IRExpr {
  let opt_exprs = optimize_exprs(exprs)

  if opt_exprs.length() == 0 {
    return IRExpr::Const(IRConst::Bool(false))
  }

  // Constant reduction
  let filtered : Array[IRExpr] = []
  for expr in opt_exprs {
    match expr {
      // If #t is present, the whole is #t (same for other true values)
      IRExpr::Const(IRConst::Bool(true)) =>
        return IRExpr::Const(IRConst::Bool(true))
      // Non-#f constants are true values
      IRExpr::Const(IRConst::Bool(false)) => {
        // #f is removed
        ()
      }
      IRExpr::Const(c) =>
        // Other constants are true values, so return them immediately
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

/// Check if all arguments are constants
fn all_const(exprs : Array[IRExpr]) -> Bool {
  for expr in exprs {
    match expr {
      IRExpr::Const(_) => ()
      _ => return false
    }
  }
  true
}

/// whether the expression is 0
fn is_zero(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(IRConst::Int(0)) => true
    IRExpr::Const(IRConst::Real(r)) => r == 0.0
    _ => false
  }
}

/// whether the expression is 1
fn is_one(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(IRConst::Int(1)) => true
    IRExpr::Const(IRConst::Real(r)) => r == 1.0
    _ => false
  }
}

/// Compute reachable binding name from letrec binding dependencies
fn compute_reachable_bindings(
  bindings : Array[LetBinding],
  roots : Array[String]
) -> Array[String] {
  // Build a set of binding names
  let binding_names : Array[String] = []
  for binding in bindings {
    binding_names.push(binding.name)
  }

  // Collect dependencies of each binding
  let deps : Array[(String, Array[String])] = []
  for binding in bindings {
    let init_vars = collect_used_vars(binding.init)
    // Only what is in the binding name
    let binding_deps : Array[String] = []
    for v in init_vars {
      if binding_names.contains(v) && not(binding_deps.contains(v)) {
        binding_deps.push(v)
      }
    }
    deps.push((binding.name, binding_deps))
  }

  // Compute bindings reachable from roots (BFS)
  let reachable : Array[String] = []
  let queue : Array[String] = []

  // Adding an initial route
  for root in roots {
    if binding_names.contains(root) && not(reachable.contains(root)) {
      reachable.push(root)
      queue.push(root)
    }
  }

  // BFS
  while queue.length() > 0 {
    let current = queue.pop().unwrap()
    // Find dependencies of current
    for dep_entry in deps {
      if dep_entry.0 == current {
        for dep in dep_entry.1 {
          if not(reachable.contains(dep)) {
            reachable.push(dep)
            queue.push(dep)
          }
        }
        break
      }
    }
  }

  reachable
}

/// Collect variable names used in expressions
fn collect_used_vars(expr : IRExpr) -> Array[String] {
  let vars : Array[String] = []
  collect_used_vars_inner(expr, vars)
  vars
}

/// Internal function for collecting variable names
fn collect_used_vars_inner(expr : IRExpr, vars : Array[String]) -> Unit {
  match expr {
    IRExpr::Const(_) => ()
    IRExpr::Quote(_) => ()
    IRExpr::Var(var_ref) => {
      // Only variables in current scope (depth == 0)
      if var_ref.depth == 0 && not(vars.contains(var_ref.name)) {
        vars.push(var_ref.name)
      }
    }
    IRExpr::GlobalVar(_) => ()
    IRExpr::If(cond, then_branch, else_branch) => {
      collect_used_vars_inner(cond, vars)
      collect_used_vars_inner(then_branch, vars)
      collect_used_vars_inner(else_branch, vars)
    }
    IRExpr::Begin(exprs) => {
      for e in exprs {
        collect_used_vars_inner(e, vars)
      }
    }
    IRExpr::Lambda(info) => {
      // Check free variables in Lambda
      for free_var in info.free_vars {
        if free_var.depth == 0 && not(vars.contains(free_var.name)) {
          vars.push(free_var.name)
        }
      }
      // Lambda's body is a separate scope, so it does not recurse
    }
    IRExpr::App(func, args) => {
      collect_used_vars_inner(func, vars)
      for arg in args {
        collect_used_vars_inner(arg, vars)
      }
    }
    IRExpr::TailApp(func, args) => {
      collect_used_vars_inner(func, vars)
      for arg in args {
        collect_used_vars_inner(arg, vars)
      }
    }
    IRExpr::Let(bindings, body) => {
      // Binding initialization expression
      for binding in bindings {
        collect_used_vars_inner(binding.init, vars)
      }
      // Variables used within body (but variables bound with let do not affect the outer scope)
      let body_vars = collect_used_vars(body)
      let bound_names : Array[String] = []
      for binding in bindings {
        bound_names.push(binding.name)
      }
      for v in body_vars {
        if not(bound_names.contains(v)) && not(vars.contains(v)) {
          vars.push(v)
        }
      }
    }
    IRExpr::Letrec(bindings, body) => {
      // letrec initialization expression and body
      for binding in bindings {
        collect_used_vars_inner(binding.init, vars)
      }
      let body_vars = collect_used_vars(body)
      let bound_names : Array[String] = []
      for binding in bindings {
        bound_names.push(binding.name)
      }
      for v in body_vars {
        if not(bound_names.contains(v)) && not(vars.contains(v)) {
          vars.push(v)
        }
      }
    }
    IRExpr::Set(var_ref, value) => {
      if var_ref.depth == 0 && not(vars.contains(var_ref.name)) {
        vars.push(var_ref.name)
      }
      collect_used_vars_inner(value, vars)
    }
    IRExpr::GlobalSet(_, value) => {
      collect_used_vars_inner(value, vars)
    }
    IRExpr::PrimOp(_, args) => {
      for arg in args {
        collect_used_vars_inner(arg, vars)
      }
    }
    IRExpr::CallCC(proc) => {
      collect_used_vars_inner(proc, vars)
    }
    IRExpr::Delay(body) => {
      collect_used_vars_inner(body, vars)
    }
    IRExpr::And(exprs) => {
      for e in exprs {
        collect_used_vars_inner(e, vars)
      }
    }
    IRExpr::Or(exprs) => {
      for e in exprs {
        collect_used_vars_inner(e, vars)
      }
    }
  }
}

/// Whether the formula has side effects (simple determination)
fn has_side_effect(expr : IRExpr) -> Bool {
  match expr {
    IRExpr::Const(_) => false
    IRExpr::Var(_) => false
    IRExpr::GlobalVar(_) => false
    IRExpr::Quote(_) => false
    IRExpr::Lambda(_) => false
    // set! is a side effect
    IRExpr::Set(_, _) => true
    IRExpr::GlobalSet(_, _) => true
    // Function calls can have side effects
    IRExpr::App(_, _) => true
    IRExpr::TailApp(_, _) => true
    IRExpr::CallCC(_) => true
    // Some PrimOps have side effects
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
    // If, begin, let etc. need to look at child elements, conservatively consider them to have side effects.
    _ => true
  }
}

/// Constant folding for primitive operations
fn fold_primop(kind : PrimOpKind, args : Array[IRExpr]) -> IRExpr? {
  match kind {
    // Arithmetic operations
    PrimOpKind::Add => fold_add(args)
    PrimOpKind::Sub => fold_sub(args)
    PrimOpKind::Mul => fold_mul(args)
    PrimOpKind::Div => fold_div(args)
    PrimOpKind::Quotient => fold_quotient(args)
    PrimOpKind::Remainder => fold_remainder(args)
    PrimOpKind::Modulo => fold_modulo(args)
    PrimOpKind::Abs => fold_abs(args)

    // Relations
    PrimOpKind::NumEq => fold_num_eq(args)
    PrimOpKind::Lt => fold_lt(args)
    PrimOpKind::Gt => fold_gt(args)
    PrimOpKind::Le => fold_le(args)
    PrimOpKind::Ge => fold_ge(args)

    // Numeric predicate
    PrimOpKind::ZeroP => fold_zero_p(args)
    PrimOpKind::PositiveP => fold_positive_p(args)
    PrimOpKind::NegativeP => fold_negative_p(args)
    PrimOpKind::OddP => fold_odd_p(args)
    PrimOpKind::EvenP => fold_even_p(args)

    // Type predicate
    PrimOpKind::NullP => fold_null_p(args)
    PrimOpKind::BooleanP => fold_boolean_p(args)
    PrimOpKind::NumberP => fold_number_p(args)
    PrimOpKind::IntegerP => fold_integer_p(args)
    PrimOpKind::PairP => fold_pair_p(args)
    PrimOpKind::SymbolP => fold_symbol_p(args)
    PrimOpKind::StringP => fold_string_p(args)
    PrimOpKind::CharP => fold_char_p(args)

    // Logical connective
    PrimOpKind::Not => fold_not(args)

    // string
    PrimOpKind::StringLength => fold_string_length(args)

    // list
    PrimOpKind::Car => fold_car(args)
    PrimOpKind::Cdr => fold_cdr(args)
    PrimOpKind::Cons => fold_cons(args)
    PrimOpKind::Length => fold_length(args)

    _ => None
  }
}

/// Constant folding of addition
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

/// Constant folding for subtraction
fn fold_sub(args : Array[IRExpr]) -> IRExpr? {
  if args.length() == 0 {
    return None
  }
  if args.length() == 1 {
    // unary minus
    match args[0] {
      IRExpr::Const(IRConst::Int(n)) => return Some(IRExpr::Const(IRConst::Int(-n)))
      IRExpr::Const(IRConst::Real(r)) => return Some(IRExpr::Const(IRConst::Real(-r)))
      _ => return None
    }
  }

  // Two terms or more
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

/// Constant folding of multiplication
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

/// Constant folding of division
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
      return None  // 0 division is not folded
    }
    result = result / divisor
    i = i + 1
  }

  Some(IRExpr::Const(IRConst::Real(result)))
}

/// Constant folding for integer division
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

/// Constant folding of the remainder
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

/// constant folding of modulo
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
      // modulo always has the same sign as b
      if (r < 0 && b > 0) || (r > 0 && b < 0) {
        Some(IRExpr::Const(IRConst::Int(r + b)))
      } else {
        Some(IRExpr::Const(IRConst::Int(r)))
      }
    }
    _ => None
  }
}

/// Constant folding of absolute values
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

/// Constant folding of numerical equivalents
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

/// Constant less than folding
fn fold_lt(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a < b })
}

/// Constant folding greater than or equal to
fn fold_gt(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a > b })
}

/// Less than equal constant folding
fn fold_le(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a <= b })
}

/// Greater than equal constant folding
fn fold_ge(args : Array[IRExpr]) -> IRExpr? {
  fold_comparison(args, fn(a, b) { a >= b })
}

/// Generic constant folding for comparison operations
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

/// Extract numbers
fn extract_number(expr : IRExpr) -> Double? {
  match expr {
    IRExpr::Const(IRConst::Int(n)) => Some(n.to_double())
    IRExpr::Const(IRConst::Real(r)) => Some(r)
    _ => None
  }
}

/// Constant folding of zero?
fn fold_zero_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n == 0.0)))
    None => None
  }
}

/// Constant folding of positive?
fn fold_positive_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n > 0.0)))
    None => None
  }
}

/// Constant folding of negative?
fn fold_negative_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match extract_number(args[0]) {
    Some(n) => Some(IRExpr::Const(IRConst::Bool(n < 0.0)))
    None => None
  }
}

/// Constant folding of odd?
fn fold_odd_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(n)) => Some(IRExpr::Const(IRConst::Bool(n % 2 != 0)))
    _ => None
  }
}

/// Constant folding of even?
fn fold_even_p(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Int(n)) => Some(IRExpr::Const(IRConst::Bool(n % 2 == 0)))
    _ => None
  }
}

/// Constant folding of null?
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

/// Constant folding of boolean?
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

/// Constant folding of number?
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

/// Constant folding of integer?
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

/// Constant folding of pair?
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

/// Constant folding of symbol?
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

/// Constant folding of string?
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

/// Constant folding of char?
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

/// Constant folding of not
fn fold_not(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Bool(b)) => Some(IRExpr::Const(IRConst::Bool(not(b))))
    IRExpr::Const(_) => Some(IRExpr::Const(IRConst::Bool(false)))  // True except #f
    _ => None
  }
}

/// Constant folding of string-length
fn fold_string_length(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::String(s)) => Some(IRExpr::Const(IRConst::Int(s.length())))
    _ => None
  }
}

/// Constant folding of car
fn fold_car(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Pair(car, _)) => Some(IRExpr::Const(car))
    _ => None
  }
}

/// Constant folding of cdr
fn fold_cdr(args : Array[IRExpr]) -> IRExpr? {
  if args.length() != 1 {
    return None
  }
  match args[0] {
    IRExpr::Const(IRConst::Pair(_, cdr)) => Some(IRExpr::Const(cdr))
    _ => None
  }
}

/// Constant folding of cons
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

/// Constant folding of length
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

/// Calculate list length of IRConst
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
      _ => return None  // Not a proper list
    }
  }
  Some(len)
}

/// IRExpr equality check (simplified version)
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
    // Lambda, Let, Letrec have complex structures, so conservatively false
    _ => false
  }
}

/// IRExpr array equality check
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

/// IRConst equality checking
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

/// PrimOpKind equality check
fn primop_equal(a : PrimOpKind, b : PrimOpKind) -> Bool {
  // Enum equality may be automatically supported in MoonBit
  // Conservatively stringify and compare
  a.to_string() == b.to_string()
}

/// Adjust VarRef indices after removing bindings from a let
/// removed_indices: the original indices of bindings that were removed (sorted)
/// This function adjusts depth=0 VarRef indices to account for removed bindings
fn adjust_var_indices_after_removal(
  expr : IRExpr,
  removed_indices : Array[Int]
) -> IRExpr {
  if removed_indices.length() == 0 {
    return expr
  }
  adjust_var_indices_inner(expr, removed_indices, 0)
}

/// Inner function for adjusting VarRef indices
/// current_depth: the current depth level (0 = same frame as the let)
fn adjust_var_indices_inner(
  expr : IRExpr,
  removed_indices : Array[Int],
  current_depth : Int
) -> IRExpr {
  match expr {
    IRExpr::Const(_) => expr
    IRExpr::Quote(_) => expr
    IRExpr::GlobalVar(_) => expr

    IRExpr::Var(var_ref) => {
      if var_ref.depth == current_depth {
        // Calculate how many removed indices are less than this var's index
        let mut adjustment = 0
        for ri in removed_indices {
          if ri < var_ref.index {
            adjustment = adjustment + 1
          }
        }
        if adjustment > 0 {
          IRExpr::Var({ name: var_ref.name, depth: var_ref.depth, index: var_ref.index - adjustment })
        } else {
          expr
        }
      } else {
        expr
      }
    }

    IRExpr::Set(var_ref, value) => {
      let new_value = adjust_var_indices_inner(value, removed_indices, current_depth)
      if var_ref.depth == current_depth {
        let mut adjustment = 0
        for ri in removed_indices {
          if ri < var_ref.index {
            adjustment = adjustment + 1
          }
        }
        if adjustment > 0 {
          IRExpr::Set({ name: var_ref.name, depth: var_ref.depth, index: var_ref.index - adjustment }, new_value)
        } else {
          IRExpr::Set(var_ref, new_value)
        }
      } else {
        IRExpr::Set(var_ref, new_value)
      }
    }

    IRExpr::GlobalSet(name, value) =>
      IRExpr::GlobalSet(name, adjust_var_indices_inner(value, removed_indices, current_depth))

    IRExpr::If(cond, then_branch, else_branch) =>
      IRExpr::If(
        adjust_var_indices_inner(cond, removed_indices, current_depth),
        adjust_var_indices_inner(then_branch, removed_indices, current_depth),
        adjust_var_indices_inner(else_branch, removed_indices, current_depth),
      )

    IRExpr::Begin(exprs) => {
      let new_exprs : Array[IRExpr] = []
      for e in exprs {
        new_exprs.push(adjust_var_indices_inner(e, removed_indices, current_depth))
      }
      IRExpr::Begin(new_exprs)
    }

    IRExpr::Lambda(info) => {
      // Lambda creates a new frame, so depth increases by 1 for variables inside
      // But free_vars reference the outer scope at the original depth
      let new_free_vars : Array[VarRef] = []
      for fv in info.free_vars {
        if fv.depth == current_depth {
          let mut adjustment = 0
          for ri in removed_indices {
            if ri < fv.index {
              adjustment = adjustment + 1
            }
          }
          if adjustment > 0 {
            new_free_vars.push({ name: fv.name, depth: fv.depth, index: fv.index - adjustment })
          } else {
            new_free_vars.push(fv)
          }
        } else {
          new_free_vars.push(fv)
        }
      }
      // Body is in a new frame, so we don't adjust it (depth would be relative to lambda's frame)
      IRExpr::Lambda({
        params: info.params,
        arity: info.arity,
        rest_param: info.rest_param,
        body: info.body,
        free_vars: new_free_vars,
        boxed_params: info.boxed_params,
        boxed_locals: info.boxed_locals,
        boxed_free_vars: info.boxed_free_vars,
      })
    }

    IRExpr::App(func, args) => {
      let new_args : Array[IRExpr] = []
      for arg in args {
        new_args.push(adjust_var_indices_inner(arg, removed_indices, current_depth))
      }
      IRExpr::App(adjust_var_indices_inner(func, removed_indices, current_depth), new_args)
    }

    IRExpr::TailApp(func, args) => {
      let new_args : Array[IRExpr] = []
      for arg in args {
        new_args.push(adjust_var_indices_inner(arg, removed_indices, current_depth))
      }
      IRExpr::TailApp(adjust_var_indices_inner(func, removed_indices, current_depth), new_args)
    }

    IRExpr::Let(bindings, body) => {
      // Let in same frame: adjust both bindings and body at the same depth
      let new_bindings : Array[LetBinding] = []
      for binding in bindings {
        new_bindings.push({
          name: binding.name,
          init: adjust_var_indices_inner(binding.init, removed_indices, current_depth),
        })
      }
      IRExpr::Let(
        new_bindings,
        adjust_var_indices_inner(body, removed_indices, current_depth),
      )
    }

    IRExpr::Letrec(bindings, body) => {
      let new_bindings : Array[LetBinding] = []
      for binding in bindings {
        new_bindings.push({
          name: binding.name,
          init: adjust_var_indices_inner(binding.init, removed_indices, current_depth),
        })
      }
      IRExpr::Letrec(
        new_bindings,
        adjust_var_indices_inner(body, removed_indices, current_depth),
      )
    }

    IRExpr::PrimOp(kind, args) => {
      let new_args : Array[IRExpr] = []
      for arg in args {
        new_args.push(adjust_var_indices_inner(arg, removed_indices, current_depth))
      }
      IRExpr::PrimOp(kind, new_args)
    }

    IRExpr::CallCC(proc) =>
      IRExpr::CallCC(adjust_var_indices_inner(proc, removed_indices, current_depth))

    IRExpr::Delay(body) =>
      IRExpr::Delay(adjust_var_indices_inner(body, removed_indices, current_depth))

    IRExpr::And(exprs) => {
      let new_exprs : Array[IRExpr] = []
      for e in exprs {
        new_exprs.push(adjust_var_indices_inner(e, removed_indices, current_depth))
      }
      IRExpr::And(new_exprs)
    }

    IRExpr::Or(exprs) => {
      let new_exprs : Array[IRExpr] = []
      for e in exprs {
        new_exprs.push(adjust_var_indices_inner(e, removed_indices, current_depth))
      }
      IRExpr::Or(new_exprs)
    }
  }
}
