# frozen_string_literal: true

module Rabbitek
  ##
  # A model representing message that consumer receives to process
  class Message
    attr_reader :payload, :properties, :delivery_info, :raw_payload

    # @param [Hash] payload
    # @param [Bunny::MessageProperties] properties
    # @param [Bunny::DeliveryInfo] delivery_info
    def initialize(payload:, properties:, delivery_info:)
      @payload = Utils::Oj.load(payload)
      @properties = properties
      @delivery_info = delivery_info

      @raw_payload = payload
    end
  end
end
