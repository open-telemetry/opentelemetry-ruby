# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'timeout'

module OpenTelemetry
  module Exporters
    module Datadog
      # Implementation of the duck type SpanProcessor that batches spans
      # exported by the SDK into complete traces then pushes them
      # to the exporter pipeline.
      #
      # All spans reported by the SDK implementation are first added to a
      # synchronized in memory trace storage (with a {max_queue_size}
      # maximum size, of trace size {max_trace_size} after the size of
      # either is reached spans are dropped). When traces are designated
      # as "complete" they're added to a queue that is exported every
      # schedule_delay_millis to the exporter pipeline in batches of
      # completed traces. The datadog writer and transport supplied
      # to the exporter handle the bulk of the timeout and retry logic.
      class DatadogSpanProcessor
        SCHEDULE_DELAY_MILLIS = 3_000
        MAX_QUEUE_SIZE = 2048
        MAX_TRACE_SIZE = 1024
        PROBABILITY_REGEX = /\d[.]\d{1,6}/.freeze
        private_constant(:SCHEDULE_DELAY_MILLIS, :MAX_QUEUE_SIZE, :MAX_TRACE_SIZE)

        def initialize(exporter:,
                       schedule_delay_millis: SCHEDULE_DELAY_MILLIS,
                       max_queue_size: MAX_QUEUE_SIZE,
                       max_trace_size: MAX_TRACE_SIZE)
          raise ArgumentError if max_trace_size > max_queue_size

          @exporter = exporter
          @mutex = Mutex.new
          @condition = ConditionVariable.new
          @keep_running = true
          @delay_seconds = schedule_delay_millis / 1000.0
          @max_queue_size = max_queue_size
          @max_trace_size = max_trace_size
          @spans = []
          @thread = Thread.new { work }

          @traces = {}
          @traces_spans_count = {}
          @traces_spans_ended_count = {}
          @check_traces_queue = []
          @_spans_dropped = false

          # check once for probabilility based sampling rate
          begin
            sampler = OpenTelemetry.tracer_provider.active_trace_config.sampler
          rescue StandardError => e
            OpenTelemetry.logger.warn("sampler configuration not set: #{e.message}")
            sampler = nil
          end

          @probability = get_rate_from_description(sampler)
        end

        # datadog trace-agent endpoint requires a complete trace to be sent
        # threadsafe may block on lock
        def on_start(span)
          context = span.context
          trace_id = context.trace_id

          lock do
            if all_spans_count(traces_spans_count) >= max_queue_size
              # instead of just dropping all new spans, dd-trace-rb drops a random trace
              # https://github.com/DataDog/dd-trace-rb/blob/c6fbf2410a60495f1b2d8912bf7ea7dc63422141/lib/ddtrace/buffer.rb#L34-L36
              # It allows for a more fair usage of the queue when under stress load,
              # and will create proportional representation of code paths being instrumented at stress time.
              unfinished_trace_id = fetch_unfinished_trace_id

              # if there are no unfinished traces able to be dropped, don't add more spans, and return early
              if unfinished_trace_id.nil?
                OpenTelemetry.logger.warn('Max spans for all traces, spans will be dropped')
                @_spans_dropped = true
                return
              end

              drop_unfinished_trace(unfinished_trace_id)
              OpenTelemetry.logger.warn('Max spans for all traces, traces will be dropped')
            end

            if traces[trace_id].nil?
              traces[trace_id] = [span]
              traces_spans_count[trace_id] = 1
            else
              if traces[trace_id].size >= max_trace_size
                OpenTelemetry.logger.warn('Max spans for trace, spans will be dropped')
                @_spans_dropped = true
                return
              end

              traces[trace_id] << span
              traces_spans_count[trace_id] += 1
            end
          end
        end

        # adds a span to the batcher, threadsafe may block on lock
        def on_finish(span)
          if @keep_running == false
            OpenTelemetry.logger.warn('Already shutdown, dropping span')
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

            check_traces_queue.unshift(trace_id) if trace_exportable?(trace_id)
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

        attr_reader :check_traces_queue, :max_queue_size, :max_trace_size, :traces, :traces_spans_count, :traces_spans_ended_count

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
          return if trace_spans.empty?

          is_datadog_exporter = @exporter.is_a?(Datadog::Exporter)

          trace_spans.each do |spans|
            if is_datadog_exporter && @probability
              @exporter.export(spans, @probability)
            else
              @exporter.export(spans)
            end
          rescue StandardError => e
            OpenTelemetry.logger.warn("Exception while exporting Span batch. #{e.message} , #{e.backtrace}")
          end
        end

        def trace_exportable?(trace_id)
          traces_spans_count[trace_id] - traces_spans_ended_count[trace_id] <= 0 if traces_spans_count.key?(trace_id) && traces_spans_ended_count.key?(trace_id)
        end

        def all_spans_count(traces_spans_count)
          traces_spans_count.values.sum
        end

        def fetch_batch
          export_traces = []

          check_traces_queue.reverse_each do |trace_id|
            next unless trace_exportable?(trace_id)

            export_traces << fetch_spans(traces.delete(trace_id))
            check_traces_queue.delete(trace_id)
            traces_spans_count.delete(trace_id)
            traces_spans_ended_count.delete(trace_id)
          end

          export_traces
        end

        def fetch_spans(spans)
          spans.map!(&:to_span_data)
        end

        def fetch_unfinished_trace_id
          # don't delete potentially finished trace awaiting export
          unfinished_traces = traces.keys - check_traces_queue
          unfinished_traces[rand(unfinished_traces.length)]
        end

        def drop_unfinished_trace(trace_id)
          traces.delete(trace_id)
          traces_spans_count.delete(trace_id)
          traces_spans_ended_count.delete(trace_id)
        end

        def get_rate_from_description(sampler)
          # format to parse of sampler description is
          # "ProbabilitySampler{1.000000}" or
          # "AlwaysOnSampler" / "AlwaysOffSampler"
          return nil unless sampler&.is_a?(ProbabilitySampler)

          rate = sampler.description&.match(PROBABILITY_REGEX)

          return nil unless rate

          rate[0].to_f(4)
        rescue StandardError => e
          # rescue just in case the format changes dramatically in the future
          OpenTelemetry.logger.warn("error while extracting sampling rate #{e.message} , #{e.backtrace}")
          nil
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
