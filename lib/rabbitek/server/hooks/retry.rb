# frozen_string_literal: true

require_relative '../server_hook'

module Rabbitek
  module Server
    module Hooks
      ##
      # Hook to retry failed jobs
      class Retry < Rabbitek::ServerHook
        include Loggable

        def call(consumer, message)
          super
        rescue StandardError
          retry_message(consumer, message) unless consumer.opts[:batch]
          raise
        end

        private

        def retry_message(consumer, message)
          Retryer.call(consumer, message)
        rescue StandardError => e
          error(
            message: 'Critical error while retrying. Nacking and requeueing message',
            consumer: message.delivery_info.routing_key,
            jid: consumer.jid,
            error: e.to_s
          )

          consumer.nack!(message.delivery_info)
        end
      end
    end
  end
end
