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
        # Typically, the BatchSpanProcessor will be more suitable for
        # production environments than the SimpleSpanProcessor.
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
          # Returns a new instance of the {BatchSpanProcessor}.
          #
          # @param [SpanExporter] exporter
          # @param [Numeric] exporter_timeout_millis the delay interval between two
          #   consecutive exports. Defaults to the value of the OTEL_BSP_EXPORT_TIMEOUT_MILLIS
          #   environment variable, if set, or 30,000 (30 seconds).
          # @param [Numeric] schedule_delay_millis the maximum allowed time to export data.
          #   Defaults to the value of the OTEL_BSP_SCHEDULE_DELAY_MILLIS environment
          #   variable, if set, or 5,000 (5 seconds).
          # @param [Integer] max_queue_size the maximum queue size in spans.
          #   Defaults to the value of the OTEL_BSP_MAX_QUEUE_SIZE environment
          #   variable, if set, or 2048.
          # @param [Integer] max_export_batch_size the maximum batch size in spans.
          #   Defaults to the value of the OTEL_BSP_MAX_EXPORT_BATCH_SIZE environment
          #   variable, if set, or 512.
          #
          # @return a new instance of the {BatchSpanProcessor}.
          def initialize(exporter:,
                         exporter_timeout_millis: Float(ENV.fetch('OTEL_BSP_EXPORT_TIMEOUT_MILLIS', 30_000)),
                         schedule_delay_millis: Float(ENV.fetch('OTEL_BSP_SCHEDULE_DELAY_MILLIS', 5_000)),
                         max_queue_size: Integer(ENV.fetch('OTEL_BSP_MAX_QUEUE_SIZE', 2048)),
                         max_export_batch_size: Integer(ENV.fetch('OTEL_BSP_MAX_EXPORT_BATCH_SIZE', 512)),
                         start_thread_on_boot: String(ENV['OTEL_RUBY_BSP_START_THREAD_ON_BOOT']) !~ /false/i)
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
            @pid = nil
            @thread = nil
            reset_on_fork(restart_thread: start_thread_on_boot)
          end

          # does nothing for this processor
          def on_start(span, parent_context)
            # noop
          end

          # adds a span to the batcher, threadsafe may block on lock
          def on_finish(span) # rubocop:disable Metrics/AbcSize
            return unless span.context.trace_flags.sampled?

            lock do
              reset_on_fork
              n = spans.size + 1 - max_queue_size
              spans.shift(n) if n.positive?
              spans << span
              @condition.signal if spans.size > batch_size
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
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            start_time = Time.now
            snapshot = lock do
              reset_on_fork(restart_thread: false) if @keep_running
              spans.shift(spans.size)
            end
            until snapshot.empty? || Internal.maybe_timeout(timeout, start_time)&.zero?
              batch = snapshot.shift(@batch_size).map!(&:to_span_data)
              result_code = @exporter.export(batch)
              report_result(result_code, batch)
            end

            # Unshift the remaining spans if we timed out. We drop excess spans from
            # the snapshot because they're older than any spans in the spans buffer.
            lock do
              n = spans.size + snapshot.size - max_queue_size
              snapshot.shift(n) if n.positive?
              spans.unshift(snapshot) unless snapshot.empty?
              @condition.signal if spans.size > max_queue_size / 2
            end

            SUCCESS
          end

          # shuts the consumer thread down and flushes the current accumulated buffer
          # will block until the thread is finished
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            start_time = Time.now
            lock do
              @keep_running = false
              @condition.signal
            end

            @thread.join(timeout)
            force_flush(timeout: Internal.maybe_timeout(timeout, start_time))
            @exporter.shutdown(timeout: Internal.maybe_timeout(timeout, start_time))
          end

          private

          attr_reader :spans, :max_queue_size, :batch_size

          def work
            loop do
              batch = lock do
                reset_on_fork(restart_thread: false)
                @condition.wait(@mutex, @delay_seconds) if spans.size < batch_size && @keep_running
                @condition.wait(@mutex, @delay_seconds) while spans.empty? && @keep_running
                return unless @keep_running

                fetch_batch
              end

              export_batch(batch)
            end
          end

          def reset_on_fork(restart_thread: true)
            pid = Process.pid
            return if @pid == pid

            @pid = pid
            spans.clear
            @thread = Thread.new { work } if restart_thread
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
