# frozen_string_literal: true

module Legion
  module Extensions
    module ErrorMonitoring
      module Helpers
        class ErrorSignal
          include Constants

          attr_reader :action, :domain, :intended, :actual, :severity, :detected_at, :corrected

          def initialize(action:, domain:, intended:, actual:, severity:)
            @action      = action
            @domain      = domain
            @intended    = intended
            @actual      = actual
            @severity    = severity.to_f.clamp(0.0, 1.0)
            @detected_at = Time.now.utc
            @corrected   = false
          end

          def mark_corrected
            @corrected = true
          end

          def severe?
            @severity >= SEVERE_ERROR_THRESHOLD
          end

          def age
            Time.now.utc - @detected_at
          end

          def label
            ERROR_SEVERITY_LABELS.each { |range, lbl| return lbl if range.cover?(@severity) }
            :trivial
          end

          def to_h
            {
              action: @action,
              domain: @domain,
              intended: @intended,
              actual: @actual,
              severity: @severity.round(4),
              label: label,
              detected_at: @detected_at,
              corrected: @corrected,
              age: age.round(2)
            }
          end
        end
      end
    end
  end
end
