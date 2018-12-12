# frozen_string_literal: true

module SpecHelpers
  def message_double(payload)
    instance_double(
      Rabbitek::Message,
      payload: payload,
      raw_payload: Oj.dump(payload),
      delivery_info: instance_double(Bunny::DeliveryInfo),
      properties: instance_double(Bunny::MessageProperties)
    )
  end
end
