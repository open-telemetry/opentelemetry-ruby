# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class ExemplarReservoir

          def initialize(value, timestamp, attributes, context)
            @value      = value
            @timestamp  = timestamp
            @attributes = attributes
            @context    = context
          end

          def offer; end

          # return Exemplar
          def collect; end
        end
      end
    end
  end
end
