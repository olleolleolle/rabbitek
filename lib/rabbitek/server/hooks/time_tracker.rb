# frozen_string_literal: true

require_relative '../server_hook'

module Rabbitek
  module Server
    module Hooks
      ##
      # Hook to keep track of time used for processing single job
      class TimeTracker < Rabbitek::ServerHook
        include Loggable

        def call(consumer, message)
          info(message: 'Starting', consumer: message.delivery_info.routing_key, jid: consumer.jid)

          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          super
        ensure
          info(
            message: 'Finished',
            consumer: message.delivery_info.routing_key,
            time: Process.clock_gettime(Process::CLOCK_MONOTONIC) - start,
            jid: consumer.jid
          )
        end
      end
    end
  end
end
