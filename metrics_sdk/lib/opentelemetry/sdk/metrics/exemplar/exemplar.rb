# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class Exemplar
          attr_reader :value, :time_unix_nano, :attributes, :span_id, :trace_id

          def initialize(value, time_unix_nano, attributes, span_id, trace_id)
            @value = value
            @time_unix_nano = time_unix_nano
            @attributes = attributes
            @span_id  = span_id
            @trace_id = trace_id
          end
        end
      end
    end
  end
end
