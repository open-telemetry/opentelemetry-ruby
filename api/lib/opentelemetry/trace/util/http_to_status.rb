# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Util
      # Convenience methods, not necessarily required by the API specification.
      module HttpToStatus
        # Implemented according to
        # https://github.com/open-telemetry/opentelemetry-specification/issues/306
        # https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#status
        #
        # @param code Numeric HTTP status
        # @return Status
        def http_to_status(code) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
          case code.to_i
          when 100..399
            new(const_get(:OK))
          when 401
            new(const_get(:UNAUTHENTICATED))
          when 403
            new(const_get(:PERMISSION_DENIED))
          when 404
            new(const_get(:NOT_FOUND))
          when 429
            new(const_get(:RESOURCE_EXHAUSTED))
          when 400..499
            new(const_get(:INVALID_ARGUMENT))
          when 501
            new(const_get(:UNIMPLEMENTED))
          when 503
            new(const_get(:UNAVAILABLE))
          when 504
            new(const_get(:DEADLINE_EXCEEDED))
          when 500..599
            new(const_get(:INTERNAL_ERROR))
          else
            new(const_get(:UNKNOWN_ERROR))
          end
        end
      end
    end
  end
end
