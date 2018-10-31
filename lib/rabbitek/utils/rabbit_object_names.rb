# frozen_string_literal: true

module Rabbitek
  module Utils
    ##
    # Names builder for exchanges, queues, etc.
    class RabbitObjectNames
      class << self
        def retry_or_delayed_bind_exchange(bind_exchange)
          "#{bind_exchange}.rabbitek.__rod__"
        end

        def retry_or_delayed_queue(queue_name)
          "#{queue_name}.rabbitek.__rod__"
        end
      end
    end
  end
end
