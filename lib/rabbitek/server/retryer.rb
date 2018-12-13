# frozen_string_literal: true

module Rabbitek
  ##
  # A service to retry a failed message consuming
  class Retryer
    include Loggable

    def self.call(*args)
      new(*args).call
    end

    def initialize(consumer, message)
      @consumer = consumer
      @message = message

      headers = message.properties.headers || {}
      dead_headers = headers.fetch('x-death', []).last || {}

      @retry_count = headers.fetch('x-retry-count', 0)
      @expiration = dead_headers.fetch('original-expiration', 1000).to_i
    end

    def call
      warn_log

      # acknowledge existing message
      @consumer.ack!(@message.delivery_info)

      if @retry_count <= 25
        # Set the new expiration with an increasing factor
        @expiration *= 1.5

        # Publish to retry queue with new expiration
        publish_to_retry_queue
      else
        publish_to_dead_queue
      end
    end

    def warn_log
      warn(
        message: 'Failure!',
        retry_count: @retry_count,
        expiration: @expiration,
        consumer: @consumer.class.to_s,
        jid: @consumer.jid
      )
    end

    def publish_to_retry_queue
      @consumer.retry_or_delayed_exchange.publish(
        @message.raw_payload,
        expiration: @expiration.to_i,
        routing_key: @message.delivery_info.routing_key,
        headers: { 'x-retry-count': @retry_count + 1, 'x-dead-letter-routing-key': @message.delivery_info.routing_key }
      )
    end

    def publish_to_dead_queue
      # TODO: implement dead queue
    end
  end
end
