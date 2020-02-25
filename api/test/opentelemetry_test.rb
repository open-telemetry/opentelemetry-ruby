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

  describe '.correlations' do
    after do
      # Ensure we don't leak custom correlations to other tests
      OpenTelemetry.correlations = nil
    end

    it 'returns CorrelationContext::Manager by default' do
      manager = OpenTelemetry.correlations
      _(manager).must_be_instance_of(OpenTelemetry::CorrelationContext::Manager)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.correlations).must_equal(
        OpenTelemetry.correlations
      )
    end

    it 'returns user specified correlations' do
      custom_manager = 'a custom correlations'
      OpenTelemetry.correlations = custom_manager
      _(OpenTelemetry.correlations).must_equal(custom_manager)
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
