# frozen_string_literal: true

module Rabbitek
  module Utils
    ##
    # OpenTracing helpers
    class OpenTracing
      OPENTRACING_COMPONENT = 'rabbitek'
      OPENTRACING_KIND_SERVER = 'server'
      OPENTRACING_KIND_CLIENT = 'client'

      class << self
        def inject!(span, carrier)
          ::OpenTracing.inject(span.context, ::OpenTracing::FORMAT_TEXT_MAP, carrier)
        end

        def client_options(params)
          {
            tags: {
              'component' => OPENTRACING_COMPONENT,
              'span.kind' => OPENTRACING_KIND_CLIENT,
              'rabbitmq.routing_key' => params[:routing_key]
            }
          }
        end

        def server_options(delivery_info, properties)
          references = server_references(properties)

          options = {
            tags: {
              'component' => OPENTRACING_COMPONENT,
              'span.kind' => OPENTRACING_KIND_SERVER,
              'rabbitmq.routing_key' => delivery_info.routing_key,
              'rabbitmq.jid' => Thread.current[:rabbit_context][:jid],
              'rabbitmq.queue' => Thread.current[:rabbit_context][:queue],
              'rabbitmq.worker' => Thread.current[:rabbit_context][:consumer]
            }
          }

          options[:references] = [references] if references
          options
        end

        def log_error(span, err)
          span.set_tag('error', true)
          span.log_kv(
            event: 'error',
            'error.kind': err.class.to_s,
            'error.object': err,
            message: err.message
          )
        end

        private

        def server_references(message_properties)
          ctx = extract(message_properties)
          return unless ctx

          ::OpenTracing::Reference.follows_from(ctx)
        end

        def extract(message_properties)
          ::OpenTracing.extract(::OpenTracing::FORMAT_TEXT_MAP, message_properties.headers)
        end
      end
    end
  end
end
