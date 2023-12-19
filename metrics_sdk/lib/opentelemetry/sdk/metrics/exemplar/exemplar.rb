# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class Exemplar
          def initialize(value, time_unix_nano, attributes)
            @value = value
            @time_unix_nano = time_unix_nano
            @attributes = attributes
            @span_id  = nil
            @trace_id = nil
          end
        end
      end
    end
  end
end
