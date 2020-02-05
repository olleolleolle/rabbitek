# frozen_string_literal: true

require 'forwardable'

module Rabbitek
  ##
  # Single message processor
  class MessageProcessor
    include Loggable
    extend Forwardable

    def initialize(starter, delivery_info, properties, payload)
      @starter = starter
      @delivery_info = delivery_info
      @properties = properties
      @payload = payload
    end

    def process
      consumer.set_context

      metrics_add_processed_count

      hook_walker = Utils::HookWalker.new(Rabbitek.config.server_hooks)
      hook_walker.call!(consumer, message) { |*args| run_job(*args) }
    rescue StandardError => e
      on_message_errored(e)
    end

    private

    attr_reader :starter, :delivery_info, :properties, :payload
    def_delegators :starter, :channel, :work_queue, :retry_or_delayed_queue, :retry_or_delayed_exchange

    def run_job(modified_consumer, message)
      if modified_consumer.opts[:batch]
        run_job_batched(modified_consumer, message)
      else
        modified_consumer.perform(message)
        modified_consumer.ack!(message.delivery_info) unless modified_consumer.opts[:manual_ack]
      end
    end

    def run_job_batched(modified_consumer, message)
      Batcher.new(modified_consumer).perform(message) do |batch|
        modified_consumer.perform(batch)
        modified_consumer.ack!(batch.last.delivery_info, true) unless modified_consumer.opts[:manual_ack]
      end
    end

    def on_message_errored(exception)
      error(message: exception.inspect, backtrace: exception.backtrace, consumer: consumer.class, jid: consumer.jid)
      metrics_add_errored_count
    end

    def metrics_add_processed_count
      Yabeda.rabbitek.processed_messages_count.increment(metrics_tags, by: 1)
    end

    def metrics_add_errored_count
      Yabeda.rabbitek.errored_messages_count.increment(metrics_tags, by: 1)
    end

    def message
      @message ||= Message.new(delivery_info: delivery_info, properties: properties, payload: payload)
    end

    def consumer
      @consumer ||= consumer_instance(message.delivery_info.routing_key)
    end

    def consumer_instance(routing_key)
      Thread.current[:worker_classes] ||= {}
      klass = Thread.current[:worker_classes][routing_key] ||= routing_key.constantize
      klass.new(channel, work_queue, retry_or_delayed_queue, retry_or_delayed_exchange)
    rescue NameError
      nil # TODO: to dead queue
    end

    def metrics_tags
      { consumer: consumer.class }
    end
  end
end
