# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class ConsoleMetricExporter
          def export(metrics)
            puts metrics
          end

          def shutdown
            SUCCESS
          end
        end
      end
    end
  end
end
