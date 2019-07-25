# frozen_string_literal: true

require_relative '../server_hook'

module Rabbitek
  module Server
    module Hooks
      ##
      # Active record connection reset to maintain correct connection state
      # Used only in Rails < 5
      class ActiveRecordConnectionReset < Rabbitek::ServerHook
        def initialize
          raise ArgumentError, 'Use AR connection reset only in Rails < 5!' unless should_allow_hook?
        end

        def call(consumer, message)
          ::ActiveRecord::Base.establish_connection unless ::ActiveRecord::Base.connection.active?

          super
        ensure
          ::ActiveRecord::Base.clear_active_connections!
        end

        private

        def should_allow_hook?
          defined?(::Rails) && ::Rails::VERSION::MAJOR < 5
        end
      end
    end
  end
end
