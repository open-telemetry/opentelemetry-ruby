# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # DbHelper class provides methods for calculating aws db span attributes
      class DbHelper
        class << self
          def get_db_attributes(context, service_name, operation)
            return get_dynamodb_attributes(context, operation) if service_name == 'DynamoDB'

            {}
          end

          def get_dynamodb_attributes(context, operation)
            {
              SemanticConventions::Trace::DB_SYSTEM => 'dynamodb'
            }
          end
        end
      end
    end
  end
end
