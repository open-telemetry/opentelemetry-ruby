# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class FixedSizeExemplarReservoir < ExemplarReservoir
          MAX_BUCKET_SIZE = 20

          def collect
          end
        end
      end
    end
  end
end
