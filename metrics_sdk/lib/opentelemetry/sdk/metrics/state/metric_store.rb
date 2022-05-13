# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module State
        class MetricStore
          def initialize
            @mutex = Mutex.new
            # @epoch_start_time = now
            @metric_streams = {}
          end

          def collect
            # this probably needs to take the mutex, take a snapshot of state, (reset state?), release the mutex
            # end_time = now
            @metric_streams.map do |_k, metric_stream|
              metric_stream
            end
            # @epoch_start_time = end_time
          end

          def record(measurement, instrument, resource)
            # compute metric stream name
            # find or create the metric stream
            # run aggregation on the metric stream

            # need to block on lookup or creation
            # if aggregation is quick hold the lock?
            # otherwise we want to release the lock for the lookup/creation
            # and takeup a lock on the aggregator

            metric_stream = @mutex.synchronize do
              @metric_streams[instrument.to_s] || @metric_streams[instrument.to_s] = MetricStream.new(instrument, resource)
            end

            metric_stream.update(measurement)
          end
        end
      end
    end
  end
end
