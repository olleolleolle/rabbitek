# frozen_string_literal: true

require 'slop'
require 'yaml'

require_relative './cli/signal_handlers'
require_relative './loggable'

require 'rabbitek'

module Rabbitek
  ##
  # Rabbitek server CLI
  class CLI
    include ::Rabbitek::Loggable

    def run
      opts
      require_application
      map_consumer_workers!

      start_log

      io_r, io_w = IO.pipe
      SignalHandlers.setup(io_w)

      begin
        consumers = boot_consumers

        while io_resp = IO.select([io_r]) # rubocop:disable Lint/AssignmentInCondition
          SignalHandlers.public_send(io_resp.first.first.gets.strip)
        end
      rescue Interrupt
        execute_shutdown(consumers)
      end
    end

    private

    def start_log # rubocop:disable Metrics/AbcSize
      info "Rabbit consumers '[#{configuration[:consumers].map(&:to_s).join(', ')}]' started with PID #{Process.pid}"
      info "Client hooks: [#{Rabbitek.config.client_hooks.map(&:class).join(', ')}]"
      info "Server hooks: [#{Rabbitek.config.server_hooks.map(&:class).join(', ')}]"
    end

    def opts
      @opts ||= Slop.parse do |o|
        o.string '-c', '--config', 'config file path. Default: "config/rabbitek.yaml"', default: 'config/rabbitek.yml'
        o.string '-r', '--require', 'file to require while booting. Default: "config/environment.rb"',
                 default: 'config/environment.rb'
        o.on '--version', 'print the version' do
          puts VERSION
          exit
        end
        o.on '-h', '--help' do
          puts o
          exit
        end
      end
    end

    def configuration
      @configuration ||= YAML.load_file(opts[:config]).with_indifferent_access
    end

    def require_application
      require File.expand_path(opts[:require])
    end

    def map_consumer_workers!
      configuration[:consumers].map!(&:constantize)
    end

    def boot_consumers
      (1..configuration[:threads]).each_with_object([]) do |_, arr|
        arr << Starter.new(Rabbitek.bunny_connection, configuration).start
      end
    end

    def execute_shutdown(consumers)
      info 'Shutting down gracefully...'

      consumers.map(&:cancel)
      Rabbitek.close_bunny_connection
      info 'Graceful shutdown completed'

      exit(0)
    end
  end
end
