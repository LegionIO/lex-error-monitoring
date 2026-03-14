# frozen_string_literal: true

RSpec.describe Legion::Extensions::ErrorMonitoring::Runners::ErrorMonitoring do
  let(:client) { Legion::Extensions::ErrorMonitoring::Client.new }

  describe '#report_error' do
    it 'registers an error' do
      result = client.report_error(action: :api_call, domain: :network, intended: :ok, actual: :timeout, severity: 0.6)
      expect(result[:success]).to be true
      expect(result[:error][:action]).to eq(:api_call)
      expect(result[:slowdown]).to be > 0
    end
  end

  describe '#report_success' do
    it 'registers a success' do
      result = client.report_success(action: :api_call, domain: :network)
      expect(result[:success]).to be true
      expect(result[:error_rate]).to be_a(Float)
    end
  end

  describe '#report_conflict' do
    it 'registers a conflict' do
      result = client.report_conflict(action_a: :run, action_b: :hide, domain: :safety, intensity: 0.7)
      expect(result[:success]).to be true
      expect(result[:conflict][:action_a]).to eq(:run)
    end
  end

  describe '#apply_correction' do
    it 'applies a correction' do
      client.report_error(action: :parse, domain: :data, intended: :valid, actual: :bad, severity: 0.5)
      result = client.apply_correction(action: :parse, domain: :data, original_error: :bad, correction: :retry)
      expect(result[:success]).to be true
      expect(result[:confidence]).to be > 0
    end
  end

  describe '#recent_errors' do
    it 'returns recent errors' do
      client.report_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.3)
      result = client.recent_errors(limit: 5)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#errors_in_domain' do
    it 'filters errors by domain' do
      client.report_error(action: :a, domain: :net, intended: :i, actual: :a, severity: 0.3)
      client.report_error(action: :b, domain: :data, intended: :i, actual: :a, severity: 0.3)
      result = client.errors_in_domain(domain: :net)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#uncorrected_errors' do
    it 'returns uncorrected errors' do
      client.report_error(action: :a, domain: :d, intended: :i, actual: :a, severity: 0.3)
      result = client.uncorrected_errors
      expect(result[:count]).to eq(1)
    end
  end

  describe '#monitoring_state' do
    it 'returns current state' do
      result = client.monitoring_state
      expect(result[:success]).to be true
      expect(result[:state]).to be_a(Symbol)
    end
  end

  describe '#update_error_monitoring' do
    it 'runs tick' do
      result = client.update_error_monitoring
      expect(result[:success]).to be true
    end
  end

  describe '#error_monitoring_stats' do
    it 'returns stats' do
      result = client.error_monitoring_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:error_rate, :confidence, :state)
    end
  end
end
