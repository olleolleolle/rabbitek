# frozen_string_literal: true

module Rabbitek
  ##
  # Consumer helpers
  module Consumer
    def self.included(base)
      base.extend(ClassMethods)
    end

    attr_reader :channel, :queue, :retry_or_delayed_queue, :retry_or_delayed_exchange

    def initialize(channel, queue, retry_or_delayed_queue, retry_or_delayed_exchange)
      @channel = channel
      @queue = queue
      @retry_or_delayed_queue = retry_or_delayed_queue
      @retry_or_delayed_exchange = retry_or_delayed_exchange
    end

    def ack!(delivery_info, multiple = false)
      channel.ack(delivery_info.delivery_tag, multiple)
    end

    def nack!(delivery_info, multiple = false, requeue = true)
      channel.nack(delivery_info.delivery_tag, multiple, requeue)
    end

    def logger
      Rabbitek.logger
    end

    def parse_payload(payload)
      Utils::Oj.load(payload)
    end

    def perform(_message)
      raise NotImplementedError
    end

    def set_context
      Thread.current[:rabbit_context] = { consumer: self.class.name, queue: @queue.name, job_id: SecureRandom.uuid }
    end

    def jid
      Thread.current[:rabbit_context][:job_id]
    end

    def pop_message_manually
      delivery_info, properties, payload = queue.pop(manual_ack: true)
      return nil unless payload

      Message.new(delivery_info: delivery_info, properties: properties, payload: payload)
    end

    def batch_size
      self.class.batch
    end

    module ClassMethods # rubocop:disable Style/Documentation
      attr_accessor :rabbit_options_hash, :batch

      def rabbit_options(opts)
        self.rabbit_options_hash = default_rabbit_options(opts).with_indifferent_access.merge(opts)
        self.batch = opts[:batch]
      end

      def perform_async(payload, opts: {}, channel: nil)
        publisher = Publisher.new(
          rabbit_options_hash[:bind_exchange],
          exchange_type: rabbit_options_hash[:bind_exchange_type],
          channel: channel
        )
        publish_with_publisher(publisher, payload, opts)
      ensure
        publisher&.close unless channel
      end

      def perform_in(time, payload, opts: {}, channel: nil)
        publisher = Publisher.new(
          Utils::RabbitObjectNames.retry_or_delayed_bind_exchange(rabbit_options_hash[:bind_exchange]),
          exchange_type: :direct,
          channel: channel
        )
        publish_with_publisher(publisher, payload, {
          expiration: time.to_i * 1000, # in milliseconds
          headers: { 'x-dead-letter-routing-key': to_s }
        }.merge(opts))
      ensure
        publisher&.close unless channel
      end

      def perform_at(at_time, payload, opts: {}, channel: nil)
        perform_in(at_time - Time.current, payload, opts: opts, channel: channel)
      end

      def publish_with_publisher(publisher, payload, opts)
        publisher.publish(payload, { routing_key: to_s }.merge(opts))
      end

      private

      def default_rabbit_options(opts)
        YAML.load_file(opts[:config_file]).with_indifferent_access[:parameters]
      end
    end
  end
end
