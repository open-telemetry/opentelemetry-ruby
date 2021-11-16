# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Generates Spans for all interactions with AwsSdk
      class Handler < Seahorse::Client::Handler
        def call(context)
          span_name = get_span_name(context)
          attributes = get_span_attributes(context)

          tracer.in_span(span_name, kind: OpenTelemetry::Trace::SpanKind::CLIENT, attributes: attributes) do |span|
            execute = proc {
              super(context).tap do |response|
                if (err = response.error)
                  span.record_exception(err)
                  span.status = Trace::Status.error(err)
                end
              end
            }

            if instrumentation_config[:suppress_internal_instrumentation]
              OpenTelemetry::Common::Utilities.untraced(&execute)
            else
              execute.call
            end
          end
        end

        def get_span_attributes(context)
          span_attributes = {
            'aws.region' => context.config.region,
            OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
            OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => get_operation(context),
            OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => get_service_name(context)
          }

          db_attributes = DbHelper.get_db_attributes(context, get_service_name(context), get_operation(context))
          span_attributes.merge(db_attributes)
        end

        def get_service_name(context)
          context&.client.class.api.metadata['serviceId'] || context&.client.class.to_s.split('::')[1]
        end

        def get_operation(context)
          context&.operation&.name
        end

        def get_span_name(context)
          "#{get_service_name(context)}.#{get_operation(context)}"
        end

        def tracer
          AwsSdk::Instrumentation.instance.tracer
        end

        def instrumentation_config
          AwsSdk::Instrumentation.instance.config
        end
      end

      # A Seahorse::Client::Plugin that enables instrumentation for all AWS services
      class Plugin < Seahorse::Client::Plugin
        def add_handlers(handlers, config)
          # run before Seahorse::Client::Plugin::ParamValidator (priority 50)
          handlers.add Handler, step: :validate, priority: 49
        end
      end
    end
  end
end
