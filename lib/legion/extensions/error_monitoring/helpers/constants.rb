# frozen_string_literal: true

module Legion
  module Extensions
    module ErrorMonitoring
      module Helpers
        module Constants
          MAX_ERROR_LOG = 500
          MAX_CONFLICT_LOG = 200
          MAX_CORRECTIONS = 200

          ERROR_RATE_ALPHA = 0.12
          CONFLICT_ALPHA = 0.1
          CONFIDENCE_ALPHA = 0.1

          DEFAULT_ERROR_RATE = 0.1
          DEFAULT_CONFLICT_LEVEL = 0.0
          DEFAULT_CONFIDENCE = 0.7

          POST_ERROR_SLOWDOWN = 0.3
          SLOWDOWN_DECAY = 0.05
          MAX_SLOWDOWN = 1.0

          CONFLICT_THRESHOLD = 0.5
          SEVERE_ERROR_THRESHOLD = 0.7
          CORRECTION_BOOST = 0.05

          ERROR_SEVERITY_LABELS = {
            (0.8..) => :critical,
            (0.6...0.8) => :major,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :minor,
            (..0.2) => :trivial
          }.freeze

          MONITORING_STATE_LABELS = {
            vigilant: 'heightened error sensitivity after recent errors',
            normal: 'standard monitoring',
            relaxed: 'low error rate, reduced monitoring',
            overwhelmed: 'error rate too high, system stressed'
          }.freeze
        end
      end
    end
  end
end
