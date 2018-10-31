# frozen_string_literal: true

module Rabbitek
  module Utils
    ##
    # Utility to work down the hooks setup
    class HookWalker
      include Loggable

      def initialize(hooks = [])
        @hooks = hooks.clone
      end

      def call!(*args)
        return yield(*args) unless hooks.any?
        hook = hooks.pop

        debug "Calling hook: #{hook.class}"

        begin
          return_args = hook.call(*args) do |*new_args|
            hooks.any? ? call!(*new_args) { |*next_args| yield(*next_args) } : yield(*new_args)
          end
        ensure
          debug "Finishing hook: #{hook.class}"
        end

        return_args
      end

      private

      attr_reader :hooks
    end
  end
end
