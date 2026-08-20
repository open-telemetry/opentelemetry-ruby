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
          # Ignores an offered measurement.
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil); end

          # @return [Array] an empty collection of exemplars.
          def collect(attributes: nil, aggregation_temporality: :delta)
            []
          end

          # @return [Boolean] always true for this no-op reservoir.
          def noop?
            true
          end
        end
      end
    end
  end
end
