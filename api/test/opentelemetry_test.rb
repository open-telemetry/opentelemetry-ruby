# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'tempfile'

describe OpenTelemetry do
  class CustomSpan < OpenTelemetry::Trace::Span
  end

  class CustomTracer < OpenTelemetry::Trace::Tracer
    def start_root_span(*)
      CustomSpan.new
    end
  end

  class CustomTracerProvider < OpenTelemetry::Trace::TracerProvider
    def tracer(name = nil, version = nil)
      CustomTracer.new
    end
  end

  describe '.tracer_provider' do
    after do
      # Ensure we don't leak custom tracer factories and tracers to other tests
      OpenTelemetry.tracer_provider = OpenTelemetry::Internal::ProxyTracerProvider.new
    end

    it 'returns a Trace::TracerProvider by default' do
      tracer_provider = OpenTelemetry.tracer_provider
      _(tracer_provider).must_be_kind_of(OpenTelemetry::Trace::TracerProvider)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.tracer_provider).must_equal(OpenTelemetry.tracer_provider)
    end

    it 'returns user specified tracer provider' do
      custom_tracer_provider = CustomTracerProvider.new
      OpenTelemetry.tracer_provider = custom_tracer_provider
      _(OpenTelemetry.tracer_provider).must_equal(custom_tracer_provider)
    end
  end

  describe '.tracer_provider=' do
    after do
      # Ensure we don't leak custom tracer factories and tracers to other tests
      OpenTelemetry.tracer_provider = OpenTelemetry::Internal::ProxyTracerProvider.new
    end

    it 'upgrades default tracers to "real" tracers' do
      default_tracer = OpenTelemetry.tracer_provider.tracer
      _(default_tracer.start_root_span('root')).must_be_instance_of(OpenTelemetry::Trace::Span)
      OpenTelemetry.tracer_provider = CustomTracerProvider.new
      _(default_tracer.start_root_span('root')).must_be_instance_of(CustomSpan)
    end

    it 'upgrades the default tracer provider to a "real" tracer provider' do
      default_tracer_provider = OpenTelemetry.tracer_provider
      OpenTelemetry.tracer_provider = CustomTracerProvider.new
      _(default_tracer_provider.tracer).must_be_instance_of(CustomTracer)
    end
  end

  describe '.handle_error' do
    before do
      @default_logger = OpenTelemetry.logger
      @default_error_handler = OpenTelemetry.error_handler
    end

    after do
      # Ensure we don't leak custom loggers and error handlers to other tests
      OpenTelemetry.logger = @default_logger
      OpenTelemetry.error_handler = @default_error_handler
    end

    it 'logs at error level by default' do
      logger = Struct.new(:messages) do
        def error(message)
          messages << message
        end
      end
      OpenTelemetry.logger = logger.new([])

      OpenTelemetry.handle_error(message: 'foo')
      begin
        raise 'hell'
      rescue StandardError => e
        OpenTelemetry.handle_error(exception: e)
      end
      begin
        raise 'bar'
      rescue StandardError => e
        OpenTelemetry.handle_error(exception: e, message: 'hi')
      end
      _(OpenTelemetry.logger.messages).must_equal ['OpenTelemetry error: foo', 'OpenTelemetry error: hell', 'OpenTelemetry error: hi - bar']
    end

    it 'calls user specified error handler' do
      received_exception = nil
      received_message = nil
      custom_error_handler = lambda do |exception: nil, message: nil|
        received_exception = exception
        received_message = message
      end
      OpenTelemetry.error_handler = custom_error_handler
      OpenTelemetry.handle_error(exception: 1, message: 2)
      _(received_exception).must_equal 1
      _(received_message).must_equal 2
    end
  end

  describe '.logger' do
    it 'should log things' do
      t = Tempfile.new('logger')
      begin
        OpenTelemetry.logger = Logger.new(t.path)
        OpenTelemetry.logger.info('stuff')
        t.rewind
        _(t.read).must_match(/INFO -- : stuff/)
      ensure
        t.unlink
      end
    end
  end

  describe '.propagation' do
    it 'returns instance of Context::Propagation::NoopTextMapPropagator by default' do
      _(OpenTelemetry.propagation).must_be_instance_of(
        OpenTelemetry::Context::Propagation::NoopTextMapPropagator
      )
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.propagation).must_equal(
        OpenTelemetry.propagation
      )
    end
  end
end
