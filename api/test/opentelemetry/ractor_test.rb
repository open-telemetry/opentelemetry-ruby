# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'OpenTelemetry API in a non-main Ractor' do
  before do
    @default_logger = OpenTelemetry.logger
    @default_error_handler = OpenTelemetry.error_handler

    skip 'Ractors are not supported on this Ruby' unless defined?(Ractor)
  end

  after do
    OpenTelemetry.logger = @default_logger
    OpenTelemetry.error_handler = @default_error_handler
    OpenTelemetry.propagation = nil
  end

  # A non-main Ractor raises Ractor::IsolationError when it reads a constant that holds an unshareable object.
  def in_ractor(&)
    ractor = Ractor.new(&)
    ractor.respond_to?(:value) ? ractor.value : ractor.take
  end

  it 'starts and activates no-op spans' do
    result = in_ractor do
      tracer = OpenTelemetry::Trace::Tracer.new
      root_span = tracer.start_root_span('root')
      tracer.in_span('child') do |span|
        [root_span.context.valid?, span.context.valid?, OpenTelemetry::Trace.current_span.equal?(span)]
      end
    end

    _(result).must_equal([false, false, true])
  end

  it 'injects and extracts trace context and baggage' do
    result = in_ractor do
      span_context = OpenTelemetry::Trace::SpanContext.new(trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED)
      context = OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(span_context))
      context = OpenTelemetry::Baggage.set_value('key', 'value', context: context)
      propagators = [
        OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator,
        OpenTelemetry::Baggage::Propagation.text_map_propagator
      ]

      carrier = {}
      propagators.each { |propagator| propagator.inject(carrier, context: context) }
      extracted = propagators.reduce(OpenTelemetry::Context.empty) do |extracted_context, propagator|
        propagator.extract(carrier, context: extracted_context)
      end

      extracted_span_context = OpenTelemetry::Trace.current_span(extracted).context
      [
        extracted_span_context.hex_trace_id == span_context.hex_trace_id,
        extracted_span_context.trace_flags.sampled?,
        OpenTelemetry::Baggage.value('key', context: extracted)
      ]
    end

    _(result).must_equal([true, true, 'value'])
  end

  it 'traces with a no-op tracer from the global tracer provider' do
    result = in_ractor do
      OpenTelemetry.tracer_provider.tracer('name', 'version').in_span('span') { |span| span.context.valid? }
    end

    _(result).must_equal(false)
  end

  it 'propagates with the default propagator' do
    result = in_ractor do
      carrier = {}
      OpenTelemetry.propagation.inject(carrier)
      [carrier, OpenTelemetry.propagation.extract(carrier).equal?(OpenTelemetry::Context.current)]
    end

    _(result).must_equal([{}, true])
  end

  it 'propagates with a registered composite of shareable propagators' do
    OpenTelemetry.propagation = OpenTelemetry::Context::Propagation::CompositeTextMapPropagator.compose_propagators(
      [OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator, OpenTelemetry::Baggage::Propagation.text_map_propagator]
    )

    _(in_ractor { OpenTelemetry.propagation.fields }).must_equal(%w[traceparent tracestate baggage])
  end

  it 'propagates with a registered composite of shareable injectors and extractors' do
    OpenTelemetry.propagation = OpenTelemetry::Context::Propagation::CompositeTextMapPropagator.compose(
      injectors: [OpenTelemetry::Baggage::Propagation.text_map_propagator],
      extractors: [OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator]
    )

    _(in_ractor { OpenTelemetry.propagation.fields }).must_equal(%w[baggage])
  end

  it 'propagates with the default propagator if the registered one is not shareable' do
    OpenTelemetry.propagation = OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new

    _(in_ractor { OpenTelemetry.propagation.fields }).must_equal([])
  end

  it 'handles errors with the default error handler and the registered logger if it is shareable' do
    # Modules are shareable. This one records the messages in the Ractor that logs them.
    OpenTelemetry.logger = Module.new do
      def self.error(message)
        (Ractor.current[:logged] ||= []) << message
      end
    end
    OpenTelemetry.error_handler = ->(**) { raise 'not shareable' }

    result = in_ractor do
      OpenTelemetry.handle_error(message: 'message')
      Ractor.current[:logged]
    end

    _(result).must_equal(['OpenTelemetry error: message'])
  end

  it 'logs with a logger of its own if the registered one is not shareable' do
    OpenTelemetry.logger = Logger.new(File::NULL)

    _(in_ractor { [OpenTelemetry.logger.class, OpenTelemetry.logger.equal?(OpenTelemetry.logger)] }).must_equal([Logger, true])
  end
end
