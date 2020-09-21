# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Util
      # Convenience methods, not necessarily required by the API specification.
      module HttpToStatus
        # Maps numeric HTTP status codes to Trace::Status. This module is a mixin for Trace::Status
        # and is not intended for standalone use.
        #
        # @param code Numeric HTTP status
        # @return Status
        def http_to_status(code)
          case code.to_i
          when 100..399
            new(const_get(:OK))
          else
            new(const_get(:ERROR))
          end
        end
      end
    end
  end
end
