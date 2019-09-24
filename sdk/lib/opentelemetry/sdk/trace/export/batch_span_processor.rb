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
        # schedule_delay_millis to the exporter pipeline in batches of
        # max_export_batch_size.
        #
        # If the queue gets half full a preemptive notification is sent to the
        # worker thread that exports the spans to wake up and start a new
        # export cycle.
        #
        # max_export_attempts attempts are made to export each batch, while
        # export fails with {FAILED_RETRYABLE}, backing off linearly in 100ms
        # increments.
        class BatchSpanProcessor
          SCHEDULE_DELAY_MILLIS = 5
          MAX_QUEUE_SIZE = 2048
          MAX_EXPORT_BATCH_SIZE = 512
          MAX_EXPORT_ATTEMPTS = 5
          private_constant(:SCHEDULE_DELAY_MILLIS, :MAX_QUEUE_SIZE, :MAX_EXPORT_BATCH_SIZE, :MAX_EXPORT_ATTEMPTS)

          def initialize(exporter:,
                         schedule_delay_millis: SCHEDULE_DELAY_MILLIS,
                         max_queue_size: MAX_QUEUE_SIZE,
                         max_export_batch_size: MAX_EXPORT_BATCH_SIZE,
                         max_export_attempts: MAX_EXPORT_ATTEMPTS)
            raise ArgumentError if max_export_batch_size > max_queue_size

            @exporter = exporter
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay_seconds = schedule_delay_millis / 1000.0
            @max_queue_size = max_queue_size
            @batch_size = max_export_batch_size
            @export_attempts = max_export_attempts
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
              n = spans.size + 1 - max_queue_size
              spans.shift(n) if n.positive?
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
            flush
            @exporter.shutdown
          end

          private

          attr_reader :spans, :max_queue_size, :batch_size

          def work
            loop do
              batch = lock do
                @condition.wait(@mutex, @delay_seconds) if spans.size < batch_size && @keep_running
                @condition.wait(@mutex, @delay_seconds) while spans.empty? && @keep_running
                return unless @keep_running

                fetch_batch
              end

              export_batch(batch) # TODO: log or count errors
            end
          end

          def export_batch(batch)
            @export_attempts.times do |retries|
              result_code = @exporter.export(batch)
              return result_code unless result_code == FAILED_RETRYABLE

              sleep(0.1 * retries)
            end
            FAILED_RETRYABLE
          end

          def flush
            snapshot = lock { spans.shift(spans.size) }
            # TODO: should this call export_batch or just blindly attempt to export and ignore failures?
            @exporter.export(snapshot.shift(@batch_size).map!(&:to_span_data)) until snapshot.empty?
          end

          def fetch_batch
            spans.shift(@batch_size).map!(&:to_span_data)
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
