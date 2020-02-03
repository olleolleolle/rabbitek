# frozen_string_literal: true

module Rabbitek
  ##
  # A service to group messages from queue by batches.
  class Batcher
    def initialize(consumer)
      @consumer = consumer
      @batch_size = consumer.opts[:batch][:of]
      @batch = []
    end

    def perform(message)
      collect_batch(message)
      yield(@batch)
    rescue StandardError
      retry_all_messages
      raise
    end

    private

    def collect_batch(message)
      loop do
        @batch << message
        break if @batch.size >= @batch_size # stop collecting batch when maximum batch size has been reached

        message = @consumer.pop_message_manually
        break unless message # stop collecting batch when there are no more messages waiting
      end
    end

    def retry_all_messages
      @batch.each { |message| Rabbitek::Retryer.call(@consumer, message) }
    end
  end
end
