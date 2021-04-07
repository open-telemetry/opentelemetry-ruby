# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'tempfile'

describe OpenTelemetry do
  describe '.tracer_provider' do
    after do
      # Ensure we don't leak custom tracer factories and tracers to other tests
      OpenTelemetry.tracer_provider = nil
    end

    it 'returns instance of Trace::TracerProvider by default' do
      tracer_provider = OpenTelemetry.tracer_provider
      _(tracer_provider).must_be_instance_of(OpenTelemetry::Trace::TracerProvider)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.tracer_provider).must_equal(OpenTelemetry.tracer_provider)
    end

    it 'returns user specified tracer provider' do
      custom_tracer_provider = 'a custom tracer provider'
      OpenTelemetry.tracer_provider = custom_tracer_provider
      _(OpenTelemetry.tracer_provider).must_equal(custom_tracer_provider)
    end
  end

  describe '.handle_error' do
    after do
      # Ensure we don't leak custom loggers and error handlers to other tests
      OpenTelemetry.logger = nil
      OpenTelemetry.error_handler = nil
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

  describe '.baggage' do
    after do
      # Ensure we don't leak custom baggage to other tests
      OpenTelemetry.baggage = nil
    end

    it 'returns Baggage::NoopManager by default' do
      manager = OpenTelemetry.baggage
      _(manager).must_be_instance_of(OpenTelemetry::Baggage::NoopManager)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.baggage).must_equal(
        OpenTelemetry.baggage
      )
    end

    it 'returns user specified baggage' do
      custom_manager = 'a custom baggage'
      OpenTelemetry.baggage = custom_manager
      _(OpenTelemetry.baggage).must_equal(custom_manager)
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
