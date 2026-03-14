# frozen_string_literal: true

RSpec.describe Legion::Extensions::ErrorMonitoring::Helpers::ErrorMonitor do
  subject(:monitor) { described_class.new }

  let(:constants) { Legion::Extensions::ErrorMonitoring::Helpers::Constants }

  describe '#register_error' do
    it 'creates an error signal' do
      signal = monitor.register_error(action: :parse, domain: :data, intended: :valid, actual: :malformed,
                                      severity: 0.5)
      expect(signal).to be_a(Legion::Extensions::ErrorMonitoring::Helpers::ErrorSignal)
      expect(monitor.error_count).to eq(1)
    end

    it 'increases error rate' do
      before = monitor.error_rate
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.8)
      expect(monitor.error_rate).to be > before
    end

    it 'applies post-error slowdown' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.8)
      expect(monitor.slowdown).to be > 0
    end

    it 'decreases confidence' do
      before = monitor.confidence
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.5)
      expect(monitor.confidence).to be < before
    end

    it 'limits error log size' do
      (constants::MAX_ERROR_LOG + 10).times do |i|
        monitor.register_error(action: :"a_#{i}", domain: :d, intended: :i, actual: :a, severity: 0.3)
      end
      expect(monitor.error_count).to eq(constants::MAX_ERROR_LOG)
    end
  end

  describe '#register_success' do
    it 'decreases error rate' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.8)
      before = monitor.error_rate
      monitor.register_success(action: :b, domain: :d)
      expect(monitor.error_rate).to be < before
    end

    it 'increases confidence' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.5)
      before = monitor.confidence
      monitor.register_success(action: :b, domain: :d)
      expect(monitor.confidence).to be > before
    end
  end

  describe '#register_conflict' do
    it 'records a conflict' do
      entry = monitor.register_conflict(action_a: :run, action_b: :hide, domain: :safety, intensity: 0.8)
      expect(entry[:action_a]).to eq(:run)
      expect(entry[:intensity]).to eq(0.8)
    end

    it 'increases conflict level' do
      monitor.register_conflict(action_a: :a, action_b: :b, domain: :d, intensity: 0.9)
      expect(monitor.conflict_level).to be > 0
    end
  end

  describe '#register_correction' do
    it 'records a correction' do
      monitor.register_error(action: :parse, domain: :data, intended: :valid, actual: :malformed, severity: 0.5)
      entry = monitor.register_correction(action: :parse, domain: :data, original_error: :malformed, correction: :retry)
      expect(entry[:correction]).to eq(:retry)
    end

    it 'marks the error as corrected' do
      monitor.register_error(action: :parse, domain: :data, intended: :valid, actual: :malformed, severity: 0.5)
      monitor.register_correction(action: :parse, domain: :data, original_error: :malformed, correction: :retry)
      expect(monitor.uncorrected_errors).to be_empty
    end

    it 'boosts confidence' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.5)
      before = monitor.confidence
      monitor.register_correction(action: :a, domain: :d, original_error: :a, correction: :fix)
      expect(monitor.confidence).to be > before
    end
  end

  describe '#recent_errors' do
    it 'returns recent errors' do
      3.times { |i| monitor.register_error(action: :"a_#{i}", domain: :d, intended: :i, actual: :a, severity: 0.3) }
      expect(monitor.recent_errors(limit: 2).size).to eq(2)
    end
  end

  describe '#errors_in' do
    it 'filters by domain' do
      monitor.register_error(action: :a, domain: :network, intended: :i, actual: :a, severity: 0.3)
      monitor.register_error(action: :b, domain: :data, intended: :i, actual: :a, severity: 0.3)
      expect(monitor.errors_in(domain: :network).size).to eq(1)
    end
  end

  describe '#uncorrected_errors' do
    it 'returns only uncorrected errors' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.3)
      monitor.register_error(action: :b, domain: :d, intended: :i, actual: :a, severity: 0.3)
      monitor.register_correction(action: :a, domain: :d, original_error: :a, correction: :fix)
      expect(monitor.uncorrected_errors.size).to eq(1)
    end
  end

  describe '#conflict_active?' do
    it 'returns false initially' do
      expect(monitor.conflict_active?).to be false
    end

    it 'returns true after sustained high-intensity conflict' do
      20.times { monitor.register_conflict(action_a: :a, action_b: :b, domain: :d, intensity: 0.9) }
      expect(monitor.conflict_active?).to be true
    end
  end

  describe '#monitoring_state' do
    it 'returns :normal initially' do
      expect(monitor.monitoring_state).to eq(:normal)
    end

    it 'returns :vigilant after errors (slowdown active)' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.8)
      expect(monitor.monitoring_state).to eq(:vigilant)
    end

    it 'returns :relaxed after many successes' do
      50.times { monitor.register_success(action: :a, domain: :d) }
      expect(monitor.monitoring_state).to eq(:relaxed)
    end
  end

  describe '#tick' do
    it 'decays slowdown' do
      monitor.register_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.8)
      before = monitor.slowdown
      monitor.tick
      expect(monitor.slowdown).to be < before
    end

    it 'decays conflict level' do
      monitor.register_conflict(action_a: :a, action_b: :b, domain: :d, intensity: 0.9)
      before = monitor.conflict_level
      monitor.tick
      expect(monitor.conflict_level).to be < before
    end
  end

  describe '#correction_rate' do
    it 'returns 0 with no errors' do
      expect(monitor.correction_rate).to eq(0.0)
    end

    it 'returns ratio of corrected to total' do
      monitor.register_error(action: :first, domain: :d, intended: :i, actual: :a, severity: 0.3)
      monitor.register_error(action: :second, domain: :d, intended: :i, actual: :a, severity: 0.3)
      monitor.register_correction(action: :first, domain: :d, original_error: :a, correction: :fix)
      expect(monitor.correction_rate).to eq(0.5)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      h = monitor.to_h
      expect(h).to include(:error_rate, :conflict_level, :confidence, :slowdown, :state,
                           :state_label, :total_errors, :uncorrected, :correction_rate, :conflict_active)
    end
  end
end
