# frozen_string_literal: true

module Legion
  module Extensions
    module ErrorMonitoring
      module Helpers
        class ErrorMonitor
          include Constants

          attr_reader :error_log, :conflict_log, :corrections,
                      :error_rate, :conflict_level, :confidence, :slowdown

          def initialize
            @error_log      = []
            @conflict_log   = []
            @corrections    = []
            @error_rate     = DEFAULT_ERROR_RATE
            @conflict_level = DEFAULT_CONFLICT_LEVEL
            @confidence     = DEFAULT_CONFIDENCE
            @slowdown       = 0.0
          end

          def register_error(action:, domain:, intended:, actual:, severity:)
            signal = ErrorSignal.new(
              action: action, domain: domain,
              intended: intended, actual: actual, severity: severity
            )
            @error_log << signal
            @error_log.shift while @error_log.size > MAX_ERROR_LOG

            update_error_rate(severity.to_f)
            apply_post_error_slowdown(severity.to_f)
            update_confidence(correct: false)
            signal
          end

          def register_success(action:, domain:)
            update_error_rate(0.0)
            update_confidence(correct: true)
            decay_slowdown
            { action: action, domain: domain, error_rate: @error_rate.round(4) }
          end

          def register_conflict(action_a:, action_b:, domain:, intensity:)
            entry = {
              action_a: action_a, action_b: action_b,
              domain: domain, intensity: intensity.to_f.clamp(0.0, 1.0),
              detected_at: Time.now.utc
            }
            @conflict_log << entry
            @conflict_log.shift while @conflict_log.size > MAX_CONFLICT_LOG

            update_conflict_level(intensity.to_f)
            entry
          end

          def register_correction(action:, domain:, original_error:, correction:)
            entry = {
              action: action, domain: domain,
              original_error: original_error, correction: correction,
              applied_at: Time.now.utc
            }
            @corrections << entry
            @corrections.shift while @corrections.size > MAX_CORRECTIONS

            mark_error_corrected(action, domain)
            update_confidence_boost
            entry
          end

          def recent_errors(limit: 10)
            @error_log.last(limit)
          end

          def errors_in(domain:)
            @error_log.select { |e| e.domain == domain }
          end

          def uncorrected_errors
            @error_log.reject(&:corrected)
          end

          def conflict_active?
            @conflict_level >= CONFLICT_THRESHOLD
          end

          def monitoring_state
            if @error_rate > 0.5
              :overwhelmed
            elsif @slowdown > 0.1
              :vigilant
            elsif @error_rate < 0.05
              :relaxed
            else
              :normal
            end
          end

          def tick
            decay_slowdown
            decay_conflict
          end

          def error_count
            @error_log.size
          end

          def correction_rate
            return 0.0 if @error_log.empty?

            corrected = @error_log.count(&:corrected)
            corrected.to_f / @error_log.size
          end

          def to_h
            {
              error_rate: @error_rate.round(4),
              conflict_level: @conflict_level.round(4),
              confidence: @confidence.round(4),
              slowdown: @slowdown.round(4),
              state: monitoring_state,
              state_label: MONITORING_STATE_LABELS[monitoring_state],
              total_errors: @error_log.size,
              uncorrected: uncorrected_errors.size,
              correction_rate: correction_rate.round(4),
              conflict_active: conflict_active?
            }
          end

          private

          def update_error_rate(severity)
            @error_rate += ERROR_RATE_ALPHA * (severity - @error_rate)
          end

          def update_conflict_level(intensity)
            @conflict_level += CONFLICT_ALPHA * (intensity - @conflict_level)
          end

          def update_confidence(correct:)
            target = correct ? 1.0 : 0.0
            @confidence += CONFIDENCE_ALPHA * (target - @confidence)
          end

          def update_confidence_boost
            @confidence = [@confidence + CORRECTION_BOOST, 1.0].min
          end

          def apply_post_error_slowdown(severity)
            increase = POST_ERROR_SLOWDOWN * severity
            @slowdown = [@slowdown + increase, MAX_SLOWDOWN].min
          end

          def decay_slowdown
            @slowdown = [@slowdown - SLOWDOWN_DECAY, 0.0].max
          end

          def decay_conflict
            @conflict_level = [@conflict_level * 0.95, 0.0].max
          end

          def mark_error_corrected(action, domain)
            match = @error_log.reverse.find { |e| e.action == action && e.domain == domain && !e.corrected }
            match&.mark_corrected
          end
        end
      end
    end
  end
end
