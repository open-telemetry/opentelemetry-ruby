# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'timeout'

module OpenTelemetry
  module Exporters
    module Datadog
      
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
      class DatadogSpanProcessor
        EXPORTER_TIMEOUT_MILLIS = 30_000
        SCHEDULE_DELAY_MILLIS = 3_000
        MAX_QUEUE_SIZE = 2048
        MAX_EXPORT_BATCH_SIZE = 512
        MAX_EXPORT_ATTEMPTS = 5
        private_constant(:SCHEDULE_DELAY_MILLIS, :MAX_QUEUE_SIZE, :MAX_EXPORT_BATCH_SIZE, :MAX_EXPORT_ATTEMPTS)

        def initialize(exporter:,
                       exporter_timeout_millis: EXPORTER_TIMEOUT_MILLIS,
                       schedule_delay_millis: SCHEDULE_DELAY_MILLIS,
                       max_queue_size: MAX_QUEUE_SIZE,
                       max_export_batch_size: MAX_EXPORT_BATCH_SIZE,
                       max_export_attempts: MAX_EXPORT_ATTEMPTS)
          raise ArgumentError if max_export_batch_size > max_queue_size

          @exporter = exporter
          @exporter_timeout_seconds = exporter_timeout_millis / 1000.0
          @mutex = Mutex.new
          @condition = ConditionVariable.new
          @keep_running = true
          @delay_seconds = schedule_delay_millis / 1000.0
          @max_queue_size = max_queue_size
          @batch_size = max_export_batch_size
          @export_attempts = max_export_attempts
          @spans = []
          @thread = Thread.new { work }

          @traces = {}
          @traces_spans_count = {}
          @traces_spans_ended_count = {}
          @check_traces_queue = []
          @_spans_dropped = false
        end

        # datadog trace-agent endpoint requires a complete trace to be sent
        # threadsafe may block on lock
        def on_start(span)
          context = span.context
          trace_id = context.trace_id

          lock do
            if all_spans_count(traces_spans_count) == max_queue_size
              OpenTelemetry.logger.warn("Max spans for trace, spans will be dropped")
              @_spans_dropped = true
              return
            end

            if traces[trace_id].nil?
              traces[trace_id] = [span]
              traces_spans_count[trace_id] = 1
            else
              traces[trace_id] << span
              traces_spans_count[trace_id] += 1
            end
          end
        end

        # adds a span to the batcher, threadsafe may block on lock
        def on_finish(span) # rubocop:disable Metrics/AbcSize
          if @keep_running == false
            OpenTelemetry.logger.warn("Already shutdown, dropping span")
            return
          end

          # TODO: determine if all "not-sampled" spans still get passed to on_finish?
          # If so then we don't need to account for Probability Sampling
          # and can likely incorporate Priority Sampling from DD
          # If not, then we need to ensure the rate from OpenTelemetry.tracer_provider.active_trace_config.sampler
          # can be expoed to the span or attached to spanData in some way
          # return unless span.context.trace_flags.sampled?

          context = span.context
          trace_id = context.trace_id

          lock do
            if traces_spans_ended_count[trace_id].nil?
              traces_spans_ended_count[trace_id] = 1
            else
              traces_spans_ended_count[trace_id] += 1
            end

            if is_trace_exportable?(trace_id)
              check_traces_queue.unshift(trace_id)
            end
          end
        end

        # TODO: test this explicitly.
        # Export all ended traces to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        def force_flush
          snapshot = lock { fetch_batch }
          export_batch(snapshot)
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

        attr_reader :check_traces_queue, :max_queue_size, :traces, :traces_spans_count, :traces_spans_ended_count

        def work
          while @keep_running
            trace_spans = lock do
              @condition.wait(@mutex, @delay_seconds) if @keep_running
              @condition.wait(@mutex, @delay_seconds) while check_traces_queue.empty? && @keep_running
              return unless @keep_running

              fetch_batch
            end

            export_batch(trace_spans)
          end
        end

        def export_batch(trace_spans)
          if trace_spans.length > 0
            trace_spans.each do |spans|
              begin
                @exporter.export(spans)
              rescue Exception => e
                OpenTelemetry.logger.warn("Exception while exporting Span batch. #{e.message} , #{e.backtrace}")
              end
            end
          end
        end

        def is_trace_exportable?(trace_id)
          traces_spans_count[trace_id] - traces_spans_ended_count[trace_id] <= 0
        end

        def all_spans_count(traces_spans_count)
          traces_spans_count.values.sum
        end

        def fetch_batch
          export_traces = []

          check_traces_queue.reverse_each do |trace_id|
            if is_trace_exportable?(trace_id)                    
              export_traces << fetch_spans(traces.delete(trace_id))
              check_traces_queue.delete(trace_id)
              traces_spans_count.delete(trace_id)
              traces_spans_ended_count.delete(trace_id)                 
            end
          end

          export_traces
        end

        def fetch_spans(spans)
          spans.map!(&:to_span_data)
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