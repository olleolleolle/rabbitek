# frozen_string_literal: true

module Rabbitek
  ##
  # Base server hook class
  class ServerHook
    def call(consumer, message)
      yield(consumer, message)
    end
  end
end
