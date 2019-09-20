# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

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
        class BatchSpanProcessor
          SCHEDULE_DELAY_MILLIS = 5000
          MAX_QUEUE_SIZE = 2048
          MAX_EXPORT_BATCH_SIZE = 512

          def initialize(exporter:, schedule_delay: SCHEDULE_DELAY_MILLIS, max_queue_size: MAX_QUEUE_SIZE, max_export_batch_size: MAX_EXPORT_BATCH_SIZE)
            @exporter = exporter
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay = schedule_delay
            @max_queue_size = max_queue_size
            @batch_size = max_export_batch_size
            @spans = []
            @thread = Thread.new { work }
          end

          # does nothing for this processor
          def on_start(span)
            # noop
          end

          # adds a span to the batcher, threadsafe may block on lock
          def on_end(span)
            return unless span.recording_events?

            lock do
              spans.shift if spans.size >= max_queue_size
              spans << span
              @condition.signal if spans.size > max_queue_size / 2
            end
          end

          # shuts the consumer thread down and flushes the current accumulated buffer
          # will block until the thread is finished
          def shutdown
            lock do
              @keep_running = false
              @condition.signal
            end

            @thread.join
          end

          private

          attr_reader :spans, :max_queue_size, :batch_size

          def work
            loop do
              keep_running = nil
              batch = lock do
                if spans.size < max_queue_size
                  @condition.wait(@mutex, @delay) while spans.empty? && @keep_running
                  keep_running = @keep_running
                end
                fetch_batch
              end
              # this is done outside the lock to unblock the producers
              @exporter.export(batch)
              break unless keep_running
            end
            flush
          end

          def flush
            until spans.empty?
              batch = lock { fetch_batch }
              @exporter.export(batch)
            end
          end

          def fetch_batch
            spans.shift(@batch_size).map!(&:to_span_proto)
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
