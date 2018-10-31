# frozen_string_literal: true

module Rabbitek
  module Utils
    ##
    # Common utilities to create/use RabbitMQ exchange or queue
    class Common
      class << self
        def exchange(channel, exchange_type, exchange_name)
          channel.public_send(exchange_type || 'direct', exchange_name, durable: true, auto_delete: false)
        end

        def queue(channel, name, opts)
          opts ||= {}
          opts = symbolize_keys(opts.to_hash)
          opts[:durable] = true
          opts[:auto_delete] = false

          channel.queue(name, opts)
        end

        private

        def symbolize_keys(hash)
          hash.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v; }
        end
      end
    end
  end
end
