# frozen_string_literal: true

module Rabbitek
  ##
  # A service to retry a failed message consuming
  class Retryer
    include Loggable

    def self.call(*args)
      new.call(*args)
    end

    def call(consumer, payload, delivery_info, properties)
      headers = properties.headers || {}
      dead_headers = headers.fetch('x-death', []).last || {}

      retry_count = headers.fetch('x-retry-count', 0)
      expiration = dead_headers.fetch('original-expiration', 1000).to_i

      warn_log(retry_count, expiration, consumer)

      # acknowledge existing message
      consumer.ack!(delivery_info)

      if retry_count <= 25
        # Set the new expiration with an increasing factor
        new_expiration = expiration * 1.5

        # Publish to retry queue with new expiration
        publish_to_retry_queue(consumer, new_expiration, delivery_info, payload, retry_count)
      else
        publish_to_dead_queue
      end
    end

    def warn_log(retry_count, expiration, consumer)
      warn(
        message: 'Failure!',
        retry_count: retry_count,
        expiration: expiration,
        consumer: consumer.class.to_s,
        jid: consumer.jid
      )
    end

    def publish_to_retry_queue(consumer, new_expiration, delivery_info, payload, retry_count)
      consumer.retry_or_delayed_exchange.publish(
        payload,
        expiration: new_expiration.to_i,
        routing_key: delivery_info.routing_key,
        headers: { 'x-retry-count': retry_count + 1, 'x-dead-letter-routing-key': delivery_info.routing_key }
      )
    end

    def publish_to_dead_queue
      # TODO: implement dead queue
    end
  end
end
