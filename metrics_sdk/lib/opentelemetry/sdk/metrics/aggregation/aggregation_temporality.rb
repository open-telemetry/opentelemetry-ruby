# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # AggregationTemporality represents the temporality of
        # data point ({NumberDataPoint} and {HistogramDataPoint}) in {Metrics}.
        # It determine whether the data point will be cleared for each metrics pull/export.
        class AggregationTemporality
          class << self
            private :new

            # Returns a newly created {AggregationTemporality} with temporality == DELTA
            #
            # @return [AggregationTemporality]
            def delta
              new(DELTA)
            end

            # Returns a newly created {AggregationTemporality} with temporality == CUMULATIVE
            #
            # @return [AggregationTemporality]
            def cumulative
              new(CUMULATIVE)
            end
          end

          attr_reader :temporality

          # @api private
          # The constructor is private and only for use internally by the class.
          # Users should use the {delta} and {cumulative} factory methods to obtain
          # a {AggregationTemporality} instance.
          #
          # @param [Integer] temporality One of the status codes below
          def initialize(temporality)
            @temporality = temporality
          end

          def delta?
            @temporality == :delta
          end

          def cumulative?
            @temporality == :cumulative
          end

          # delta: data point will be cleared after each metrics pull/export.
          DELTA = :delta

          # cumulative: data point will NOT be cleared after metrics pull/export.
          CUMULATIVE = :cumulative
        end
      end
    end
  end
end
