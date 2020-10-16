# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
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

  describe '.tracer' do
    let(:mock_provider) { MiniTest::Mock.new }

    after do
      # Ensure we don't leak custom tracer factories and tracers to other tests
      OpenTelemetry.tracer_provider = nil
    end

    describe 'default tracer' do
      it 'returns the same instance when accessed multiple times' do
        _(OpenTelemetry.tracer).must_equal(OpenTelemetry.tracer)
      end
    end

    describe 'delegation' do
      before do
        OpenTelemetry.tracer_provider = mock_provider
      end

      it 'delegates to tracer provider' do
        mock_provider.expect(:tracer, Object.new, [nil, nil])
        _ = OpenTelemetry.tracer
        mock_provider.verify
      end

      it 'delegates to tracer provider with provided name' do
        mock_provider.expect(:tracer, Object.new, ['foo', nil])
        _ = OpenTelemetry.tracer('foo')
        mock_provider.verify
      end

      it 'delegates to tracer provider with provided name and version' do
        mock_provider.expect(:tracer, Object.new, ['foo', '0.4.0'])
        _ = OpenTelemetry.tracer('foo', '0.4.0')
        mock_provider.verify
      end
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

  describe '.meter_provider' do
    after do
      # Ensure we don't leak custom meter factories and meters to other tests
      OpenTelemetry.meter_provider = nil
    end

    it 'returns instance of Metrics::MeterProvider by default' do
      meter_provider = OpenTelemetry.meter_provider
      _(meter_provider).must_be_instance_of(OpenTelemetry::Metrics::MeterProvider)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.meter_provider).must_equal(OpenTelemetry.meter_provider)
    end

    it 'returns user specified meter provider' do
      custom_meter_provider = 'a custom meter provider'
      OpenTelemetry.meter_provider = custom_meter_provider
      _(OpenTelemetry.meter_provider).must_equal(custom_meter_provider)
    end
  end

  describe '.baggage' do
    after do
      # Ensure we don't leak custom baggage to other tests
      OpenTelemetry.baggage = nil
    end

    it 'returns Baggage::Manager by default' do
      manager = OpenTelemetry.baggage
      _(manager).must_be_instance_of(OpenTelemetry::Baggage::Manager)
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

  describe '.instrumentation_registry' do
    it 'returns an instance of Instrumentation::Registry' do
      _(OpenTelemetry.instrumentation_registry).must_be_instance_of(
        OpenTelemetry::Instrumentation::Registry
      )
    end
  end

  describe '.propagation' do
    it 'returns instance of Context::Propagation::Propagation by default' do
      _(OpenTelemetry.propagation).must_be_instance_of(
        OpenTelemetry::Context::Propagation::Propagation
      )
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.propagation).must_equal(
        OpenTelemetry.propagation
      )
    end
  end
end
