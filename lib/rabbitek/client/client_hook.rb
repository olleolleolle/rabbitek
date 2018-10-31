# frozen_string_literal: true

module Rabbitek
  ##
  # Base client hook class
  class ClientHook
    def call(payload, params)
      yield(payload, params)
    end
  end
end
