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
        Rabbitek.reloader.call do
          MessageProcessor.new(self, delivery_info, properties, payload).process
        end
      end
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
        :direct,
        Utils::RabbitObjectNames.retry_or_delayed_bind_exchange(opts[:bind_exchange])
      )
    end

    private

    attr_reader :connection, :queue_name, :consumers, :opts

    def setup_bindings!
      consumers.each do |worker_class|
        work_queue.bind(work_exchange, routing_key: worker_class.to_s)
        retry_or_delayed_queue.bind(retry_or_delayed_exchange, routing_key: worker_class.to_s)
      end
    end
  end
end
