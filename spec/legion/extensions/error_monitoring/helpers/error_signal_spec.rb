# frozen_string_literal: true

RSpec.describe Legion::Extensions::ErrorMonitoring::Helpers::ErrorSignal do
  subject(:signal) do
    described_class.new(action: :api_call, domain: :network, intended: :success, actual: :timeout, severity: 0.7)
  end

  let(:constants) { Legion::Extensions::ErrorMonitoring::Helpers::Constants }

  describe '#initialize' do
    it 'sets attributes' do
      expect(signal.action).to eq(:api_call)
      expect(signal.domain).to eq(:network)
      expect(signal.intended).to eq(:success)
      expect(signal.actual).to eq(:timeout)
      expect(signal.severity).to eq(0.7)
      expect(signal.corrected).to be false
    end

    it 'clamps severity' do
      high = described_class.new(action: :a, domain: :d, intended: :i, actual: :a, severity: 1.5)
      expect(high.severity).to eq(1.0)
    end

    it 'records detected_at' do
      expect(signal.detected_at).to be_a(Time)
    end
  end

  describe '#mark_corrected' do
    it 'marks the error as corrected' do
      signal.mark_corrected
      expect(signal.corrected).to be true
    end
  end

  describe '#severe?' do
    it 'returns true for high severity' do
      expect(signal.severe?).to be true
    end

    it 'returns false for low severity' do
      low = described_class.new(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.3)
      expect(low.severe?).to be false
    end
  end

  describe '#age' do
    it 'returns elapsed time' do
      expect(signal.age).to be >= 0.0
    end
  end

  describe '#label' do
    it 'returns :major for 0.7 severity' do
      expect(signal.label).to eq(:major)
    end

    it 'returns :trivial for low severity' do
      low = described_class.new(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.1)
      expect(low.label).to eq(:trivial)
    end

    it 'returns :critical for high severity' do
      crit = described_class.new(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.9)
      expect(crit.label).to eq(:critical)
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields' do
      h = signal.to_h
      expect(h).to include(:action, :domain, :intended, :actual, :severity, :label, :detected_at, :corrected, :age)
    end
  end
end
