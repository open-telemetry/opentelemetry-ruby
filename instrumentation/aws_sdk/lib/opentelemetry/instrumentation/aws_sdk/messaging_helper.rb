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
          def queue_name(context) # rubocop:disable Metrics/CyclomaticComplexity
            topic_arn = params(context, :topic_arn)
            target_arn = params(context, :target_arn)
            phone_number = params(context, :phone_number)
            queue_url = params(context, :queue_url)

            if topic_arn || target_arn
              arn = topic_arn || target_arn
              begin
                return arn.split(':')[-1]
              rescue StandardError
                return arn
              end
            end

            return phone_number if phone_number

            return queue_url.split('/')[-1] if queue_url

            'unknown'
          end

          def apply_sqs_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sqs'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'queue'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = queue_name(context)
            attributes[SemanticConventions::Trace::MESSAGING_URL] = params(context, :queue_url)

            attributes[SemanticConventions::Trace::MESSAGING_OPERATION] = 'receive' if client_method == 'SQS.ReceiveMessage'
          end

          def apply_sns_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sns'

            return unless client_method == 'SNS.Publish'

            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'topic'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = queue_name(context)
          end

          def params(context, param)
            defined?(context.metadata[:original_params][param]) ? context.metadata[:original_params][param] : context.params[param]
          end
        end
      end
    end
  end
end
