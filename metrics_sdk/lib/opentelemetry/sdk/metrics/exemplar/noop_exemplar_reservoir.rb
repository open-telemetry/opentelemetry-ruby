# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class NoopExemplarReservoir < ExemplarReservoir
          def initialize; end

          def offer(value: nil, timestamp: nil, attributes: nil, context: nil); end

          def collect(attributes: nil, aggregation_temporality: :delta)
            Array.new
          end
        end
      end
    end
  end
end
