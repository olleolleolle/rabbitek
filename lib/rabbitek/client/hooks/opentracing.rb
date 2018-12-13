# frozen_string_literal: true

require_relative '../client_hook'

module Rabbitek
  module Client
    module Hooks
      ##
      # OpenTracing client hook
      class OpenTracing < Rabbitek::ClientHook
        def call(payload, params)
          result = nil

          ::OpenTracing.start_active_span(params[:routing_key], opentracing_options(params)) do |scope|
            params[:headers] ||= {}
            Utils::OpenTracing.inject!(scope.span, params[:headers])

            result = super
          rescue StandardError => e
            raise unless scope.span

            Utils::OpenTracing.log_error(scope.span, e)
            raise
          end

          result
        end

        def opentracing_options(params)
          Utils::OpenTracing.client_options(params)
        end
      end
    end
  end
end
