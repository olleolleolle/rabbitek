# frozen_string_literal: true

module Rabbitek
  class CLI
    ##
    # OS signal handlers
    class SignalHandlers
      SIGNALS = {
        INT: :shutdown,
        TERM: :shutdown
      }.freeze

      def self.setup(io_w)
        SIGNALS.each do |signal, hook|
          Signal.trap(signal) { io_w.write("#{hook}\n") }
        end
      end

      def self.shutdown
        raise Interrupt
      end
    end
  end
end
