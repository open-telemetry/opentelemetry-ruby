# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'thread'

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # Implementation of the duck type SpanProcessor that batches spans
        # exported by the SDK then pushes them to the exporter pipeline.
        #
        # All spans reported by the SDK implementation are first added to a
        # synchronized queue (with a {max_queue_size} maximum size, after the
        # size is reached spans are dropped) and exported every
        # {schedule_delay_millis} to the exporter pipeline in batches of
        # {max_export_batch_size}.
        #
        # If the queue gets half full a preemptive notification is sent to the
        # worker thread that exports the spans to wake up and start a new
        # export cycle.
        class BatchSampledSpanProcessor
          SCHEDULE_DELAY_MILLIS = 5000
          MAX_QUEUE_SIZE = 2048
          MAX_EXPORT_BATCH_SIZE = 512

          def initialize(exporter:, schedule_delay: SCHEDULE_DELAY_MILLIS, max_queue_size: MAX_QUEUE_SIZE, max_export_batch_size: MAX_EXPORT_BATCH_SIZE)
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay = schedule_delay
            @max_queue_size = max_queue_size
            @batch_size = max_batch_size
            @spans = []
            @thread = Thread.new do
              work
            end
          end

          def on_end(span)
            lock do
              spans.shift if spans.size >= max_queue_size
              spans << span
              @condition.signal if spans.size > queue_size/2
              spans.shift
            end
          end

          def shutdown
            lock do
              return unless @keep_running
              @keep_running = false
              @condition.signal
            end
          end

          private

          def max_queue_size
            @max_queue_size
          end

          def spans
            @spans
          end

          def work
            lock do
              while @keep_running
                if  spans.size < max_queue_size
                  loop do
                    @condition.wait(@delay)
                    break unless spans.empty?
                  end
                end
                export_batches
              end

              flush
            end
          end

          def export_batches
          end

          def max(a, b)
            a > b ? a : b
          end

          def lock
            @mutex.synchronize do
              yield
            end
          end
        end
      end
    end
  end
end
