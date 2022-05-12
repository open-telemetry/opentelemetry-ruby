# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class ConsoleMetricExporter
          PREFERRED_TEMPORALITY = 'delta'

          def export(metrics)
            puts metrics
          end

          def shutdown
            SUCCESS
          end

          def preferred_temporality
            PREFERRED_TEMPORALITY
          end
        end
      end
    end
  end
end

