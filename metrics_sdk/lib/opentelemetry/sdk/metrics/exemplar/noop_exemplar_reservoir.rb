# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # NoopExemplarReservoir
        class NoopExemplarReservoir < ExemplarReservoir
          # No-op: discards the offered measurement.
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil); end

          # Always returns an empty exemplar list.
          def collect(attributes: nil, aggregation_temporality: :delta)
            []
          end

          # Returns true; this reservoir never stores exemplars.
          def noop?
            true
          end
        end
      end
    end
  end
end
