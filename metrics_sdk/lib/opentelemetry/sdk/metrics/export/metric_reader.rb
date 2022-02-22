# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class MetricReader
          def initialize(exporter)
            @exporter = exporter
          end

          def collect; end

          def shutdown(timeout: nil)
            SUCCESS
          end
        end
      end
    end
  end
end

