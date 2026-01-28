/// Testing optimization passes

/// Constant folding: addition
test "optimize: constant folding - add" {
  // (+ 1 2) => 3
  let expr = IRExpr::PrimOp(PrimOpKind::Add, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 3)
    _ => fail("Expected Const(Int(3))")
  }
}

/// Constant folding: Multiplication
test "optimize: constant folding - mul" {
  // (* 3 4) => 12
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(3)),
    IRExpr::Const(IRConst::Int(4)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 12)
    _ => fail("Expected Const(Int(12))")
  }
}

/// Constant folding: subtraction
test "optimize: constant folding - sub" {
  // (- 10 3) => 7
  let expr = IRExpr::PrimOp(PrimOpKind::Sub, [
    IRExpr::Const(IRConst::Int(10)),
    IRExpr::Const(IRConst::Int(3)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 7)
    _ => fail("Expected Const(Int(7))")
  }
}

/// Constant folding: comparison
test "optimize: constant folding - comparison" {
  // (< 1 2) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::Lt, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected Const(Bool(true))")
  }
}

/// Constant folding: comparison (false)
test "optimize: constant folding - comparison false" {
  // (> 1 2) => #f
  let expr = IRExpr::PrimOp(PrimOpKind::Gt, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, false)
    _ => fail("Expected Const(Bool(false))")
  }
}

/// Constant condition reduction: if #t
test "optimize: constant if - true" {
  // (if #t 1 2) => 1
  let expr = IRExpr::If(
    IRExpr::Const(IRConst::Bool(true)),
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  )
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 1)
    _ => fail("Expected Const(Int(1))")
  }
}

/// Constant condition reduction: if #f
test "optimize: constant if - false" {
  // (if #f 1 2) => 2
  let expr = IRExpr::If(
    IRExpr::Const(IRConst::Bool(false)),
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::Const(IRConst::Int(2)),
  )
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 2)
    _ => fail("Expected Const(Int(2))")
  }
}

/// and reduction: (and #f ...) => #f
test "optimize: and with false" {
  // (and #f x) => #f
  let expr = IRExpr::And([
    IRExpr::Const(IRConst::Bool(false)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, false)
    _ => fail("Expected Const(Bool(false))")
  }
}

/// or reduction: (or #t ...) => #t
test "optimize: or with true" {
  // (or #t x) => #t
  let expr = IRExpr::Or([
    IRExpr::Const(IRConst::Bool(true)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected Const(Bool(true))")
  }
}

/// Partial optimization: (+ 0 x) => x
test "optimize: add zero" {
  // (+ 0 x) => x
  let expr = IRExpr::PrimOp(PrimOpKind::Add, [
    IRExpr::Const(IRConst::Int(0)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::GlobalVar(name) => assert_eq(name, "x")
    _ => fail("Expected GlobalVar(x)")
  }
}

/// Partial optimization: (* 1 x) => x
test "optimize: mul one" {
  // (* 1 x) => x
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(1)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::GlobalVar(name) => assert_eq(name, "x")
    _ => fail("Expected GlobalVar(x)")
  }
}

/// Partial optimization: (* 0 x) => 0
test "optimize: mul zero" {
  // (* 0 x) => 0
  let expr = IRExpr::PrimOp(PrimOpKind::Mul, [
    IRExpr::Const(IRConst::Int(0)),
    IRExpr::GlobalVar("x"),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 0)
    _ => fail("Expected Const(Int(0))")
  }
}

/// begin optimization: single expression
test "optimize: begin single" {
  // (begin 1) => 1
  let expr = IRExpr::Begin([IRExpr::Const(IRConst::Int(1))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 1)
    _ => fail("Expected Const(Int(1))")
  }
}

/// nested constant folding
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
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 15)
    _ => fail("Expected Const(Int(15))")
  }
}

/// Constant folding of predicate: zero?
test "optimize: zero?" {
  // (zero? 0) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::ZeroP, [IRExpr::Const(IRConst::Int(0))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected Const(Bool(true))")
  }
}

/// Constant folding of predicate: null?
test "optimize: null?" {
  // (null? '()) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::NullP, [IRExpr::Const(IRConst::Nil)])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected Const(Bool(true))")
  }
}

/// Constant folding of predicate: number?
test "optimize: number?" {
  // (number? 42) => #t
  let expr = IRExpr::PrimOp(PrimOpKind::NumberP, [IRExpr::Const(IRConst::Int(42))])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Bool(b)) => assert_eq(b, true)
    _ => fail("Expected Const(Bool(true))")
  }
}

/// Constant folding for list operations: car
test "optimize: car" {
  // (car '(1 . 2)) => 1
  let expr = IRExpr::PrimOp(PrimOpKind::Car, [
    IRExpr::Const(IRConst::Pair(IRConst::Int(1), IRConst::Int(2))),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 1)
    _ => fail("Expected Const(Int(1))")
  }
}

/// Constant folding for list operations: cdr
test "optimize: cdr" {
  // (cdr '(1 . 2)) => 2
  let expr = IRExpr::PrimOp(PrimOpKind::Cdr, [
    IRExpr::Const(IRConst::Pair(IRConst::Int(1), IRConst::Int(2))),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 2)
    _ => fail("Expected Const(Int(2))")
  }
}

/// Constant folding of strings: string-length
test "optimize: string-length" {
  // (string-length "hello") => 5
  let expr = IRExpr::PrimOp(PrimOpKind::StringLength, [
    IRExpr::Const(IRConst::String("hello")),
  ])
  let result = optimize(expr)
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 5)
    _ => fail("Expected Const(Int(5))")
  }
}

/// Complex optimization: if + constant folding
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
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 10)
    _ => fail("Expected Const(Int(10))")
  }
}

/// Eliminate unnecessary code: unused let bindings
test "optimize: dead code elimination - unused let binding" {
  // (let ((x 1) (y 2)) y) => leave only y=2
  let expr = IRExpr::Let(
    [
      { name: "x", init: IRExpr::Const(IRConst::Int(1)) },
      { name: "y", init: IRExpr::Const(IRConst::Int(2)) },
    ],
    IRExpr::Var({ name: "y", depth: 0, index: 1 })
  )
  let result = optimize(expr)
  // x is unused and is removed
  match result {
    IRExpr::Let(bindings, _body) => {
      // x should have been removed
      assert_eq(bindings.length(), 1)
      assert_eq(bindings[0].name, "y")
    }
    _ => fail("Expected Let with one binding")
  }
}

/// Redundant code removal: all bindings are unused
test "optimize: dead code elimination - all bindings unused" {
  // (let ((x 1) (y 2)) 3) => 3
  let expr = IRExpr::Let(
    [
      { name: "x", init: IRExpr::Const(IRConst::Int(1)) },
      { name: "y", init: IRExpr::Const(IRConst::Int(2)) },
    ],
    IRExpr::Const(IRConst::Int(3))
  )
  let result = optimize(expr)
  // all bindings are removed
  match result {
    IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 3)
    _ => fail("Expected Const(Int(3))")
  }
}

/// Eliminate unnecessary code: keep unused bindings with side effects
test "optimize: dead code elimination - keep side effects" {
  // (let ((x (display 1))) 2) => (begin (display 1) 2)
  let expr = IRExpr::Let(
    [
      { name: "x", init: IRExpr::PrimOp(PrimOpKind::Display, [IRExpr::Const(IRConst::Int(1))]) },
    ],
    IRExpr::Const(IRConst::Int(2))
  )
  let result = optimize(expr)
  // Since display has side effects, it is executed with begin.
  match result {
    IRExpr::Begin(_exprs) => ()  // OK
    _ => fail("Expected Begin (side effect preserved)")
  }
}

/// Eliminate unnecessary code: Used variables are retained
test "optimize: dead code elimination - used binding kept" {
  // (let ((x 1)) x) => (let ((x 1)) x)
  let expr = IRExpr::Let(
    [
      { name: "x", init: IRExpr::Const(IRConst::Int(1)) },
    ],
    IRExpr::Var({ name: "x", depth: 0, index: 0 })
  )
  let result = optimize(expr)
  match result {
    IRExpr::Let(bindings, _body) => {
      assert_eq(bindings.length(), 1)
      assert_eq(bindings[0].name, "x")
    }
    _ => fail("Expected Let with x binding")
  }
}

/// Inlining: a simple lambda call
test "optimize: inline expansion - simple lambda" {
  // ((lambda (x) (+ x 1)) 5) => (let ((x 5)) (+ x 1))
  let expr = IRExpr::App(
    IRExpr::Lambda({
      params: ["x"],
      arity: 1,
      body: IRExpr::PrimOp(PrimOpKind::Add, [
        IRExpr::Var({ name: "x", depth: 0, index: 0 }),
        IRExpr::Const(IRConst::Int(1)),
      ]),
      free_vars: [],
      boxed_params: [],
      boxed_locals: [],
    }),
    [IRExpr::Const(IRConst::Int(5))]
  )
  let result = optimize(expr)
  // Inlined and converted to Let
  match result {
    IRExpr::Let(bindings, _body) => {
      assert_eq(bindings.length(), 1)
      assert_eq(bindings[0].name, "x")
      match bindings[0].init {
        IRExpr::Const(IRConst::Int(n)) => assert_eq(n, 5)
        _ => fail("Expected binding init to be Const(5)")
      }
    }
    _ => fail("Expected Let")
  }
}

/// Inlining: multi-argument lambda
test "optimize: inline expansion - multiple args" {
  // ((lambda (x y) (+ x y)) 3 4) => (let ((x 3) (y 4)) (+ x y))
  let expr = IRExpr::App(
    IRExpr::Lambda({
      params: ["x", "y"],
      arity: 2,
      body: IRExpr::PrimOp(PrimOpKind::Add, [
        IRExpr::Var({ name: "x", depth: 0, index: 0 }),
        IRExpr::Var({ name: "y", depth: 0, index: 1 }),
      ]),
      free_vars: [],
      boxed_params: [],
      boxed_locals: [],
    }),
    [IRExpr::Const(IRConst::Int(3)), IRExpr::Const(IRConst::Int(4))]
  )
  let result = optimize(expr)
  match result {
    IRExpr::Let(bindings, _body) => {
      assert_eq(bindings.length(), 2)
      assert_eq(bindings[0].name, "x")
      assert_eq(bindings[1].name, "y")
    }
    _ => fail("Expected Let with 2 bindings")
  }
}

/// Inlining: Inline even at the end of a call
test "optimize: inline expansion - tail call" {
  // (tail-app (lambda (x) x) 42) => (let ((x 42)) x)
  let expr = IRExpr::TailApp(
    IRExpr::Lambda({
      params: ["x"],
      arity: 1,
      body: IRExpr::Var({ name: "x", depth: 0, index: 0 }),
      free_vars: [],
      boxed_params: [],
      boxed_locals: [],
    }),
    [IRExpr::Const(IRConst::Int(42))]
  )
  let result = optimize(expr)
  match result {
    IRExpr::Let(bindings, _body) => {
      assert_eq(bindings.length(), 1)
      assert_eq(bindings[0].name, "x")
    }
    _ => fail("Expected Let")
  }
}
