# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class AlwaysOffExemplarFilter < ExemplarFilter
          def should_sample?(value, timestamp, attributes, context)
            false
          end
        end
      end
    end
  end
end
