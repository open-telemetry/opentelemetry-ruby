# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Generates Spans for all interactions with AwsSdk
      class Handler < Seahorse::Client::Handler
        def call(context) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          return super unless context

          service_name = context.client.class.api.metadata['serviceId'] || context.client.class.to_s.split('::')[1]
          operation = context.operation&.name
          attributes = {
            'aws.region' => context.config.region,
            OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
            OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => operation,
            OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_name
          }
          attributes[SemanticConventions::Trace::DB_SYSTEM] = 'dynamodb' if service_name == 'DynamoDB'

          tracer.in_span("#{service_name}.#{operation}", attributes: attributes, kind: OpenTelemetry::Trace::SpanKind::CLIENT) do |span|
            if instrumentation_config[:suppress_internal_instrumentation]
              OpenTelemetry::Common::Utilities.untraced { super }
            else
              super
            end.tap do |response|
              if (err = response.error)
                span.record_exception(err)
                span.status = Trace::Status.error(err)
              end
            end
          end
        end

        private

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
