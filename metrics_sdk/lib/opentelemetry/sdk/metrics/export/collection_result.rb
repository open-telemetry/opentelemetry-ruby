# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # CollectionResult is returned by {MetricReader#collect_with_result}. It pairs
        # the collected {State::MetricData} with a status code so callers can tell a
        # successful but empty collection apart from a failed or timed out one.
        #
        # @!attribute [r] metrics
        #   @return [Array<State::MetricData>] the collected metrics. Empty when the
        #     collection failed.
        # @!attribute [r] status
        #   @return [Integer] {SUCCESS}, {FAILURE} or {TIMEOUT}.
        CollectionResult = Struct.new(:metrics, :status) do
          # @return [Boolean] true if the collection finished successfully.
          def success?
            status == SUCCESS
          end

          # @return [Boolean] true if the collection finished with an error.
          def failure?
            status == FAILURE
          end

          # @return [Boolean] true if the collection exceeded its timeout.
          def timeout?
            status == TIMEOUT
          end
        end
      end
    end
  end
end
