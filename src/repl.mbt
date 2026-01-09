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
    "#t",
    "#f",
    "(cons 1 2)",
    "(cons 1 (cons 2 (cons 3 ())))",
    "(car (cons 1 2))",
    "(cdr (cons 1 2))",
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
    "(define lst (cons 1 (cons 2 (cons 3 ()))))",
    "(car lst)",
    "(car (cdr lst))",
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
