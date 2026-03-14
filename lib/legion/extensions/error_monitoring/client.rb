# frozen_string_literal: true

require 'legion/extensions/error_monitoring/helpers/constants'
require 'legion/extensions/error_monitoring/helpers/error_signal'
require 'legion/extensions/error_monitoring/helpers/error_monitor'
require 'legion/extensions/error_monitoring/runners/error_monitoring'

module Legion
  module Extensions
    module ErrorMonitoring
      class Client
        include Runners::ErrorMonitoring

        def initialize(monitor: nil, **)
          @monitor = monitor || Helpers::ErrorMonitor.new
        end

        private

        attr_reader :monitor
      end
    end
  end
end
