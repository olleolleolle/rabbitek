# frozen_string_literal: true

module Rabbitek
  ##
  # A service to group messages from queue by batches.
  class Batcher
    def initialize(consumer, batch_size)
      @consumer = consumer
      @batch_size = batch_size
      @batch = []
    end

    def perform(payload, delivery_info, properties)
      add_message_to_batch(payload, delivery_info, properties)
      yield(@batch)
    rescue StandardError
      retry_all_messages
      raise
    end

    private

    def add_message_to_batch(payload, delivery_info, properties)
      @batch << { payload: payload, delivery_info: delivery_info, properties: properties }
      return if @batch.size >= @batch_size # stop collecting batch when maximum batch size has been reached

      delivery_info, properties, new_payload = @consumer.queue.pop(manual_ack: true)
      return unless new_payload # stop collecting batch when there is no more messages waiting

      payload = Utils::Oj.load(new_payload) # as messages in queue are serialized, we need to parse them
      add_message_to_batch(payload, delivery_info, properties)
    end

    def retry_all_messages
      @batch.each do |message|
        Rabbitek::Retryer.call(
          @consumer, Utils::Oj.dump(message[:payload]), message[:delivery_info], message[:properties]
        )
      end
    end
  end
end
