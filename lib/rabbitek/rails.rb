# frozen_string_literal: true

module Rabbitek
  ##
  # Rails extensions
  class Rails < ::Rails::Engine
    include Loggable

    config.before_configuration do
      if ::Rails::VERSION::MAJOR < 5 && defined?(::ActiveRecord)
        info 'Adding Rabbitek::Server::Hooks::ActiveRecordConnectionReset hook'

        Rabbitek.configure do |c|
          c.add_server_hook(Rabbitek::Server::Hooks::ActiveRecordConnectionReset.new, 0)
        end
      end
    end

    config.after_initialize do
      if ::Rails::VERSION::MAJOR >= 5
        info 'Using Rails code reloader'

        Rabbitek.configure { |c| c.reloader = RailsReloader.new }
      end
    end

    ##
    # Implementation of reloader for Rails
    class RailsReloader
      def initialize
        @app = ::Rails.application
      end

      def call
        @app.reloader.wrap { yield }
      end

      def inspect
        "#<Rabbitek::Rails::RailsReloader @app=#{@app.class.name}>"
      end
    end
  end
end
