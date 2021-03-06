# frozen_string_literal: true

require_relative '../server_hook'

module Rabbitek
  module Server
    module Hooks
      ##
      # OpenTracing server hook
      class OpenTracing < Rabbitek::ServerHook
        def call(consumer, message)
          response = nil

          ::OpenTracing.start_active_span(
            message.delivery_info.routing_key, opts(message.delivery_info, message.properties)
          ) do |scope|
            response = super
          rescue StandardError => e
            Utils::OpenTracing.log_error(scope.span, e)
            raise
          end

          response
        end

        private

        def opts(delivery_info, properties)
          Utils::OpenTracing.server_options(delivery_info, properties)
        end
      end
    end
  end
end
