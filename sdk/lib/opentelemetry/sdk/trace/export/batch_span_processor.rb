# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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
        # Typically, the BatchSpanProcessor will be more suitable for
        # production environments than the SimpleSpanProcessor.
        #
        # All spans reported by the SDK implementation are first added to a
        # synchronized queue (with a {max_queue_size} maximum size, after the
        # size is reached spans are dropped) and exported every
        # schedule_delay to the exporter pipeline in batches of
        # max_export_batch_size.
        #
        # If the queue gets half full a preemptive notification is sent to the
        # worker thread that exports the spans to wake up and start a new
        # export cycle.
        class BatchSpanProcessor # rubocop:disable Metrics/ClassLength
          # Returns a new instance of the {BatchSpanProcessor}.
          #
          # @param [SpanExporter] exporter the (duck type) SpanExporter to where the
          #   recorded Spans are pushed after batching.
          # @param [Numeric] exporter_timeout the delay interval between two
          #   consecutive exports. Defaults to the value of the OTEL_BSP_EXPORT_TIMEOUT
          #   environment variable, if set, or 30,000 (30 seconds).
          # @param [Numeric] schedule_delay the maximum allowed time to export data.
          #   Defaults to the value of the OTEL_BSP_SCHEDULE_DELAY environment
          #   variable, if set, or 5,000 (5 seconds).
          # @param [Integer] max_queue_size the maximum queue size in spans.
          #   Defaults to the value of the OTEL_BSP_MAX_QUEUE_SIZE environment
          #   variable, if set, or 2048.
          # @param [Integer] max_export_batch_size the maximum batch size in spans.
          #   Defaults to the value of the OTEL_BSP_MAX_EXPORT_BATCH_SIZE environment
          #   variable, if set, or 512.
          #
          # @return a new instance of the {BatchSpanProcessor}.
          def initialize(exporter,
                         exporter_timeout: Float(ENV.fetch('OTEL_BSP_EXPORT_TIMEOUT', 30_000)),
                         schedule_delay: Float(ENV.fetch('OTEL_BSP_SCHEDULE_DELAY', 5_000)),
                         max_queue_size: Integer(ENV.fetch('OTEL_BSP_MAX_QUEUE_SIZE', 2048)),
                         max_export_batch_size: Integer(ENV.fetch('OTEL_BSP_MAX_EXPORT_BATCH_SIZE', 512)),
                         start_thread_on_boot: String(ENV['OTEL_RUBY_BSP_START_THREAD_ON_BOOT']) !~ /false/i,
                         metrics_reporter: nil)
            raise ArgumentError if max_export_batch_size > max_queue_size

            @exporter = exporter
            @exporter_timeout_seconds = exporter_timeout / 1000.0
            @mutex = Mutex.new
            @export_mutex = Mutex.new
            @condition = ConditionVariable.new
            @keep_running = true
            @delay_seconds = schedule_delay / 1000.0
            @max_queue_size = max_queue_size
            @batch_size = max_export_batch_size
            @metrics_reporter = metrics_reporter || OpenTelemetry::SDK::Trace::Export::MetricsReporter
            @spans = []
            @pid = nil
            @thread = nil
            reset_on_fork(restart_thread: start_thread_on_boot)
          end

          # Does nothing for this processor
          def on_start(_span, _parent_context); end

          # Adds a span to the batch. Thread-safe; may block on lock.
          def on_finish(span) # rubocop:disable Metrics/AbcSize
            return unless span.context.trace_flags.sampled?

            lock do
              reset_on_fork
              n = spans.size + 1 - max_queue_size
              if n.positive?
                spans.shift(n)
                report_dropped_spans(n, reason: 'buffer-full')
              end
              spans << span
              @condition.signal if spans.size > batch_size
            end
          end

          # Export all ended spans to the configured `Exporter` that have not yet
          # been exported.
          #
          # This method should only be called in cases where it is absolutely
          # necessary, such as when using some FaaS providers that may suspend
          # the process after an invocation, but before the `Processor` exports
          # the completed spans.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
            start_time = Time.now
            snapshot = lock do
              reset_on_fork if @keep_running
              spans.shift(spans.size)
            end
            until snapshot.empty?
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              batch = snapshot.shift(@batch_size).map!(&:to_span_data)
              result_code = export_batch(batch, timeout: remaining_timeout)
              return result_code unless result_code == SUCCESS
            end

            @exporter.force_flush(timeout: OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time))
          ensure
            # Unshift the remaining spans if we timed out. We drop excess spans from
            # the snapshot because they're older than any spans in the spans buffer.
            lock do
              n = spans.size + snapshot.size - max_queue_size
              if n.positive?
                snapshot.shift(n)
                report_dropped_spans(n, reason: 'buffer-full')
              end
              spans.unshift(snapshot) unless snapshot.empty?
              @condition.signal if spans.size > max_queue_size / 2
            end
          end

          # Shuts the consumer thread down and flushes the current accumulated buffer
          # will block until the thread is finished.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            start_time = Time.now
            thread = lock do
              @keep_running = false
              @condition.signal
              @thread
            end

            thread&.join(timeout)
            force_flush(timeout: OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time))
            @exporter.shutdown(timeout: OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time))
            dropped_spans = lock { spans.size }
            report_dropped_spans(dropped_spans, reason: 'terminating') if dropped_spans.positive?
          end

          private

          attr_reader :spans, :max_queue_size, :batch_size

          def work # rubocop:disable Metrics/AbcSize
            loop do
              batch = lock do
                @condition.wait(@mutex, @delay_seconds) if spans.size < batch_size && @keep_running
                @condition.wait(@mutex, @delay_seconds) while spans.empty? && @keep_running
                return unless @keep_running

                fetch_batch
              end

              @metrics_reporter.observe_value('otel.bsp.buffer_utilization', value: spans.size / max_queue_size.to_f)

              export_batch(batch)
            end
          end

          def reset_on_fork(restart_thread: true)
            pid = Process.pid
            return if @pid == pid

            @pid = pid
            spans.clear
            @thread = restart_thread ? Thread.new { work } : nil
          rescue ThreadError => e
            @metrics_reporter.add_to_counter('otel.bsp.error', labels: { 'reason' => 'ThreadError' })
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error in BatchSpanProcessor#reset_on_fork')
          end

          def export_batch(batch, timeout: @exporter_timeout_seconds)
            result_code = @export_mutex.synchronize { @exporter.export(batch, timeout: timeout) }
            report_result(result_code, batch)
            result_code
          end

          def report_result(result_code, batch)
            if result_code == SUCCESS
              @metrics_reporter.add_to_counter('otel.bsp.export.success')
              @metrics_reporter.add_to_counter('otel.bsp.exported_spans', increment: batch.size)
            else
              OpenTelemetry.handle_error(message: "Unable to export #{batch.size} spans")
              @metrics_reporter.add_to_counter('otel.bsp.export.failure')
              report_dropped_spans(batch.size, reason: 'export-failure')
            end
          end

          def report_dropped_spans(count, reason:)
            @metrics_reporter.add_to_counter('otel.bsp.dropped_spans', increment: count, labels: { 'reason' => reason })
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
