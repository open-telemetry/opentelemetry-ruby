# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Status represents the status of a finished {Span}. It is composed of a
        # status code in conjunction with an optional descriptive message.
        class AggregationTemporality
          class << self
            private :new

            # Returns a newly created {Status} with code == UNSET and an optional
            # description.
            #
            # @param [String] description
            # @return [Status]
            def delta
              new(DELTA)
            end

            # Returns a newly created {Status} with code == OK and an optional
            # description.
            #
            # @param [String] description
            # @return [Status]
            def cumulative
              new(CUMULATIVE)
            end
          end

          attr_reader :temporality

          # @api private
          # The constructor is private and only for use internally by the class.
          # Users should use the {unset}, {error}, or {ok} factory methods to
          # obtain a {Status} instance.
          #
          # @param [Integer] code One of the status codes below
          # @param [String] description
          def initialize(temporality)
            @temporality = temporality
          end

          def delta?
            @temporality == :delta
          end

          def cumulative?
            @temporality == :cumulative
          end

          # The following represents the set of status codes of a
          # finished {Span}

          # The operation completed successfully.
          DELTA = :delta

          # The default status.
          CUMULATIVE = :cumulative
        end
      end
    end
  end
end
