# lex-error-monitoring

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Error monitoring modeling for the LegionIO cognitive architecture. Implements the brain's error monitoring system — continuous comparison of expected vs. actual outcomes (Error-Related Negativity, ERN). Detects performance errors, response conflicts, and prediction violations. Tracks error patterns per domain, adjusts confidence calibration, and triggers post-error slowing (increased caution following mistakes).

Based on Holroyd and Coles' reinforcement learning theory of error-related brain activity.

## Gem Info

- **Gem name**: `lex-error-monitoring`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::ErrorMonitoring`
- **Location**: `extensions-agentic/lex-error-monitoring/`

## File Structure

```
lib/legion/extensions/error_monitoring/
  error_monitoring.rb           # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # ERROR_TYPES, SEVERITY_LEVELS, CAUTION_LABELS, thresholds
    error_event.rb              # ErrorEvent value object
    error_monitor.rb            # Monitor: error detection, conflict monitoring, caution adjustment
  runners/
    error_monitoring.rb         # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `ERROR_TYPES` | `[:performance, :conflict, :prediction_violation, :omission, :commission]` | Error categories |
| `SEVERITY_LEVELS` | `[:critical, :high, :moderate, :low, :trivial]` | Error severity |
| `CAUTION_BOOST` | 0.2 | Caution level increase per detected error |
| `CAUTION_DECAY` | 0.03 | Caution level decrease per maintenance cycle |
| `CAUTION_CEILING` | 1.0 | Maximum caution level |
| `ERROR_RATE_WINDOW` | 20 | Rolling window for computing error rate |
| `CONFLICT_THRESHOLD` | 0.5 | Response conflict level above which monitoring fires |
| `MAX_ERRORS` | 500 | Rolling error log cap |
| `CAUTION_LABELS` | range hash | `hypercautious / vigilant / normal / relaxed` |
| `ERROR_RATE_LABELS` | range hash | `high / moderate / low / negligible` |

## Runners

All methods in `Legion::Extensions::ErrorMonitoring::Runners::ErrorMonitoring`.

| Method | Key Args | Returns |
|---|---|---|
| `detect_error` | `expected:, actual:, domain:, error_type:, severity: :moderate` | `{ success:, error_id:, detected:, caution_level:, post_error_slowing: }` |
| `monitor_conflict` | `response_a:, response_b:, domain:` | `{ success:, conflict_detected:, conflict_level:, domain:, caution_boost: }` |
| `record_correct_response` | `domain:` | `{ success:, domain:, caution_before:, caution_after: }` |
| `error_rate` | `domain: nil` | `{ success:, error_rate:, rate_label:, window_size:, error_count: }` |
| `caution_level` | — | `{ success:, caution:, caution_label:, post_error_slowing: }` |
| `domain_error_profile` | `domain:` | `{ success:, domain:, error_count:, error_rate:, most_common_type: }` |
| `recent_errors` | `limit: 10, domain: nil` | `{ success:, errors:, count: }` |
| `update_error_monitoring` | — | `{ success:, caution_decayed:, errors_pruned: }` |
| `error_monitoring_stats` | — | Full stats hash including per-domain and per-type breakdowns |

## Helpers

### `ErrorEvent`
Value object. Attributes: `id`, `expected`, `actual`, `domain`, `error_type`, `severity`, `timestamp`. `to_h`.

### `ErrorMonitor`
Central state: `@errors` (array, rolling), `@caution_level` (float 0–1), `@domain_counts` (hash by domain). Key methods:
- `detect(expected:, actual:, domain:, error_type:, severity:)`: compares expected vs actual (equality check), creates ErrorEvent if mismatch, boosts caution by `CAUTION_BOOST * severity_weight`
- `monitor_conflict(response_a:, response_b:, domain:)`: computes conflict level from response divergence, boosts caution if above `CONFLICT_THRESHOLD`
- `record_correct(domain:)`: slightly reduces caution (successful performance = reduced vigilance)
- `error_rate(domain:)`: computes errors / total events in last `ERROR_RATE_WINDOW` entries
- `post_error_slowing?`: returns true when caution_level > 0.5
- `decay_caution`: reduces `@caution_level` by `CAUTION_DECAY`, floors at 0.0

## Integration Points

- `detect_error` called from lex-tick's `post_tick_reflection` phase when actual outcome diverges from prediction
- `caution_level` feeds lex-tick's `action_selection` phase — high caution slows commitment to actions
- `error_rate[:error_rate]` feeds lex-prediction's confidence calibration (high domain error rate = lower prediction confidence)
- `monitor_conflict` called when lex-dual-process routing produces conflicting system recommendations
- `post_error_slowing` state feeds lex-dual-process to bias toward System 2 after errors
- `update_error_monitoring` maps to lex-tick's periodic maintenance cycle

## Development Notes

- `detect_error` comparison is strict equality between expected and actual — callers are responsible for normalizing before comparison
- Severity weights for caution boost: `:critical` = 1.0, `:high` = 0.8, `:moderate` = 0.5, `:low` = 0.3, `:trivial` = 0.1
- Correct response reduces caution by `CAUTION_DECAY / 2` (half the passive decay rate)
- Error rate uses a rolling window of the last N events (both errors and successes), not a time window
- Domain error profiles are computed on-demand from `@errors` scan, not maintained in a separate index
