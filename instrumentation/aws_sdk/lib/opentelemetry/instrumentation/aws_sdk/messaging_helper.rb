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
            topic_arn = context.metadata[:original_params][:topic_arn]
            target_arn = context.metadata[:original_params][:target_arn]
            phone_number = context.metadata[:original_params][:phone_number]
            queue_url = context.metadata[:original_params][:queue_url]

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
        end
      end
    end
  end
end
