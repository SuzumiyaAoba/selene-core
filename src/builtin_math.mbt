/// 数学関数組み込み関数
///
/// Scheme の数学関数を実装する。

/// 組み込み関数: floor
/// (floor x) - x 以下の最大の整数を返す
fn builtin_floor(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("floor: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Int(r.floor().to_int())))
    _ => Err(EvalError::TypeError("floor: argument must be a number"))
  }
}

/// 組み込み関数: ceiling
/// (ceiling x) - x 以上の最小の整数を返す
fn builtin_ceiling(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("ceiling: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Int(r.ceil().to_int())))
    _ => Err(EvalError::TypeError("ceiling: argument must be a number"))
  }
}

/// 組み込み関数: truncate
/// (truncate x) - x を 0 に向かって丸める
fn builtin_truncate(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("truncate: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Int(r.to_int())))
    _ => Err(EvalError::TypeError("truncate: argument must be a number"))
  }
}

/// 組み込み関数: round
/// (round x) - x を最も近い整数に丸める（.5 の場合は偶数に丸める）
fn builtin_round(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("round: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => {
      // 四捨五入（.5の場合は最も近い偶数に丸める）
      let rounded = r.round()
      Ok(Value::Number(Number::Int(rounded.to_int())))
    }
    _ => Err(EvalError::TypeError("round: argument must be a number"))
  }
}

/// 組み込み関数: sqrt
/// (sqrt x) - x の平方根を返す
fn builtin_sqrt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("sqrt: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = n.to_double().sqrt()
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Real(r.sqrt())))
    _ => Err(EvalError::TypeError("sqrt: argument must be a number"))
  }
}

/// 組み込み関数: expt
/// (expt x y) - x の y 乗を返す
fn builtin_expt(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("expt: requires exactly 2 arguments"))
  }
  let base = match expect_number(args[0]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let exp = match expect_number(args[1]) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  match (base, exp) {
    (Number::Int(b), Number::Int(e)) => {
      if e >= 0 {
        // 整数のべき乗（非負の指数）
        let result = b.to_double().pow(e.to_double())
        if result.floor() == result && result.to_int() != 0 {
          Ok(Value::Number(Number::Int(result.to_int())))
        } else {
          Ok(Value::Number(Number::Real(result)))
        }
      } else {
        // 負の指数は実数になる
        Ok(Value::Number(Number::Real(b.to_double().pow(e.to_double()))))
      }
    }
    _ => {
      let b_real = number_to_double(base)
      let e_real = number_to_double(exp)
      Ok(Value::Number(Number::Real(b_real.pow(e_real))))
    }
  }
}

/// 組み込み関数: exact?
/// (exact? z) - z が正確な数（整数または有理数）かどうかを判定
fn builtin_exact_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("exact?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Rational(_, _)) => Ok(Value::Bool(true))
    Value::Number(Number::Real(_)) => Ok(Value::Bool(false))
    Value::Number(Number::Complex(_, _)) => Ok(Value::Bool(false))
    _ => Err(EvalError::TypeError("exact?: argument must be a number"))
  }
}

/// 組み込み関数: inexact?
/// (inexact? z) - z が不正確な数（実数または複素数）かどうかを判定
fn builtin_inexact_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("inexact?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(false))
    Value::Number(Number::Rational(_, _)) => Ok(Value::Bool(false))
    Value::Number(Number::Real(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Complex(_, _)) => Ok(Value::Bool(true))
    _ => Err(EvalError::TypeError("inexact?: argument must be a number"))
  }
}

/// 組み込み関数: sin
/// (sin x) - x のサイン（正弦）を返す（ラジアン）
fn builtin_sin(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("sin: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.sin(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.sin(r))))
    _ => Err(EvalError::TypeError("sin: argument must be a number"))
  }
}

/// 組み込み関数: cos
/// (cos x) - x のコサイン（余弦）を返す（ラジアン）
fn builtin_cos(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("cos: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.cos(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.cos(r))))
    _ => Err(EvalError::TypeError("cos: argument must be a number"))
  }
}

/// 組み込み関数: tan
/// (tan x) - x のタンジェント（正接）を返す（ラジアン）
fn builtin_tan(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("tan: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.tan(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.tan(r))))
    _ => Err(EvalError::TypeError("tan: argument must be a number"))
  }
}

/// 組み込み関数: asin
/// (asin x) - x のアークサイン（逆正弦）を返す（ラジアン）
fn builtin_asin(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("asin: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.asin(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.asin(r))))
    _ => Err(EvalError::TypeError("asin: argument must be a number"))
  }
}

/// 組み込み関数: acos
/// (acos x) - x のアークコサイン（逆余弦）を返す（ラジアン）
fn builtin_acos(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("acos: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.acos(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.acos(r))))
    _ => Err(EvalError::TypeError("acos: argument must be a number"))
  }
}

/// 組み込み関数: atan
/// (atan x) または (atan y x) - アークタンジェント（逆正接）を返す（ラジアン）
/// 1引数の場合: atan(x)
/// 2引数の場合: atan2(y, x)
fn builtin_atan(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() == 1 {
    match args[0] {
      Value::Number(Number::Int(n)) => {
        let r = @math.atan(n.to_double())
        Ok(Value::Number(Number::Real(r)))
      }
      Value::Number(Number::Real(r)) =>
        Ok(Value::Number(Number::Real(@math.atan(r))))
      _ => Err(EvalError::TypeError("atan: argument must be a number"))
    }
  } else if args.length() == 2 {
    let y = match expect_number(args[0]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    let x = match expect_number(args[1]) {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    let y_real = number_to_double(y)
    let x_real = number_to_double(x)
    Ok(Value::Number(Number::Real(@math.atan2(y_real, x_real))))
  } else {
    Err(EvalError::ArityError("atan: requires 1 or 2 arguments"))
  }
}

/// 組み込み関数: exp
/// (exp x) - e の x 乗を返す
fn builtin_exp(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("exp: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.exp(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.exp(r))))
    _ => Err(EvalError::TypeError("exp: argument must be a number"))
  }
}

/// 組み込み関数: log
/// (log x) - x の自然対数を返す
fn builtin_log(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("log: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => {
      let r = @math.ln(n.to_double())
      Ok(Value::Number(Number::Real(r)))
    }
    Value::Number(Number::Real(r)) =>
      Ok(Value::Number(Number::Real(@math.ln(r))))
    _ => Err(EvalError::TypeError("log: argument must be a number"))
  }
}

// =============================================================================
// 複素数関連の組み込み関数
// =============================================================================

/// 組み込み関数: make-rectangular
/// (make-rectangular real imag) - 実部と虚部から複素数を作成
fn builtin_make_rectangular(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("make-rectangular: requires exactly 2 arguments"))
  }
  let real = match args[0] {
    Value::Number(n) => number_to_double(n)
    _ => return Err(EvalError::TypeError("make-rectangular: arguments must be numbers"))
  }
  let imag = match args[1] {
    Value::Number(n) => number_to_double(n)
    _ => return Err(EvalError::TypeError("make-rectangular: arguments must be numbers"))
  }
  Ok(Value::Number(normalize_complex(real, imag)))
}

/// 組み込み関数: make-polar
/// (make-polar magnitude angle) - 極形式から複素数を作成
fn builtin_make_polar(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(EvalError::ArityError("make-polar: requires exactly 2 arguments"))
  }
  let mag = match args[0] {
    Value::Number(n) => number_to_double(n)
    _ => return Err(EvalError::TypeError("make-polar: arguments must be numbers"))
  }
  let angle = match args[1] {
    Value::Number(n) => number_to_double(n)
    _ => return Err(EvalError::TypeError("make-polar: arguments must be numbers"))
  }
  let real = mag * @math.cos(angle)
  let imag = mag * @math.sin(angle)
  Ok(Value::Number(normalize_complex(real, imag)))
}

/// 組み込み関数: real-part
/// (real-part z) - 複素数の実部を取得
fn builtin_real_part(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("real-part: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(r, _)) => Ok(Value::Number(Number::Real(r)))
    Value::Number(n) => Ok(Value::Number(Number::Real(number_to_double(n))))
    _ => Err(EvalError::TypeError("real-part: argument must be a number"))
  }
}

/// 組み込み関数: imag-part
/// (imag-part z) - 複素数の虚部を取得
fn builtin_imag_part(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("imag-part: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(_, i)) => Ok(Value::Number(Number::Real(i)))
    Value::Number(_) => Ok(Value::Number(Number::Real(0.0))) // 実数の虚部は0
    _ => Err(EvalError::TypeError("imag-part: argument must be a number"))
  }
}

/// 組み込み関数: magnitude
/// (magnitude z) - 複素数の絶対値を取得
fn builtin_magnitude(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("magnitude: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(r, i)) => {
      let mag = (r * r + i * i).sqrt()
      Ok(Value::Number(Number::Real(mag)))
    }
    Value::Number(n) => {
      let v = number_to_double(n)
      Ok(Value::Number(Number::Real(if v < 0.0 { -v } else { v })))
    }
    _ => Err(EvalError::TypeError("magnitude: argument must be a number"))
  }
}

/// 組み込み関数: angle
/// (angle z) - 複素数の偏角を取得
fn builtin_angle(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("angle: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(r, i)) => {
      Ok(Value::Number(Number::Real(@math.atan2(i, r))))
    }
    Value::Number(n) => {
      // 実数の偏角は 0 または π
      let v = number_to_double(n)
      if v >= 0.0 {
        Ok(Value::Number(Number::Real(0.0)))
      } else {
        Ok(Value::Number(Number::Real(@math.PI)))
      }
    }
    _ => Err(EvalError::TypeError("angle: argument must be a number"))
  }
}

/// 組み込み関数: complex?
/// (complex? obj) - obj が複素数かどうかを判定（すべての数は複素数）
fn builtin_complex_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("complex?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true)) // すべての数は複素数のサブセット
    _ => Ok(Value::Bool(false))
  }
}

// =============================================================================
// 有理数関連の組み込み関数
// =============================================================================

/// 組み込み関数: numerator
/// (numerator q) - 有理数の分子を取得
fn builtin_numerator(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("numerator: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Rational(num, _)) => Ok(Value::Number(Number::Int(num)))
    _ => Err(EvalError::TypeError("numerator: argument must be an integer or rational"))
  }
}

/// 組み込み関数: denominator
/// (denominator q) - 有理数の分母を取得
fn builtin_denominator(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("denominator: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Number(Number::Int(1)))
    Value::Number(Number::Rational(_, den)) => Ok(Value::Number(Number::Int(den)))
    _ => Err(EvalError::TypeError("denominator: argument must be an integer or rational"))
  }
}

/// 組み込み関数: rational?
/// (rational? obj) - obj が有理数かどうかを判定
fn builtin_rational_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("rational?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Rational(_, _)) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}
