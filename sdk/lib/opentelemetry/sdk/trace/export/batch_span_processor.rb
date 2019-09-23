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
        # {SCHEDULE_DELAY_MILLIS} to the exporter pipeline in batches of
        # {MAX_EXPORT_BATCH_SIZE}.
        #
        # If the queue gets half full a preemptive notification is sent to the
        # worker thread that exports the spans to wake up and start a new
        # export cycle.
        #
        # Exports failed with {FAILED_RETRYABLE} will be retried, backing off
        # linearly up to {MAX_EXPORT_RETRY_ATTEMPTS} in 100ms increments.
        class BatchSpanProcessor
          SCHEDULE_DELAY_MILLIS = 5000
          MAX_QUEUE_SIZE = 2048
          MAX_EXPORT_BATCH_SIZE = 512
          MAX_EXPORT_RETRY_ATTEMPTS = 5

          def initialize(exporter:, schedule_delay: SCHEDULE_DELAY_MILLIS, max_queue_size: MAX_QUEUE_SIZE, max_export_batch_size: MAX_EXPORT_BATCH_SIZE, max_export_retry_attempts: MAX_EXPORT_RETRY_ATTEMPTS)
            raise(ArgumentError) if max_export_batch_size > max_queue_size

            @exporter = exporter
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay = schedule_delay
            @max_queue_size = max_queue_size
            @batch_size = max_export_batch_size
            @export_retry_attempts = max_export_retry_attempts
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
            @exporter.shutdown
          end

          private

          attr_reader :spans, :max_queue_size, :batch_size

          # rubocop:disable CyclomaticComplexity
          def work
            loop do
              batch = lock do
                # rubocop:disable IfUnlessModifier
                if spans.size < batch_size
                  @condition.wait(@mutex, @delay) while spans.empty? && @keep_running
                end
                # rubocop:enable IfUnlessModifier
                break unless @keep_running

                fetch_batch
              end

              if batch
                # this is done outside the lock to unblock the producers
                export_batch(batch)
              end
              break unless @keep_running
            end
            flush
          end
          # rubocop:enable CyclomaticComplexity

          def export_batch(batch)
            retries = 1
            result_code = @exporter.export(batch)
            while result_code == FAILED_RETRYABLE && retries < @export_retry_attempts
              sleep(0.1 * retries)
              result_code = @exporter.export(batch)
              retries += 1
            end
          end

          def flush
            snapshot = lock { spans.shift(spans.size) }
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
