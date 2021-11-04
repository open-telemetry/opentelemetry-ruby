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
          span_name, attributes = calculate_span(context)

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

        def calculate_span(context)
          service_name = context.client.class.api.metadata['serviceId'] || context.client.class.to_s.split('::')[1]
          span_name = "#{service_name}.#{context.operation.name}"
          attributes = {
            'aws.region' => context.config.region,
            OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
            OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => context.operation.name,
            OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_name
          }

          [span_name, attributes]
        end

        def tracer
          AwsSdk::Instrumentation.instance.tracer
        end

        def instrumentation_config
          AwsSdk::Instrumentation.instance.config
        end
      end
    end
  end
end
