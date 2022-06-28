# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class MetricReader
          attr_reader :metric_store

          def initialize
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new
          end

          def collect
            @metric_store.collect
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
