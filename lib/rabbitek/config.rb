# frozen_string_literal: true

module Rabbitek
  ##
  # Rabbitek configuration
  class Config
    DEFAULTS = {
      bunny_configuration: { hosts: 'localhost:5672', vhost: '/' },
      log_format: 'json',
      enable_newrelic: true,
      enable_sentry: true,
      logger: Logger.new(STDOUT),
      reloader: proc { |&block| block.call }
    }.freeze

    attr_accessor(*DEFAULTS.keys)

    def initialize
      DEFAULTS.each { |k, v| public_send("#{k}=", v) }

      @client_hooks_config = []
      @server_hooks_config = []
    end

    def add_client_hook(hook_object, position = @client_hooks_config.size)
      @client_hooks_config.insert(position, hook_object)
    end

    def add_server_hook(hook_object, position = @server_hooks_config.size)
      @server_hooks_config.insert(position, hook_object)
    end

    def client_hooks
      @client_hooks ||= begin
        @client_hooks_config << Client::Hooks::OpenTracing.new
        @client_hooks_config.reverse
      end
    end

    def server_hooks
      @server_hooks ||= begin
        @server_hooks_config.unshift(Server::Hooks::TimeTracker.new)
        @server_hooks_config.push(Server::Hooks::OpenTracing.new, Server::Hooks::Retry.new)
        @server_hooks_config.reverse
      end
    end
  end
end
