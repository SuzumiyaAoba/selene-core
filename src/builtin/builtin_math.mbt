/// Mathematical Functions Embedded Functions
///
/// Implement the mathematical functions of Scheme.

/// Built-in function: floor
/// (floor x) - Returns the largest integer less than or equal to x
pub fn builtin_floor(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: ceiling
/// (ceiling x) - Returns the smallest integer greater than or equal to x
pub fn builtin_ceiling(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: truncate
/// (truncate x) Round -x towards 0
pub fn builtin_truncate(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("truncate: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => Ok(Value::Number(Number::Int(r.to_int())))
    _ => Err(EvalError::TypeError("truncate: argument must be a number"))
  }
}

/// Built-in functions: round
/// (round x) - Round x to the nearest integer (even for 5)
pub fn builtin_round(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("round: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Real(r)) => {
      // Round (round to nearest even in case of 5)
      let rounded = r.round()
      Ok(Value::Number(Number::Int(rounded.to_int())))
    }
    _ => Err(EvalError::TypeError("round: argument must be a number"))
  }
}

/// Built-in function: sqrt
/// (sqrt x) Returns the square root of -x
pub fn builtin_sqrt(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: expt
/// (expt x y) Returns the y-squared of -x
pub fn builtin_expt(args : Array[Value]) -> Result[Value, EvalError] {
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
        // Power of integers (non-negative exponent)
        let result = b.to_double().pow(e.to_double())
        if result.floor() == result && result.to_int() != 0 {
          Ok(Value::Number(Number::Int(result.to_int())))
        } else {
          Ok(Value::Number(Number::Real(result)))
        }
      } else {
        // Negative exponents become real numbers
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

/// Built-in functions: exact?
/// (exact? z) - Determine if z is an exact number (integer or rational)
pub fn builtin_exact_p(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: inexact?
/// (inexact? z) - Determine if z is an incorrect number (real or complex)
pub fn builtin_inexact_p(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: sin
/// (sin x) - Returns the sign (sine) of x (radian)
pub fn builtin_sin(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: cos
/// (cos x) - Returns the cosine of x (radian)
pub fn builtin_cos(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: tan
/// (tan x) Returns the tangent of -x (radian)
pub fn builtin_tan(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: asin
/// (asin x) - Returns the arcsine (inverse sine) of x (radian)
pub fn builtin_asin(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: acos
/// (acos x) - Returns the arc cosine of x (inverse cosine) (radian)
pub fn builtin_acos(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: atan
/// (atan x) or (atan y x) - returns arc tangent (inverse tangent) (radian)
/// For one argument: atan (x)
/// For two arguments: atan2 (y, x)
pub fn builtin_atan(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: exp
/// (exp x) Returns the x power of -e
pub fn builtin_exp(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: log
/// (log x) - Returns the natural logarithm of x
pub fn builtin_log(args : Array[Value]) -> Result[Value, EvalError] {
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
// Built-in functions related to complex numbers
// =============================================================================

/// Built-in function: make-rectangular
/// (make-rectangular real imag) - create complex numbers from real and imaginary parts
pub fn builtin_make_rectangular(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in function: make-polar
/// (make-polar magnitude angle) - create complex numbers from polar form
pub fn builtin_make_polar(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: real-part
/// (real-part z) - get the real part of a complex number
pub fn builtin_real_part(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("real-part: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(r, _)) => Ok(Value::Number(Number::Real(r)))
    Value::Number(n) => Ok(Value::Number(Number::Real(number_to_double(n))))
    _ => Err(EvalError::TypeError("real-part: argument must be a number"))
  }
}

/// Built-in functions: imag-part
/// (imag-part z) - get the imaginary part of a complex number
pub fn builtin_imag_part(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("imag-part: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(_, i)) => Ok(Value::Number(Number::Real(i)))
    Value::Number(_) => Ok(Value::Number(Number::Real(0.0))) // The imaginary part of the real number is 0
    _ => Err(EvalError::TypeError("imag-part: argument must be a number"))
  }
}

/// Built-in function: magnitude
/// (magnitude z) - get the absolute value of a complex number
pub fn builtin_magnitude(args : Array[Value]) -> Result[Value, EvalError] {
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

/// Built-in functions: angle
/// (angle z) - get the deflection angle of a complex number
pub fn builtin_angle(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("angle: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Complex(r, i)) => {
      Ok(Value::Number(Number::Real(@math.atan2(i, r))))
    }
    Value::Number(n) => {
      // The deflection angle of the real number is 0 or π
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

/// Built-in functions: complex?
/// (complex? obj) - Determines whether obj is a complex number (all numbers are complex numbers)
pub fn builtin_complex_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("complex?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(_) => Ok(Value::Bool(true)) // All numbers are a subset of complex numbers
    _ => Ok(Value::Bool(false))
  }
}

// =============================================================================
// Rational Number-Related Built-In Functions
// =============================================================================

/// Built-in function: numerator
/// (numerator q) - get the numerator of a rational number
pub fn builtin_numerator(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("numerator: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(n)) => Ok(Value::Number(Number::Int(n)))
    Value::Number(Number::Rational(num, _)) => Ok(Value::Number(Number::Int(num)))
    _ => Err(EvalError::TypeError("numerator: argument must be an integer or rational"))
  }
}

/// built-in function: denominator
/// (denominator q) - get denominator of rational numbers
pub fn builtin_denominator(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("denominator: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Number(Number::Int(1)))
    Value::Number(Number::Rational(_, den)) => Ok(Value::Number(Number::Int(den)))
    _ => Err(EvalError::TypeError("denominator: argument must be an integer or rational"))
  }
}

/// Built-in functions: rational?
/// (rational? obj) - Determine if obj is a rational number
pub fn builtin_rational_p(args : Array[Value]) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(EvalError::ArityError("rational?: requires exactly 1 argument"))
  }
  match args[0] {
    Value::Number(Number::Int(_)) => Ok(Value::Bool(true))
    Value::Number(Number::Rational(_, _)) => Ok(Value::Bool(true))
    _ => Ok(Value::Bool(false))
  }
}
