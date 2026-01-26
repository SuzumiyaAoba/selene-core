# Selene Core

A Scheme (R5RS) interpreter and virtual machine implemented in MoonBit.

## Overview

Selene Core is a Scheme interpreter that conforms to the R5RS (Revised^5 Report on the Algorithmic Language Scheme) specification. It provides both a tree-walking interpreter and a bytecode compiler with a virtual machine.

## Features

### R5RS Compliance

- **Special Forms**: `if`, `lambda`, `define`, `set!`, `begin`, `quote`, `quasiquote`, `let`, `let*`, `letrec`, `cond`, `case`, `and`, `or`, `do`, `delay`, `force`
- **Macros**: Pattern-matching macros using `syntax-rules`
- **Numeric Tower**: Integers, rational numbers, real numbers, complex numbers
- **Data Types**: Lists, vectors, strings, characters, symbols, booleans
- **Control Flow**: `call/cc` (continuations), `dynamic-wind`, `call-with-values`/`values` (multiple values)
- **I/O**: Port operations, file input/output

### Compiler

- **Intermediate Representation (IR)**: Conversion from AST to an optimizable intermediate representation
- **Optimization Passes**:
  - Constant folding
  - Dead code elimination
  - Inline expansion
- **Bytecode Generation**: Conversion from IR to stack-based bytecode
- **Serialization/Deserialization**: Text and binary formats

### Virtual Machine (VM)

- **Stack-Based Architecture**: Efficient instruction execution
- **Closure Support**: Free variable capture with boxing support for mutable variables
- **Continuation Support**: Full implementation of `call/cc`
- **Tail Call Optimization**: Efficient recursive function execution
- **Garbage Collection**: Management of continuation objects

### Development Tools

- **Debugger**: Breakpoints, step execution, state inspection
- **Profiler**: Instruction statistics, function call statistics, hotspot analysis
- **Bytecode Dump**: Human-readable bytecode representation

## Requirements

- MoonBit CLI (latest version recommended)
- make (optional)

## Installation

```bash
# Clone the repository
git clone https://github.com/SuzumiyaAoba/selene-core.git
cd selene-core

# Build
moon build

# Run tests
moon test
```

## Usage

### REPL

```bash
moon run
```

### Examples

```scheme
; Factorial function
(define (factorial n)
  (if (<= n 1)
      1
      (* n (factorial (- n 1)))))

(factorial 10)  ; => 3628800

; Higher-order functions
(define (map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst)) (map f (cdr lst)))))

(map (lambda (x) (* x x)) '(1 2 3 4 5))  ; => (1 4 9 16 25)

; Closures
(define (make-counter)
  (let ((count 0))
    (lambda ()
      (set! count (+ count 1))
      count)))

(define counter (make-counter))
(counter)  ; => 1
(counter)  ; => 2

; Continuations
(call/cc (lambda (k) (+ 1 (k 10))))  ; => 10
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Source Code                             │
│                    (Scheme / R5RS)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Lexer                                 │
│                     (lexer.mbt)                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Parser                                │
│                     (parser.mbt)                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          AST                                 │
│                      (value.mbt)                             │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│      Tree-Walking        │    │        Compiler          │
│       Interpreter        │    │                          │
│       (eval.mbt)         │    │   AST → IR → Bytecode    │
│                          │    │                          │
└──────────────────────────┘    └──────────────────────────┘
                                              │
                                              ▼
                                ┌──────────────────────────┐
                                │     Virtual Machine      │
                                │        (vm.mbt)          │
                                │                          │
                                │   Bytecode Execution     │
                                └──────────────────────────┘
```

## File Structure

```
src/
├── lexer.mbt              # Lexical analysis
├── parser.mbt             # Syntax analysis
├── value.mbt              # Value representation
├── env.mbt                # Environment
├── eval.mbt               # Evaluator core
├── special_form.mbt       # Special forms
├── builtin_*.mbt          # Built-in functions
├── ir.mbt                 # Intermediate Representation (IR)
├── compile.mbt            # AST → IR compiler
├── optimize.mbt           # IR optimization
├── opcode.mbt             # Bytecode definitions
├── codegen.mbt            # IR → bytecode generation
├── serialize.mbt          # Bytecode serialization
├── deserialize.mbt        # Bytecode deserialization
├── vm.mbt                 # Virtual machine
├── vm_repl.mbt            # VM REPL context
├── gc.mbt                 # Garbage collection
├── debugger.mbt           # Debugger
├── profiler.mbt           # Profiler
├── bytecode_dump.mbt      # Bytecode dump tool
└── *_test.mbt             # Test files
```

## Testing

593 tests are implemented.

```bash
# Run all tests
moon test

# Run tests for a specific package
moon test --package selene-core/src
```

## References

- [R5RS Specification](https://schemers.org/Documents/Standards/R5RS/)
- [MoonBit Language Documentation](https://www.moonbitlang.com/docs/)

## License

MIT License
