# frozen_string_literal: true

module Rabbitek
  ##
  # Base server hook class
  class ServerHook
    def call(consumer, delivery_info, properties, payload)
      yield(consumer, delivery_info, properties, payload)
    end
  end
end
