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

          def collect
            @metric_store.collect
          end

          # @api private
          def metric_store=(metric_store)
            if defined?(:@metric_store) && !@metric_store.nil?
              OpenTelemetry.handle_error(message: 'repeated attempts to set metric_store on metric reader')
            else
              @metric_store = metric_store
            end
          end

          def shutdown(timeout: nil)
            SUCCESS
          end

          def force_flush(timeout: nil)
            SUCCESS
          end
        end
      end
    end
  end
end
