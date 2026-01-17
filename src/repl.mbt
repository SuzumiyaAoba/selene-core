/// REPL エントリポイントの実装。

/// 値を文字列として表示する。
fn value_to_string(value : Value) -> String {
  match value {
    Value::Nil => "()"
    Value::Bool(b) => if b { "#t" } else { "#f" }
    Value::Number(Number::Int(n)) => n.to_string()
    Value::Number(Number::Real(r)) => r.to_string()
    Value::Char(c) => "#\\" + c.to_string()
    Value::String(s) => "\"" + s + "\""
    Value::Symbol(s) => s
    Value::Pair(car, cdr) => {
      let mut result = "("
      result = result + value_to_string(car)
      let mut current = cdr
      let _ = while true {
        match current {
          Value::Nil => {
            result = result + ")"
            return result
          }
          Value::Pair(car2, cdr2) => {
            result = result + " " + value_to_string(car2)
            current = cdr2
          }
          _ => {
            result = result + " . " + value_to_string(current) + ")"
            return result
          }
        }
      } else { () }
      result
    }
    Value::Vector(items) => {
      let mut result = "#("
      let len = items.length()
      let mut i = 0
      let _ = while i < len {
        if i > 0 {
          result = result + " "
        }
        result = result + value_to_string(items[i])
        i = i + 1
      } else { () }
      result + ")"
    }
    Value::Procedure(Procedure::Native(name)) => "#<procedure:" + name + ">"
    Value::Procedure(Procedure::Closure(_, _, _)) => "#<procedure:closure>"
    Value::Procedure(Procedure::Cont(cont)) => "#<continuation:" + cont.id.to_string() + ">"
  }
}

/// REPL を起動する。
pub fn run() -> Unit {
  println("selene-core: REPL")
  println("Type expressions to evaluate. (Ctrl+D to exit)")
  println("")

  let mut env = initial_env()

  // TODO: 標準入力から読み取る（現在はサンプル式で動作確認）
  let test_inputs = [
    "(+ 1 2)",
    "(- 10 3)",
    "(* 4 5)",
    "(/ 20 4)",
    "(quotient 10 3)",
    "(remainder 10 3)",
    "(modulo 10 3)",
    "(abs (- 5))",
    "(max 1 5 3 2)",
    "(min 1 5 3 2)",
    "#t",
    "#f",
    "(cons 1 2)",
    "(cons 1 (cons 2 (cons 3 ())))",
    "(car (cons 1 2))",
    "(cdr (cons 1 2))",
    "(list 1 2 3)",
    "(length (list 1 2 3 4 5))",
    "(append (list 1 2) (list 3 4))",
    "(reverse (list 1 2 3))",
    "(list-ref (list 10 20 30) 1)",
    "(list-tail (list 1 2 3 4) 2)",
    "(null? ())",
    "(null? (cons 1 2))",
    "(pair? (cons 1 2))",
    "(number? 42)",
    "(boolean? #t)",
    "(= 1 1)",
    "(< 1 2)",
    "(> 3 2)",
    "(not #f)",
    "(not #t)",
    "(+ 1 (* 2 3))",
    "((lambda (x) (+ x 1)) 5)",
    "((lambda (x y) (* x y)) 3 4)",
    "(begin (+ 1 2) (* 3 4))",
    "(define x 10)",
    "x",
    "(set! x 20)",
    "x",
    "(define square (lambda (n) (* n n)))",
    "(square 5)",
    "(define lst (cons 1 (cons 2 (cons 3 ()))))",
    "(car lst)",
    "(car (cdr lst))",
    "(define counter 0)",
    "(set! counter (+ counter 1))",
    "counter",
    "(set! counter (+ counter 1))",
    "counter",
    "(let ((x 10) (y 20)) (+ x y))",
    "(let ((a 5)) (* a a))",
    "(let* ((x 5) (y (* x 2))) y)",
    "(let* ((x 1) (x (+ x 1)) (x (+ x 1))) x)",
    "(letrec ((x 10) (y 20)) (+ x y))",
    "(let ((x 10)) (let ((y 5)) (+ x y)))",
    "(cond (#t 42) (else 0))",
    "(cond (#f 1) (#t 2) (else 3))",
    "(cond ((= 5 5) 100) (else 0))",
    "(cond ((< 3 5) 1) ((> 3 5) 2) (else 3))",
    "(let ((x 10)) (cond ((< x 5) 1) ((< x 15) 2) (else 3)))",
    "(apply + (list 1 2 3))",
    "(apply + 1 2 (list 3 4 5))",
    "(apply max (list 1 5 3 2))",
    "(apply (lambda (x y) (+ x y)) (list 3 4))",
    "(let ((nums (list 10 20 30))) (apply + nums))",
    "(map (lambda (x) (* x 2)) (list 1 2 3 4))",
    "(map + (list 1 2 3) (list 10 20 30))",
    "(map abs (list (- 0 1) 2 (- 0 3)))",
    "(for-each (lambda (x) (* x 2)) (list 1 2 3))",
    "(let ((double (lambda (x) (* x 2)))) (map double (list 1 2 3)))",
    "(string? \"hello\")",
    "(string? 42)",
    "(char? #\\a)",
    "(char? \"a\")",
    "(string-length \"hello world\")",
    "(string-ref \"hello\" 0)",
    "(string-ref \"hello\" 4)",
    "(string-append \"hello\" \" \" \"world\")",
    "(string=? \"hello\" \"hello\")",
    "(string=? \"hello\" \"world\")",
    "(make-string 5 #\\a)",
    "(make-string 3)",
    "(substring \"hello world\" 0 5)",
    "(substring \"hello world\" 6 11)",
    "#\\a",
    "#\\space",
    "#\\newline",
    "\"hello\"",
    "\"hello\\nworld\"",
    "(vector? (vector 1 2 3))",
    "(vector? (list 1 2 3))",
    "(make-vector 5 0)",
    "(make-vector 3)",
    "(vector 1 2 3 4 5)",
    "(vector)",
    "(vector-length (vector 1 2 3 4 5))",
    "(vector-ref (vector 10 20 30) 0)",
    "(vector-ref (vector 10 20 30) 2)",
    "(vector-set! (vector 1 2 3) 1 99)",
    "(vector->list (vector 1 2 3))",
    "(list->vector (list 1 2 3))",
    "(vector->list (list->vector (list 4 5 6)))",
    "(define v (vector 1 2 3))",
    "(vector-ref v 1)",
    "(vector-length v)",
    "(floor 5)",
    "(floor (sqrt 10))",
    "(ceiling 7)",
    "(ceiling (sqrt 10))",
    "(truncate 9)",
    "(truncate (sqrt 10))",
    "(round 7)",
    "(round (sqrt 10))",
    "(sqrt 4)",
    "(sqrt 9)",
    "(sqrt 16)",
    "(expt 2 3)",
    "(expt 10 3)",
    "(expt 5 0)",
    "(expt 2 (- 0 2))",
    "(exact? 42)",
    "(exact? (sqrt 2))",
    "(inexact? 42)",
    "(inexact? (sqrt 2))",
    "(number->string 42)",
    "(number->string 0)",
    "(number->string (- 0 123))",
    "(number->string (sqrt 4))",
    "(sin 0)",
    "(cos 0)",
    "(tan 0)",
    "(asin 0)",
    "(acos 1)",
    "(atan 0)",
    "(atan 1 1)",
    "(exp 0)",
    "(exp 1)",
    "(log 1)",
    "(log (exp 2))",
    "(+ (expt (sin 1) 2) (expt (cos 1) 2))",
    "(display 42)",
    "(display \"hello\")",
    "(display (list 1 2 3))",
    "(display #t)",
    "(newline)",
    "(write 42)",
    "(write \"hello\")",
    "(write (list 1 2 3))",
    "(begin (display \"Hello\") (newline) (display \"World\"))",
    "(string->number \"42\")",
    "(string->number \"-123\")",
    "(string->number \"3.14\")",
    "(string->number \"1.5e2\")",
    "(string->number \"not a number\")",
    "(+ (string->number \"10\") (string->number \"32\"))",
    "(string->number (number->string 99))",
  ]

  for input in test_inputs {
    println("> " + input)
    match parse_one(input) {
      expr => {
        // defineの特別処理
        match expr {
          SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
            match eval(value_expr, env) {
              Ok(value) => {
                env = define_var(env, name, value)
                println("#<void>")
              }
              Err(err) => println("Error: " + err.to_string())
            }
          }
          // set!の特別処理
          SExpr::Pair(SExpr::Symbol("set!"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
            match eval(value_expr, env) {
              Ok(value) => {
                let (new_env, ok) = set_bang(env, name, value)
                if ok {
                  env = new_env
                  println("#<void>")
                } else {
                  println("Error: set!: unbound variable: " + name)
                }
              }
              Err(err) => println("Error: " + err.to_string())
            }
          }
          _ => {
            match eval(expr, env) {
              Ok(value) => println(value_to_string(value))
              Err(err) => println("Error: " + err.to_string())
            }
          }
        }
      }
    }
    println("")
  }
}

/// インタラクティブ REPL を起動する（標準入力から読み取り）
/// JS バックエンド専用
pub fn run_interactive() -> Unit {
  println("selene-core: Interactive REPL")
  println("Type expressions to evaluate. (Ctrl+D or empty line to exit)")
  println("")

  let mut env = initial_env()

  // 標準入力から読み取りループ
  // Note: MoonBit には print() がないため、プロンプト表示なし
  while true {
    let input = read_line()

    // 空行またはEOFで終了
    if input.length() == 0 {
      println("\nBye!")
      break
    }

    match parse_one(input) {
      expr => {
        // defineの特別処理
        match expr {
          SExpr::Pair(SExpr::Symbol("define"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
            match eval(value_expr, env) {
              Ok(value) => {
                env = define_var(env, name, value)
                println("#<void>")
              }
              Err(err) => println("Error: " + err.to_string())
            }
          }
          // set!の特別処理
          SExpr::Pair(SExpr::Symbol("set!"), SExpr::Pair(SExpr::Symbol(name), SExpr::Pair(value_expr, SExpr::Nil))) => {
            match eval(value_expr, env) {
              Ok(value) => {
                let (new_env, ok) = set_bang(env, name, value)
                if ok {
                  env = new_env
                  println("#<void>")
                } else {
                  println("Error: set!: unbound variable: " + name)
                }
              }
              Err(err) => println("Error: " + err.to_string())
            }
          }
          _ => {
            match eval(expr, env) {
              Ok(value) => println(value_to_string(value))
              Err(err) => println("Error: " + err.to_string())
            }
          }
        }
      }
    }
  }
}
