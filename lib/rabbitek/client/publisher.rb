# frozen_string_literal: true

module Rabbitek
  ##
  # Handles publishing message to RabbitMQ
  class Publisher
    def initialize(exchange_name, exchange_type: 'direct', channel: nil)
      @channel = channel || Rabbitek.create_channel
      @exchange_name = exchange_name
      @exchange_type = exchange_type
    end

    def publish(payload, params = {})
      Utils::HookWalker.new(Rabbitek.config.client_hooks).call!(payload, params) do |parsed_payload, parsed_params|
        exchange.publish(Utils::Oj.dump(parsed_payload), parsed_params)
      end
    end

    def close
      @channel.close
    end

    def exchange
      @exchange ||= Utils::Common.exchange(@channel, @exchange_type, @exchange_name)
    end
  end
end
