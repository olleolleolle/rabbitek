# frozen_string_literal: true

module Rabbitek
  ##
  # Main server startup
  class Starter
    include Loggable

    def initialize(connection, configuration)
      @connection = connection
      @queue_name = configuration[:parameters][:queue]
      @consumers = configuration[:consumers]
      @opts = configuration[:parameters]
    end

    def start
      setup_bindings!

      work_queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
        on_message_received(delivery_info, properties, payload)
      end
    end

    private

    attr_reader :connection, :queue_name, :consumers, :opts

    def setup_bindings!
      consumers.each do |worker_class|
        work_queue.bind(work_exchange, routing_key: worker_class.to_s)
      end
      retry_or_delayed_queue.bind(retry_or_delayed_exchange)
    end

    def on_message_received(delivery_info, properties, payload)
      consumer = consumer_instance(delivery_info.routing_key)
      consumer.set_context

      hook_walker = Utils::HookWalker.new(Rabbitek.config.server_hooks)

      hook_walker.call!(consumer, delivery_info, properties, payload) do |*args|
        run_job(*args)
      end
    end

    def run_job(consumer, delivery_info, properties, payload)
      consumer.perform(consumer.parse_message(payload), delivery_info, properties)
    rescue StandardError => e
      error(message: e.inspect, backtrace: e.backtrace, consumer: consumer.class, jid: consumer.jid)
    end

    def consumer_instance(routing_key)
      Thread.current[:worker_classes] ||= {}
      klass = Thread.current[:worker_classes][routing_key] ||= routing_key.constantize
      klass.new(channel, work_queue, retry_or_delayed_queue, retry_or_delayed_exchange)
    rescue NameError
      nil # TODO: to dead queue
    end

    def channel
      @channel ||= begin
        channel = connection.create_channel
        channel.basic_qos(opts[:basic_qos]) if opts[:basic_qos].present?
        channel
      end
    end

    def work_exchange
      @work_exchange ||= Utils::Common.exchange(channel, 'direct', opts[:bind_exchange])
    end

    def work_queue
      @work_queue ||= Utils::Common.queue(channel, queue_name, opts[:queue_attributes])
    end

    def retry_or_delayed_queue
      @retry_or_delayed_queue ||= Utils::Common.queue(
        channel,
        Utils::RabbitObjectNames.retry_or_delayed_queue(opts[:queue]),
        arguments: { 'x-dead-letter-exchange': opts[:bind_exchange] }
      )
    end

    def retry_or_delayed_exchange
      @retry_or_delayed_exchange ||= Utils::Common.exchange(
        channel,
        :fanout,
        Utils::RabbitObjectNames.retry_or_delayed_bind_exchange(opts[:bind_exchange])
      )
    end
  end
end
