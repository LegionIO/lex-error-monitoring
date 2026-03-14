# lex-error-monitoring

Error monitoring modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements the brain's error monitoring system — continuous comparison of expected vs. actual outcomes. Detects performance errors, response conflicts, and prediction violations. Tracks error rates per domain, adjusts a caution level that produces post-error slowing (increased caution after mistakes), and provides confidence calibration data to the prediction engine.

Based on Holroyd and Coles' reinforcement learning theory of error-related brain activity (ERN).

## Usage

```ruby
client = Legion::Extensions::ErrorMonitoring::Client.new

# Detect an error: expected vs actual mismatch
client.detect_error(
  expected: :success,
  actual: :timeout,
  domain: :networking,
  error_type: :performance,
  severity: :high
)
# => { success: true, error_id: "...", detected: true,
#      caution_level: 0.7, post_error_slowing: true }

# Monitor for response conflicts
client.monitor_conflict(
  response_a: { action: :proceed },
  response_b: { action: :wait },
  domain: :decision_making
)
# => { conflict_detected: true, conflict_level: 0.8, caution_boost: 0.16 }

# Record a correct response (reduces caution)
client.record_correct_response(domain: :networking)

# Check current caution state
client.caution_level
# => { caution: 0.6, caution_label: :vigilant, post_error_slowing: true }

# Error rate in a domain
client.error_rate(domain: :networking)
# => { error_rate: 0.15, rate_label: :low, window_size: 20, error_count: 3 }

# Domain-specific error profile
client.domain_error_profile(domain: :networking)
# => { error_count: 3, error_rate: 0.15, most_common_type: :performance }

# Periodic maintenance: decay caution, prune old errors
client.update_error_monitoring
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
