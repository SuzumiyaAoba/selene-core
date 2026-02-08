/// garbage collection
///
/// MoonBit is a GC language, so low-level memory management is dependent on the runtime.
/// This module provides:
/// - Memory usage statistics
/// - Continuation store cleanup
/// - Explicit release of VM resources
/// - GC trigger point management

/// GC statistics
pub(all) struct GCStats {
  /// Number of Values ​​created
  mut values_allocated : Int
  /// Number of Closures created
  mut closures_allocated : Int
  /// Number of continuations created
  mut continuations_allocated : Int
  /// Number of pairs created
  mut pairs_allocated : Int
  /// Number of Vectors created
  mut vectors_allocated : Int
  /// Number of Boxes created
  mut boxes_allocated : Int
  /// Number of times GC was run
  mut gc_runs : Int
  /// Number of continuations freed in last GC
  mut last_gc_freed_continuations : Int
}

/// Global GC statistics
let gc_stats : GCStats = {
  values_allocated: 0,
  closures_allocated: 0,
  continuations_allocated: 0,
  pairs_allocated: 0,
  vectors_allocated: 0,
  boxes_allocated: 0,
  gc_runs: 0,
  last_gc_freed_continuations: 0,
}

/// Get GC statistics
pub fn get_gc_stats() -> GCStats {
  gc_stats
}

/// Reset GC statistics
pub fn reset_gc_stats() -> Unit {
  gc_stats.values_allocated = 0
  gc_stats.closures_allocated = 0
  gc_stats.continuations_allocated = 0
  gc_stats.pairs_allocated = 0
  gc_stats.vectors_allocated = 0
  gc_stats.boxes_allocated = 0
  gc_stats.gc_runs = 0
  gc_stats.last_gc_freed_continuations = 0
}

/// Record creation of Value
pub fn gc_track_value() -> Unit {
  gc_stats.values_allocated = gc_stats.values_allocated + 1
}

/// Record closure creation
pub fn gc_track_closure() -> Unit {
  gc_stats.closures_allocated = gc_stats.closures_allocated + 1
}

/// Record Continuation creation
pub fn gc_track_continuation() -> Unit {
  gc_stats.continuations_allocated = gc_stats.continuations_allocated + 1
}

/// Record pair creation
pub fn gc_track_pair() -> Unit {
  gc_stats.pairs_allocated = gc_stats.pairs_allocated + 1
}

/// Record Vector creation
pub fn gc_track_vector() -> Unit {
  gc_stats.vectors_allocated = gc_stats.vectors_allocated + 1
}

/// Record Box creation
pub fn gc_track_box() -> Unit {
  gc_stats.boxes_allocated = gc_stats.boxes_allocated + 1
}

/// Mark to determine whether the continuation is alive
pub(all) struct ContinuationMark {
  cont_id : Int
  mut marked : Bool
}

/// A map that manages the survival status of continuations
let continuation_marks : Array[ContinuationMark] = []

/// Add continuation to marked list
pub fn gc_register_continuation(cont_id : Int) -> Unit {
  continuation_marks.push({ cont_id, marked: false })
  gc_track_continuation()
}

/// Mark continuation (reachable)
pub fn gc_mark_continuation(cont_id : Int) -> Unit {
  for mark in continuation_marks {
    if mark.cont_id == cont_id {
      mark.marked = true
      return
    }
  }
}

/// Scan and mark values in VM stack (iterative to avoid stack overflow)
fn gc_mark_value(value : Value) -> Unit {
  let worklist : Array[Value] = [value]
  let visited_boxes : Array[Int] = []
  let _ = while worklist.length() > 0 {
    let current = worklist.pop()
    match current {
      Some(v) =>
        match v {
          Value::Procedure(Procedure::Cont(cont)) =>
            gc_mark_continuation(cont.id)
          Value::Procedure(Procedure::VMCont(cont)) =>
            gc_mark_continuation(cont.id)
          Value::Procedure(Procedure::Closure(_, _, _)) => ()
          Value::Procedure(Procedure::VMClosure(closure)) => {
            for capture in closure.captures {
              worklist.push(capture)
            }
          }
          Value::Pair(car, cdr, _) => {
            worklist.push(car)
            // Iterate on cdr inline to reduce worklist pressure
            let mut tail = cdr
            let _ = while true {
              match tail {
                Value::Pair(c, d, _) => {
                  worklist.push(c)
                  tail = d
                }
                _ => {
                  worklist.push(tail)
                  break
                }
              }
            } else {
              ()
            }
          }
          Value::Vector(items) => {
            for item in items {
              worklist.push(item)
            }
          }
          Value::Box(cell) => {
            // Cycle detection: skip already-visited boxes
            let mut already_visited = false
            for bid in visited_boxes {
              if bid == cell.id {
                already_visited = true
                break
              }
            }
            if not(already_visited) {
              visited_boxes.push(cell.id)
              worklist.push(cell.val)
            }
          }
          Value::MultipleValues(values) => {
            for mv in values {
              worklist.push(mv)
            }
          }
          _ => ()
        }
      None => break
    }
  } else {
    ()
  }
}

/// Scan VM state and mark continuation reachable
pub fn gc_mark_from_vm(vm : VMState) -> Unit {
  // Scan values ​​in stack
  for value in vm.stack {
    gc_mark_value(value)
  }

  // Frames in the call stack do not directly reference continuations

  // Scan values ​​in the global environment
  vm.globals.each(fn(_name, value) { gc_mark_value(value) })
}

/// Release unmarked continuations (sweep)
pub fn gc_sweep_continuations() -> Int {
  let mut freed_count = 0

  // Collect surviving continuations into a new array
  let survivors : Array[ContinuationMark] = []

  for mark in continuation_marks {
    if not(mark.marked) {
      // Delete unmarked continuation
      gc_remove_from_continuation_store(mark.cont_id)
      freed_count = freed_count + 1
    } else {
      // Reset marks and prepare for next GC cycle
      mark.marked = false
      survivors.push(mark)
    }
  }

  // Update continuation mark array
  continuation_marks.clear()
  for s in survivors {
    continuation_marks.push(s)
  }

  freed_count
}

/// Delete from continuation store (access continuation_store in value.mbt)
fn gc_remove_from_continuation_store(cont_id : Int) -> Unit {
  remove_continuation(cont_id)
}

/// Run GC (mark and sweep)
pub fn gc_run(vm : VMState) -> Int {
  gc_stats.gc_runs = gc_stats.gc_runs + 1

  // Phase 1: Mark
  gc_mark_from_vm(vm)

  // Phase 2: Sweep
  let freed = gc_sweep_continuations()
  gc_stats.last_gc_freed_continuations = freed

  freed
}

/// GC threshold setting
pub(all) struct GCConfig {
  /// Allocation count threshold that triggers GC
  mut allocation_threshold : Int
  /// Threshold number of continuations
  mut continuation_threshold : Int
  /// Whether to enable GC
  mut enabled : Bool
}

/// Global GC settings
let gc_config : GCConfig = {
  allocation_threshold: 10000,
  continuation_threshold: 100,
  enabled: true,
}

/// Get GC settings
pub fn get_gc_config() -> GCConfig {
  gc_config
}

/// Update GC settings
pub fn set_gc_config(
  allocation_threshold~ : Int = gc_config.allocation_threshold,
  continuation_threshold~ : Int = gc_config.continuation_threshold,
  enabled~ : Bool = gc_config.enabled
) -> Unit {
  gc_config.allocation_threshold = allocation_threshold
  gc_config.continuation_threshold = continuation_threshold
  gc_config.enabled = enabled
}

/// Check if GC is required and run if necessary
pub fn gc_check_and_run(vm : VMState) -> Int {
  if not(gc_config.enabled) {
    return 0
  }

  // GC when number of continuations exceeds threshold
  if continuation_marks.length() > gc_config.continuation_threshold {
    return gc_run(vm)
  }

  // GC when the number of allocations exceeds the threshold
  let total_allocs = gc_stats.values_allocated +
    gc_stats.closures_allocated +
    gc_stats.pairs_allocated +
    gc_stats.vectors_allocated +
    gc_stats.boxes_allocated

  if total_allocs > gc_config.allocation_threshold {
    return gc_run(vm)
  }

  0
}

/// Clear VM state
pub fn gc_clear_vm(vm : VMState) -> Unit {
  vm.stack.clear()
  vm.call_stack.clear()
  vm.current_chunk = -1
  vm.ip = 0
}

/// Clear all continuations (used when resetting VM)
pub fn gc_clear_all_continuations() -> Unit {
  continuation_marks.clear()
  clear_continuations()
}

/// Get GC information as a string (for debugging)
pub fn gc_stats_to_string() -> String {
  let stats = gc_stats
  let mut result = "GC Stats:\n"
  result = result + "  Values allocated: " + stats.values_allocated.to_string() + "\n"
  result = result + "  Closures allocated: " + stats.closures_allocated.to_string() + "\n"
  result = result + "  Continuations allocated: " + stats.continuations_allocated.to_string() + "\n"
  result = result + "  Pairs allocated: " + stats.pairs_allocated.to_string() + "\n"
  result = result + "  Vectors allocated: " + stats.vectors_allocated.to_string() + "\n"
  result = result + "  Boxes allocated: " + stats.boxes_allocated.to_string() + "\n"
  result = result + "  GC runs: " + stats.gc_runs.to_string() + "\n"
  result = result + "  Last GC freed continuations: " + stats.last_gc_freed_continuations.to_string() + "\n"
  result = result + "  Active continuations: " + continuation_marks.length().to_string() + "\n"
  result
}
