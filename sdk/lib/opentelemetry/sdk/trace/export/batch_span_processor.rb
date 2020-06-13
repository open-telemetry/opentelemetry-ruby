# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'timeout'

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
        class BatchSpanProcessor
          EXPORTER_TIMEOUT_MILLIS = 30_000
          SCHEDULE_DELAY_MILLIS = 5_000
          MAX_QUEUE_SIZE = 2048
          MAX_EXPORT_BATCH_SIZE = 512
          private_constant(:SCHEDULE_DELAY_MILLIS, :MAX_QUEUE_SIZE, :MAX_EXPORT_BATCH_SIZE)

          def initialize(exporter:,
                         exporter_timeout_millis: EXPORTER_TIMEOUT_MILLIS,
                         schedule_delay_millis: SCHEDULE_DELAY_MILLIS,
                         max_queue_size: MAX_QUEUE_SIZE,
                         max_export_batch_size: MAX_EXPORT_BATCH_SIZE)
            raise ArgumentError if max_export_batch_size > max_queue_size

            @exporter = exporter
            @exporter_timeout_seconds = exporter_timeout_millis / 1000.0
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay_seconds = schedule_delay_millis / 1000.0
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
          def on_finish(span) # rubocop:disable Metrics/AbcSize
            return unless span.context.trace_flags.sampled?

            lock do
              n = spans.size + 1 - max_queue_size
              spans.shift(n) if n.positive?
              spans << span
              @condition.signal if spans.size > max_queue_size / 2
            end
          end

          # TODO: test this explicitly.
          # Export all ended spans to the configured `Exporter` that have not yet
          # been exported.
          #
          # This method should only be called in cases where it is absolutely
          # necessary, such as when using some FaaS providers that may suspend
          # the process after an invocation, but before the `Processor` exports
          # the completed spans.
          def force_flush
            snapshot = lock { spans.shift(spans.size) }
            until snapshot.empty?
              batch = snapshot.shift(@batch_size).map!(&:to_span_data)
              result_code = @exporter.export(batch)
              report_result(result_code, batch)
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
            force_flush
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

              export_batch(batch)
            end
          end

          def export_batch(batch)
            result_code = export_with_timeout(batch)
            report_result(result_code, batch)
          end

          def export_with_timeout(batch)
            Timeout.timeout(@exporter_timeout_seconds) { @exporter.export(batch) }
          rescue Timeout::Error
            FAILURE
          end

          def report_result(result_code, batch)
            OpenTelemetry.logger.error("Unable to export #{batch.size} spans") unless result_code == SUCCESS
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
