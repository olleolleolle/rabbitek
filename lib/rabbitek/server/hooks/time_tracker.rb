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
          log_started(consumer, message)

          start = current_time

          super
        ensure
          total_time = current_time - start

          log_finished(consumer, message, total_time)
          metrics_measure_time(consumer, total_time)
        end

        private

        def current_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def log_started(consumer, message)
          info(message: 'Starting job', consumer: message.delivery_info.routing_key, jid: consumer.jid)
        end

        def log_finished(consumer, message, total_time)
          info(
            message: 'Finished job',
            consumer: message.delivery_info.routing_key,
            time: total_time,
            jid: consumer.jid
          )
        end

        def metrics_measure_time(consumer, total_time)
          Yabeda.rabbitek.processed_messages_runtime.measure({ consumer: consumer.class }, total_time)
        end
      end
    end
  end
end
