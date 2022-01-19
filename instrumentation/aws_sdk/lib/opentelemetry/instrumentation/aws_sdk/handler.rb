# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Generates Spans for all interactions with AwsSdk
      class Handler < Seahorse::Client::Handler
        SQS_SEND_MESSAGE = 'SQS.SendMessage'
        SQS_SEND_MESSAGE_BATCH = 'SQS.SendMessageBatch'
        SQS_RECEIVE_MESSAGE = 'SQS.ReceiveMessage'
        SNS_PUBLISH = 'SNS.Publish'

        def call(context) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return super unless context

          service_name = service_name(context)
          operation = context.operation&.name
          client_method = "#{service_name}.#{operation}"
          attributes = {
            'aws.region' => context.config.region,
            OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
            OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => operation,
            OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_name
          }
          attributes[SemanticConventions::Trace::DB_SYSTEM] = 'dynamodb' if service_name == 'DynamoDB'
          MessagingHelper.apply_sqs_attributes(attributes, context, client_method) if service_name == 'SQS'
          MessagingHelper.apply_sns_attributes(attributes, context, client_method) if service_name == 'SNS'

          tracer.in_span(span_name(context, client_method), attributes: attributes, kind: span_kind(client_method)) do |span|
            inject_context(context, client_method)
            if instrumentation_config[:suppress_internal_instrumentation]
              OpenTelemetry::Common::Utilities.untraced { super }
            else
              super
            end.tap do |response|
              if (err = response.error)
                span.record_exception(err)
                span.status = Trace::Status.error(err.to_s)
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

        def service_name(context) # rubocop:disable Metrics/AbcSize
          # Support aws-sdk v2.0.x, which 'metadata' has a setter method only
          return context.client.class.to_s.split('::')[1] if ::Seahorse::Model::Api.instance_method(:metadata).parameters.length.positive?

          context.client.class.api.metadata['serviceId'] || context.client.class.to_s.split('::')[1]
        end

        SEND_MESSAGE_CLIENT_METHODS = [SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH].freeze
        def inject_context(context, client_method)
          return unless SEND_MESSAGE_CLIENT_METHODS.include? client_method
          return unless instrumentation_config[:inject_messaging_context]

          if client_method == SQS_SEND_MESSAGE_BATCH
            context.params[:entries].each do |entry|
              entry[:message_attributes] ||= {}
              OpenTelemetry.propagation.inject(entry[:message_attributes], setter: MessageAttributeSetter)
            end
          else
            context.params[:message_attributes] ||= {}
            OpenTelemetry.propagation.inject(context.params[:message_attributes], setter: MessageAttributeSetter)
          end
        end

        def span_kind(client_method)
          case client_method
          when SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH
            OpenTelemetry::Trace::SpanKind::PRODUCER
          when SQS_RECEIVE_MESSAGE
            OpenTelemetry::Trace::SpanKind::CONSUMER
          else
            OpenTelemetry::Trace::SpanKind::CLIENT
          end
        end

        def span_name(context, client_method)
          case client_method
          when SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH
            "#{MessagingHelper.queue_name(context)} send"
          when SQS_RECEIVE_MESSAGE
            "#{MessagingHelper.queue_name(context)} receive"
          else
            client_method
          end
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
