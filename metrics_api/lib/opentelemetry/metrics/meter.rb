# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of Meter.
    class Meter
      def create_counter(name, unit: nil, description: nil)
        # TODO
      end

      def create_observable_counter(name, unit: nil, description: nil, callback:)
        # TODO
      end

      def create_histogram(name, unit: nil, description: nil)
        # TODO
      end

      def create_observable_gauge(name, unit: nil, description: nil, callback:)
        # TODO
      end

      def create_up_down_counter(name, unit: nil, description: nil)
        # TODO
      end

      def create_observable_up_down_counter(name, unit: nil, description: nil, callback:)
        # TODO
      end
    end
  end
end
