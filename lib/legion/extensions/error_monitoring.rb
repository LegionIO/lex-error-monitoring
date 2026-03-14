# frozen_string_literal: true

require 'legion/extensions/error_monitoring/version'
require 'legion/extensions/error_monitoring/helpers/constants'
require 'legion/extensions/error_monitoring/helpers/error_signal'
require 'legion/extensions/error_monitoring/helpers/error_monitor'
require 'legion/extensions/error_monitoring/runners/error_monitoring'
require 'legion/extensions/error_monitoring/client'

module Legion
  module Extensions
    module ErrorMonitoring
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
