# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # MessagingHelper class provides methods for calculating messaging span attributes
      class MessagingHelper
        class << self
          def destination_name(context)
            topic_arn = context.params[:topic_arn]
            target_arn = context.params[:target_arn]

            if topic_arn || target_arn
              arn = topic_arn || target_arn
              return arn.split(':')[-1]
            end

            phone_number = context.params[:phone_number]
            return 'phone_number' if phone_number

            queue_url = context.params[:queue_url]
            return queue_url.split('/')[-1] if queue_url

            'unknown'
          end

          def apply_sqs_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sqs'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'queue'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = destination_name(context)
            attributes[SemanticConventions::Trace::MESSAGING_URL] = context.params[:queue_url]

            attributes[SemanticConventions::Trace::MESSAGING_OPERATION] = 'receive' if client_method == 'SQS.ReceiveMessage'
          end

          def apply_sns_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sns'

            return unless client_method == 'SNS.Publish'

            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'topic'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = destination_name(context)
          end

          def create_sqs_processing_spans(context, tracer, messages)
            queue_name = destination_name(context)
            messages.each do |message|
              attributes = {
                SemanticConventions::Trace::MESSAGING_SYSTEM => 'aws.sqs',
                SemanticConventions::Trace::MESSAGING_DESTINATION => queue_name,
                SemanticConventions::Trace::MESSAGING_DESTINATION_KIND => 'queue',
                SemanticConventions::Trace::MESSAGING_MESSAGE_ID => message.message_id,
                SemanticConventions::Trace::MESSAGING_URL => context.params[:queue_url],
                SemanticConventions::Trace::MESSAGING_OPERATION => 'process'
              }
              tracer.in_span("#{queue_name} process", attributes: attributes, links: extract_links(message), kind: :consumer) {}
            end
          end

          def extract_links(sqs_message)
            extracted_context = OpenTelemetry.propagation.extract(sqs_message.message_attributes, context: Context::ROOT, getter: MessageAttributeGetter)
            span_context = OpenTelemetry::Trace.current_span(extracted_context).context

            span_context.valid? ? [OpenTelemetry::Trace::Link.new(span_context)] : []
          end
        end
      end
    end
  end
end
