# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module ErrorMonitoring
      module Actor
        class Tick < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::ErrorMonitoring::Runners::ErrorMonitoring
          end

          def runner_function
            'update_error_monitoring'
          end

          def time
            15
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
