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
          def queue_name(context)
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
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = queue_name(context)
            attributes[SemanticConventions::Trace::MESSAGING_URL] = context.params[:queue_url]

            attributes[SemanticConventions::Trace::MESSAGING_OPERATION] = 'receive' if client_method == 'SQS.ReceiveMessage'
          end

          def apply_sns_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sns'

            return unless client_method == 'SNS.Publish'

            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'topic'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = queue_name(context)
          end
        end
      end
    end
  end
end
