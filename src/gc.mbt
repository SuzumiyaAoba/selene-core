/// ガベージコレクション
///
/// MoonBit はGC言語であるため、低レベルのメモリ管理はランタイムに依存する。
/// このモジュールでは以下を提供する:
/// - メモリ使用量の統計
/// - 継続ストアのクリーンアップ
/// - VMリソースの明示的解放
/// - GCトリガーポイントの管理

/// GC 統計情報
pub(all) struct GCStats {
  /// 作成された Value の数
  mut values_allocated : Int
  /// 作成された Closure の数
  mut closures_allocated : Int
  /// 作成された Continuation の数
  mut continuations_allocated : Int
  /// 作成された Pair の数
  mut pairs_allocated : Int
  /// 作成された Vector の数
  mut vectors_allocated : Int
  /// 作成された Box の数
  mut boxes_allocated : Int
  /// GC が実行された回数
  mut gc_runs : Int
  /// 最後の GC で解放された継続の数
  mut last_gc_freed_continuations : Int
}

/// グローバル GC 統計
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

/// GC 統計を取得
pub fn get_gc_stats() -> GCStats {
  gc_stats
}

/// GC 統計をリセット
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

/// Value 作成を記録
pub fn gc_track_value() -> Unit {
  gc_stats.values_allocated = gc_stats.values_allocated + 1
}

/// Closure 作成を記録
pub fn gc_track_closure() -> Unit {
  gc_stats.closures_allocated = gc_stats.closures_allocated + 1
}

/// Continuation 作成を記録
pub fn gc_track_continuation() -> Unit {
  gc_stats.continuations_allocated = gc_stats.continuations_allocated + 1
}

/// Pair 作成を記録
pub fn gc_track_pair() -> Unit {
  gc_stats.pairs_allocated = gc_stats.pairs_allocated + 1
}

/// Vector 作成を記録
pub fn gc_track_vector() -> Unit {
  gc_stats.vectors_allocated = gc_stats.vectors_allocated + 1
}

/// Box 作成を記録
pub fn gc_track_box() -> Unit {
  gc_stats.boxes_allocated = gc_stats.boxes_allocated + 1
}

/// 継続が生きているかを判定するためのマーク
pub(all) struct ContinuationMark {
  cont_id : Int
  mut marked : Bool
}

/// 継続の生存状態を管理するマップ
let continuation_marks : Array[ContinuationMark] = []

/// 継続をマークリストに追加
pub fn gc_register_continuation(cont_id : Int) -> Unit {
  continuation_marks.push({ cont_id, marked: false })
  gc_track_continuation()
}

/// 継続をマークする（到達可能）
pub fn gc_mark_continuation(cont_id : Int) -> Unit {
  for mark in continuation_marks {
    if mark.cont_id == cont_id {
      mark.marked = true
      return
    }
  }
}

/// VM スタック内の値をスキャンしてマーク
fn gc_mark_value(value : Value) -> Unit {
  match value {
    Value::Procedure(Procedure::Cont(cont)) => gc_mark_continuation(cont.id)
    Value::Procedure(Procedure::VMCont(cont)) => gc_mark_continuation(cont.id)
    Value::Procedure(Procedure::Closure(_, _, _)) => ()  // 環境内の継続もマークが必要だが、単純化
    Value::Procedure(Procedure::VMClosure(closure)) => {
      // キャプチャ内の値をスキャン
      for capture in closure.captures {
        gc_mark_value(capture)
      }
    }
    Value::Pair(car, cdr) => {
      gc_mark_value(car)
      gc_mark_value(cdr)
    }
    Value::Vector(items) => {
      for item in items {
        gc_mark_value(item)
      }
    }
    Value::Box(cell) => gc_mark_value(cell.val)
    Value::MultipleValues(values) => {
      for v in values {
        gc_mark_value(v)
      }
    }
    _ => ()
  }
}

/// VM 状態をスキャンして到達可能な継続をマーク
pub fn gc_mark_from_vm(vm : VMState) -> Unit {
  // スタック内の値をスキャン
  for value in vm.stack {
    gc_mark_value(value)
  }

  // コールスタック内のフレームは継続を直接参照しない

  // グローバル環境内の値をスキャン
  vm.globals.each(fn(_name, value) { gc_mark_value(value) })
}

/// マークされていない継続を解放（スイープ）
pub fn gc_sweep_continuations() -> Int {
  let mut freed_count = 0

  // 生き残る継続を新しい配列に収集
  let survivors : Array[ContinuationMark] = []

  for mark in continuation_marks {
    if not(mark.marked) {
      // マークされていない継続を削除
      gc_remove_from_continuation_store(mark.cont_id)
      freed_count = freed_count + 1
    } else {
      // マークをリセットして次のGCサイクルに備える
      mark.marked = false
      survivors.push(mark)
    }
  }

  // 継続マーク配列を更新
  continuation_marks.clear()
  for s in survivors {
    continuation_marks.push(s)
  }

  freed_count
}

/// 継続ストアから削除（value.mbt の continuation_store にアクセス）
fn gc_remove_from_continuation_store(cont_id : Int) -> Unit {
  // continuation_store は value.mbt で定義されている
  // 新しい配列を作成して該当ID以外を保持
  let survivors : Array[(Int, ContinuationState)] = []
  for entry in continuation_store {
    if entry.0 != cont_id {
      survivors.push(entry)
    }
  }
  continuation_store.clear()
  for s in survivors {
    continuation_store.push(s)
  }
}

/// GC を実行（mark and sweep）
pub fn gc_run(vm : VMState) -> Int {
  gc_stats.gc_runs = gc_stats.gc_runs + 1

  // Phase 1: Mark
  gc_mark_from_vm(vm)

  // Phase 2: Sweep
  let freed = gc_sweep_continuations()
  gc_stats.last_gc_freed_continuations = freed

  freed
}

/// GC 閾値設定
pub(all) struct GCConfig {
  /// GC をトリガーするアロケーション数の閾値
  mut allocation_threshold : Int
  /// 継続の数の閾値
  mut continuation_threshold : Int
  /// GC を有効にするかどうか
  mut enabled : Bool
}

/// グローバル GC 設定
let gc_config : GCConfig = {
  allocation_threshold: 10000,
  continuation_threshold: 100,
  enabled: true,
}

/// GC 設定を取得
pub fn get_gc_config() -> GCConfig {
  gc_config
}

/// GC 設定を更新
pub fn set_gc_config(
  allocation_threshold~ : Int = gc_config.allocation_threshold,
  continuation_threshold~ : Int = gc_config.continuation_threshold,
  enabled~ : Bool = gc_config.enabled
) -> Unit {
  gc_config.allocation_threshold = allocation_threshold
  gc_config.continuation_threshold = continuation_threshold
  gc_config.enabled = enabled
}

/// GC が必要かチェックし、必要なら実行
pub fn gc_check_and_run(vm : VMState) -> Int {
  if not(gc_config.enabled) {
    return 0
  }

  // 継続の数が閾値を超えたらGC
  if continuation_marks.length() > gc_config.continuation_threshold {
    return gc_run(vm)
  }

  // アロケーション数が閾値を超えたらGC
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

/// VM 状態をクリア
pub fn gc_clear_vm(vm : VMState) -> Unit {
  vm.stack.clear()
  vm.call_stack.clear()
  vm.current_chunk = -1
  vm.ip = 0
}

/// 全ての継続をクリア（VM リセット時に使用）
pub fn gc_clear_all_continuations() -> Unit {
  continuation_marks.clear()
  continuation_store.clear()
  continuation_counter.val = 0
}

/// GC 情報を文字列として取得（デバッグ用）
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
