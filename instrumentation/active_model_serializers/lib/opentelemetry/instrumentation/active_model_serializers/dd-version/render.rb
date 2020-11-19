require 'ddtrace/contrib/active_model_serializers/ext'
require 'ddtrace/contrib/active_model_serializers/event'

module Datadog
  module Contrib
    module ActiveModelSerializers
      module Events
        # Defines instrumentation for render.active_model_serializers event
        module Render
          include ActiveSupport::Notifications::Event

          EVENT_NAME = 'render.active_model_serializers'.freeze

          module_function

          def supported?
            Gem.loaded_specs['active_model_serializers'] \
              && Gem.loaded_specs['active_model_serializers'].version >= Gem::Version.new('0.10')
          end

          def event_name
            self::EVENT_NAME
          end

          def span_name
            'active_model_serializers.render'
          end

          def span_options
            { service: configuration[:service_name] }
          end

          def tracer
            -> { configuration[:tracer] }
          end

          def configuration
            Datadog.configuration[:active_model_serializers]
          end

          def process(span, event, _id, payload)
            span.service = configuration[:service_name]

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
            end

            # Measure service stats
            Contrib::Analytics.set_measured(span)

            # Set the resource name and serializer name
            res = resource(payload[:serializer])
            span.resource = res
            span.set_tag('active_model_serializers.serializer', res)

            span.span_type = Datadog::Ext::HTTP::TEMPLATE

            # Will be nil in 0.9
            # span.set_tag('active_model_serializers.adapter', payload[:adapter].class) unless payload[:adapter].nil?
          end

          private

          def resource(serializer)
            # Depending on the version of ActiveModelSerializers
            # serializer will be a string or an object.
            if serializer.respond_to?(:name)
              serializer.name
            else
              serializer
            end
          end
        end
      end
    end
  end
end
