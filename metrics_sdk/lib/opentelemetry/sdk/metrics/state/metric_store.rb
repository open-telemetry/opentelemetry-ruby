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
            @epoch_start_time = Time.now.to_i
            @epoch_end_time = nil;
            @metric_streams = []
          end

          def collect
            # this probably needs to take the mutex, take a snapshot of state, (reset state?), release the mutex
            @mutex.synchronize do
              [
                @end_time = Time.now.to_i,
                @metric_streams,
                @epoch_start_time = @end_time,
              ]
              @metric_streams
            end
          end

          def add_metric_stream(metric_stream)
            @metric_streams = @metric_streams.dup.push(metric_stream)
            nil
          end
        end
      end
    end
  end
end
