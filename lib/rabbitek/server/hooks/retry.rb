# frozen_string_literal: true

require_relative '../server_hook'

module Rabbitek
  module Server
    module Hooks
      ##
      # Hook to retry failed jobs
      class Retry < Rabbitek::ServerHook
        def call(consumer, message)
          super
        rescue StandardError
          Retryer.call(consumer, message)
          raise
        end
      end
    end
  end
end
