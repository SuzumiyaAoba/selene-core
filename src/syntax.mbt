/// syntax-rules マクロシステムの実装

/// パターン変数にマッチした値
enum PatternValue {
  /// 単一の値
  Single(SExpr)
  /// 繰り返し（ellipsis でマッチ）
  Repeated(Array[Map[String, PatternValue]])
}

/// syntax-rules 式を評価して SyntaxRules を作成
/// (syntax-rules (literals...) (pattern template) ...)
pub fn eval_syntax_rules(args : SExpr, env : Env) -> Result[Value, EvalError] {
  // (literals...) を取得
  let (literals_sexpr, rest) = match args {
    SExpr::Pair(lits, r) => (lits, r)
    _ => return Err(EvalError::InvalidSyntax("syntax-rules: expected literals list"))
  }

  // リテラルキーワードを抽出
  let literals : Array[String] = []
  let mut current = literals_sexpr
  let _ = while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(car, cdr) => {
        match car {
          SExpr::Symbol(name) => literals.push(name)
          _ =>
            return Err(
              EvalError::InvalidSyntax("syntax-rules: literals must be identifiers"),
            )
        }
        current = cdr
      }
      _ => return Err(EvalError::InvalidSyntax("syntax-rules: invalid literals list"))
    }
  } else {
    ()
  }

  // ルールを抽出
  let rules : Array[SyntaxRule] = []
  current = rest
  let _ = while true {
    match current {
      SExpr::Nil => break
      SExpr::Pair(rule_sexpr, cdr) => {
        // 各ルールは (pattern template) の形式
        match rule_sexpr {
          SExpr::Pair(pattern, SExpr::Pair(template, SExpr::Nil)) =>
            rules.push({ pattern, template })
          _ =>
            return Err(
              EvalError::InvalidSyntax(
                "syntax-rules: rule must be (pattern template)",
              ),
            )
        }
        current = cdr
      }
      _ => return Err(EvalError::InvalidSyntax("syntax-rules: invalid rules list"))
    }
  } else {
    ()
  }

  Ok(Value::Syntax({ literals, rules, def_env: env }))
}

/// マクロを展開する
/// 式がマクロ呼び出しの場合、展開した式を返す
pub fn expand_macro(
  syntax_rules : SyntaxRules,
  expr : SExpr
) -> Result[SExpr, EvalError] {
  // 各ルールを順番に試す
  for rule in syntax_rules.rules {
    match match_pattern(rule.pattern, expr, syntax_rules.literals) {
      Some(bindings) => {
        // マッチ成功、テンプレートを展開
        return expand_template(rule.template, bindings)
      }
      None => continue
    }
  }
  Err(EvalError::InvalidSyntax("syntax-rules: no matching pattern"))
}

/// パターンマッチを行う
/// 成功した場合はバインディングを、失敗した場合は None を返す
fn match_pattern(
  pattern : SExpr,
  expr : SExpr,
  literals : Array[String]
) -> Map[String, PatternValue]? {
  let bindings : Map[String, PatternValue] = Map::new()
  if match_pattern_inner(pattern, expr, literals, bindings) {
    Some(bindings)
  } else {
    None
  }
}

/// パターンマッチの内部実装
fn match_pattern_inner(
  pattern : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  match pattern {
    // ワイルドカード（_）は何にでもマッチ
    SExpr::Symbol("_") => true
    // リテラルキーワードは完全一致が必要
    SExpr::Symbol(name) =>
      if is_literal(name, literals) {
        match expr {
          SExpr::Symbol(expr_name) => name == expr_name
          _ => false
        }
      } else {
        // パターン変数：任意の式にマッチしてバインド
        bindings.set(name, PatternValue::Single(expr))
        true
      }
    // 数値リテラル
    SExpr::Number(n) =>
      match expr {
        SExpr::Number(m) => n == m
        _ => false
      }
    // 真偽値リテラル
    SExpr::Bool(b) =>
      match expr {
        SExpr::Bool(c) => b == c
        _ => false
      }
    // 文字リテラル
    SExpr::Char(c) =>
      match expr {
        SExpr::Char(d) => c == d
        _ => false
      }
    // 文字列リテラル
    SExpr::String(s) =>
      match expr {
        SExpr::String(t) => s == t
        _ => false
      }
    // 空リスト
    SExpr::Nil =>
      match expr {
        SExpr::Nil => true
        _ => false
      }
    // リストパターン（ellipsis 対応）
    SExpr::Pair(pcar, pcdr) => match_list_pattern(pcar, pcdr, expr, literals, bindings)
    // その他
    _ => false
  }
}

/// リストパターンのマッチ（ellipsis 対応）
fn match_list_pattern(
  pcar : SExpr,
  pcdr : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  // expr がリストでなければマッチしない
  match expr {
    SExpr::Pair(ecar, ecdr) => {
      // pcdr が (... ...) の形式かチェック
      match pcdr {
        SExpr::Pair(SExpr::Symbol("..."), rest) => {
          // ellipsis パターン：pcar を0回以上繰り返しマッチ
          match_ellipsis_pattern(pcar, rest, expr, literals, bindings)
        }
        _ => {
          // 通常のリストマッチ
          if match_pattern_inner(pcar, ecar, literals, bindings) {
            match_pattern_inner(pcdr, ecdr, literals, bindings)
          } else {
            false
          }
        }
      }
    }
    SExpr::Nil =>
      // 式が空リストの場合
      match pcdr {
        SExpr::Pair(SExpr::Symbol("..."), rest) => {
          // ellipsis の場合、0回のマッチとして扱う
          // pcar のパターン変数を空の繰り返しとしてバインド
          let pattern_vars = collect_pattern_variables(pcar, literals)
          for name in pattern_vars {
            bindings.set(name, PatternValue::Repeated([]))
          }
          // 残りのパターンとマッチ
          match_pattern_inner(rest, SExpr::Nil, literals, bindings)
        }
        _ => false
      }
    _ => false
  }
}

/// ellipsis パターンのマッチ
fn match_ellipsis_pattern(
  elem_pattern : SExpr,
  rest_pattern : SExpr,
  expr : SExpr,
  literals : Array[String],
  bindings : Map[String, PatternValue]
) -> Bool {
  // パターン変数を収集
  let pattern_vars = collect_pattern_variables(elem_pattern, literals)

  // 繰り返しバインディングを格納
  let repeated : Array[Map[String, PatternValue]] = []

  // 式を走査して要素をマッチ
  let mut current = expr
  let _ = while true {
    match current {
      SExpr::Pair(ecar, ecdr) => {
        // rest_pattern が空でない場合、後ろからマッチする必要がある
        // 簡略化のため、まず貪欲にマッチを試みる
        let elem_bindings : Map[String, PatternValue] = Map::new()
        if match_pattern_inner(elem_pattern, ecar, literals, elem_bindings) {
          repeated.push(elem_bindings)
          current = ecdr
        } else {
          break
        }
      }
      SExpr::Nil => break
      _ => break
    }
  } else {
    ()
  }

  // 繰り返しバインディングをまとめる
  for name in pattern_vars {
    bindings.set(name, PatternValue::Repeated(repeated))
  }

  // 残りのパターンとマッチ
  match_pattern_inner(rest_pattern, current, literals, bindings)
}

/// パターン内のパターン変数を収集
fn collect_pattern_variables(pattern : SExpr, literals : Array[String]) -> Array[String] {
  let vars : Array[String] = []
  collect_pattern_variables_inner(pattern, literals, vars)
  vars
}

fn collect_pattern_variables_inner(
  pattern : SExpr,
  literals : Array[String],
  vars : Array[String]
) -> Unit {
  match pattern {
    SExpr::Symbol("_") => () // ワイルドカードは無視
    SExpr::Symbol("...") => () // ellipsis は無視
    SExpr::Symbol(name) =>
      if not(is_literal(name, literals)) {
        // 既に追加されていなければ追加
        if not(vars.contains(name)) {
          vars.push(name)
        }
      }
    SExpr::Pair(car, cdr) => {
      collect_pattern_variables_inner(car, literals, vars)
      collect_pattern_variables_inner(cdr, literals, vars)
    }
    _ => ()
  }
}

/// 識別子がリテラルキーワードかどうか
fn is_literal(name : String, literals : Array[String]) -> Bool {
  literals.contains(name)
}

/// テンプレートを展開
fn expand_template(
  template : SExpr,
  bindings : Map[String, PatternValue]
) -> Result[SExpr, EvalError] {
  expand_template_inner(template, bindings, 0)
}

/// テンプレート展開の内部実装
fn expand_template_inner(
  template : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[SExpr, EvalError] {
  match template {
    // シンボルはパターン変数の場合置換
    SExpr::Symbol(name) =>
      match bindings.get(name) {
        Some(PatternValue::Single(value)) => Ok(value)
        Some(PatternValue::Repeated(_)) =>
          if depth > 0 {
            // 繰り返しコンテキスト内では現在のインデックスの値を使用
            // これは expand_repeated で処理される
            Ok(template)
          } else {
            Err(EvalError::InvalidSyntax("syntax-rules: repeated pattern variable outside of ellipsis"))
          }
        None =>
          // パターン変数でないシンボルはそのまま
          Ok(template)
      }
    // リストの場合、ellipsis を処理
    SExpr::Pair(car, cdr) => expand_list_template(car, cdr, bindings, depth)
    // その他はそのまま
    _ => Ok(template)
  }
}

/// リストテンプレートの展開（ellipsis 対応）
fn expand_list_template(
  car : SExpr,
  cdr : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[SExpr, EvalError] {
  // cdr が (... ...) の形式かチェック
  match cdr {
    SExpr::Pair(SExpr::Symbol("..."), rest) => {
      // ellipsis 展開
      let expanded_elements = match expand_repeated(car, bindings, depth + 1) {
        Ok(elems) => elems
        Err(e) => return Err(e)
      }
      // 残りのテンプレートを展開
      let expanded_rest = match expand_template_inner(rest, bindings, depth) {
        Ok(r) => r
        Err(e) => return Err(e)
      }
      // 展開された要素をリストに結合
      let mut result = expanded_rest
      let mut i = expanded_elements.length() - 1
      let _ = while i >= 0 {
        result = SExpr::Pair(expanded_elements[i], result)
        i = i - 1
      } else {
        ()
      }
      Ok(result)
    }
    _ => {
      // 通常のリスト展開
      let expanded_car = match expand_template_inner(car, bindings, depth) {
        Ok(c) => c
        Err(e) => return Err(e)
      }
      let expanded_cdr = match expand_template_inner(cdr, bindings, depth) {
        Ok(c) => c
        Err(e) => return Err(e)
      }
      Ok(SExpr::Pair(expanded_car, expanded_cdr))
    }
  }
}

/// 繰り返しテンプレートを展開
fn expand_repeated(
  template : SExpr,
  bindings : Map[String, PatternValue],
  depth : Int
) -> Result[Array[SExpr], EvalError] {
  // テンプレート内の繰り返しパターン変数を見つける
  let repeated_vars = find_repeated_variables(template, bindings)
  if repeated_vars.is_empty() {
    return Err(EvalError::InvalidSyntax("syntax-rules: no repeated variables in ellipsis template"))
  }

  // 繰り返し回数を決定（最初の繰り返し変数の長さを使用）
  let first_var = repeated_vars[0]
  let count = match bindings.get(first_var) {
    Some(PatternValue::Repeated(values)) => values.length()
    _ => return Err(EvalError::InvalidSyntax("syntax-rules: expected repeated binding"))
  }

  // 各反復で展開
  let results : Array[SExpr] = []
  let mut i = 0
  let _ = while i < count {
    // この反復用のバインディングを作成
    let iter_bindings : Map[String, PatternValue] = Map::new()

    // 既存のバインディングを処理
    bindings.each(
      fn(name, value) {
        match value {
          PatternValue::Single(v) => iter_bindings.set(name, PatternValue::Single(v))
          PatternValue::Repeated(values) =>
            if i < values.length() {
              // この反復のバインディングをマージ
              let iter_bind = values[i]
              iter_bind.each(
                fn(inner_name, inner_value) {
                  iter_bindings.set(inner_name, inner_value)
                },
              )
            }
        }
      },
    )

    let expanded = match expand_template_inner(template, iter_bindings, depth) {
      Ok(e) => e
      Err(e) => return Err(e)
    }
    results.push(expanded)
    i = i + 1
  } else {
    ()
  }

  Ok(results)
}

/// テンプレート内の繰り返しパターン変数を見つける
fn find_repeated_variables(
  template : SExpr,
  bindings : Map[String, PatternValue]
) -> Array[String] {
  let vars : Array[String] = []
  find_repeated_variables_inner(template, bindings, vars)
  vars
}

fn find_repeated_variables_inner(
  template : SExpr,
  bindings : Map[String, PatternValue],
  vars : Array[String]
) -> Unit {
  match template {
    SExpr::Symbol(name) =>
      match bindings.get(name) {
        Some(PatternValue::Repeated(_)) =>
          if not(vars.contains(name)) {
            vars.push(name)
          }
        _ => ()
      }
    SExpr::Pair(car, cdr) => {
      // ellipsis の後はスキップ
      match cdr {
        SExpr::Pair(SExpr::Symbol("..."), _) => ()
        _ => {
          find_repeated_variables_inner(car, bindings, vars)
          find_repeated_variables_inner(cdr, bindings, vars)
        }
      }
    }
    _ => ()
  }
}
