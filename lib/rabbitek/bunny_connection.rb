# frozen_string_literal: true

module Rabbitek
  ##
  # Bunny connection setup
  class BunnyConnection
    def self.initialize_connection
      connection = Bunny.new(Rabbitek.config.bunny_configuration)
      connection.start
      connection
    end
  end
end
