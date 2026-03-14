# frozen_string_literal: true

RSpec.describe Legion::Extensions::ErrorMonitoring::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::ErrorMonitoring' do
    expect(described_class.ancestors).to include(Legion::Extensions::ErrorMonitoring::Runners::ErrorMonitoring)
  end

  it 'supports full error monitoring lifecycle' do
    # Normal operation with some successes
    3.times { client.report_success(action: :process, domain: :data) }

    # Error occurs
    client.report_error(action: :api_call, domain: :network, intended: :ok, actual: :timeout, severity: 0.6)

    # System should now be vigilant with slowdown
    state = client.monitoring_state
    expect(state[:slowdown]).to be > 0

    # Conflict detected
    client.report_conflict(action_a: :retry, action_b: :abort, domain: :network, intensity: 0.7)

    # Correction applied
    client.apply_correction(action: :api_call, domain: :network, original_error: :timeout,
                            correction: :retry_with_backoff)

    # Verify correction
    uncorrected = client.uncorrected_errors
    expect(uncorrected[:count]).to eq(0)

    # Tick to decay slowdown
    client.update_error_monitoring

    # Stats
    stats = client.error_monitoring_stats
    expect(stats[:stats][:total_errors]).to eq(1)
    expect(stats[:stats][:correction_rate]).to eq(1.0)
  end
end
