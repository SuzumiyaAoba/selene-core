/// 最適化パスのテスト

/// 定数畳み込み: 加算
test "optimize: constant folding - add" {
  // (+ 1 2) => 3
  let expr = IRExpr::PrimOp(PrimOpKind::Add, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 3)
    _ => fail!("Expected Const(Int(3))")
  }
}

/// 定数畳み込み: 乗算
test "optimize: constant folding - mul" {
  // (* 3 4) => 12
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(3)),
    IRExpr::Const(IRConst::Int(4)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 12)
    _ => fail!("Expected Const(Int(12))")
  }
}

/// 定数畳み込み: 減算
test "optimize: constant folding - sub" {
  // (- 10 3) => 7
  let expr = IRExpr::PrimOp(PrimOpKind::Sub, [
    IRExpr::Const(IRConst::Int(10)),
    IRExpr::Const(IRConst::Int(3)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 7)
    _ => fail!("Expected Const(Int(7))")
  }
}

/// 定数畳み込み: 比較
test "optimize: constant folding - comparison" {
  // (< 1 2) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::Lt, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected Const(Bool(true))")
  }
}

/// 定数畳み込み: 比較（偽）
test "optimize: constant folding - comparison false" {
  // (> 1 2) => #f
  let expr = IRExpr::PrimOp(PrimOpKind::Gt, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, false)
    _ => fail!("Expected Const(Bool(false))")
  }
}

/// 定数条件の簡約: if #t
test "optimize: constant if - true" {
  // (if #t 1 2) => 1
  let expr = IRExpr::If(
    IRExpr::Const(IRConst::Bool(true)),
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  )
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 1)
    _ => fail!("Expected Const(Int(1))")
  }
}

/// 定数条件の簡約: if #f
test "optimize: constant if - false" {
  // (if #f 1 2) => 2
  let expr = IRExpr::If(
    IRExpr::Const(IRConst::Bool(false)),
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  )
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 2)
    _ => fail!("Expected Const(Int(2))")
  }
}

/// and の簡約: (and #f ...) => #f
test "optimize: and with false" {
  // (and #f x) => #f
  let expr = IRExpr::And([
    IRExpr::Const(IRConst::Bool(false)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, false)
    _ => fail!("Expected Const(Bool(false))")
  }
}

/// or の簡約: (or #t ...) => #t
test "optimize: or with true" {
  // (or #t x) => #t
  let expr = IRExpr::Or([
    IRExpr::Const(IRConst::Bool(true)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected Const(Bool(true))")
  }
}

/// 部分的最適化: (+ 0 x) => x
test "optimize: add zero" {
  // (+ 0 x) => x
  let expr = IRExpr::PrimOp(PrimOpKind::Add, [
    IRExpr::Const(IRConst::Int(0)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::GlobalVar(name) => assert_eq!(name, "x")
    _ => fail!("Expected GlobalVar(x)")
  }
}

/// 部分的最適化: (* 1 x) => x
test "optimize: mul one" {
  // (* 1 x) => x
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::GlobalVar(name) => assert_eq!(name, "x")
    _ => fail!("Expected GlobalVar(x)")
  }
}

/// 部分的最適化: (* 0 x) => 0
test "optimize: mul zero" {
  // (* 0 x) => 0
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(0)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 0)
    _ => fail!("Expected Const(Int(0))")
  }
}

/// begin の最適化: 単一式
test "optimize: begin single" {
  // (begin 1) => 1
  let expr = IRExpr::Begin([IRExpr::Const(IRConst::Int(1))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 1)
    _ => fail!("Expected Const(Int(1))")
  }
}

/// ネストした定数畳み込み
test "optimize: nested constant folding" {
  // (+ (+ 1 2) (* 3 4)) => 15
  let expr = IRExpr::PrimOp(PrimOpKind::Add, [
    IRExpr::PrimOp(PrimOpKind::Add, [
      IRExpr::Const(IRConst::Int(1)),
      IRExpr::Const(IRConst::Int(2)),
    ]),
    IRExpr::PrimOp(PrimOpKind::Mul, [
      IRExpr::Const(IRConst::Int(3)),
      IRExpr::Const(IRConst::Int(4)),
    ]),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 15)
    _ => fail!("Expected Const(Int(15))")
  }
}

/// 述語の定数畳み込み: zero?
test "optimize: zero?" {
  // (zero? 0) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::ZeroP, [IRExpr::Const(IRConst::Int(0))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected Const(Bool(true))")
  }
}

/// 述語の定数畳み込み: null?
test "optimize: null?" {
  // (null? '()) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::NullP, [IRExpr::Const(IRConst::Nil)])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected Const(Bool(true))")
  }
}

/// 述語の定数畳み込み: number?
test "optimize: number?" {
  // (number? 42) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::NumberP, [IRExpr::Const(IRConst::Int(42))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq!(b, true)
    _ => fail!("Expected Const(Bool(true))")
  }
}

/// リスト操作の定数畳み込み: car
test "optimize: car" {
  // (car '(1 . 2)) => 1
  let expr = IRExpr::PrimOp(PrimOpKind::Car, [
    IRExpr::Const(IRConst::Pair(IRConst::Int(1), IRConst::Int(2))),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 1)
    _ => fail!("Expected Const(Int(1))")
  }
}

/// リスト操作の定数畳み込み: cdr
test "optimize: cdr" {
  // (cdr '(1 . 2)) => 2
  let expr = IRExpr::PrimOp(PrimOpKind::Cdr, [
    IRExpr::Const(IRConst::Pair(IRConst::Int(1), IRConst::Int(2))),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 2)
    _ => fail!("Expected Const(Int(2))")
  }
}

/// 文字列の定数畳み込み: string-length
test "optimize: string-length" {
  // (string-length "hello") => 5
  let expr = IRExpr::PrimOp(PrimOpKind::StringLength, [
    IRExpr::Const(IRConst::String("hello")),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 5)
    _ => fail!("Expected Const(Int(5))")
  }
}

/// 複合最適化: if + 定数畳み込み
test "optimize: if with constant condition from computation" {
  // (if (< 1 2) 10 20) => 10
  let expr = IRExpr::If(
    IRExpr::PrimOp(PrimOpKind::Lt, [
      IRExpr::Const(IRConst::Int(1)),
      IRExpr::Const(IRConst::Int(2)),
    ]),
    IRExpr::Const(IRConst::Int(10)),
    IRExpr::Const(IRConst::Int(20)),
  )
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq!(n, 10)
    _ => fail!("Expected Const(Int(10))")
  }
}
