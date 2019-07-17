# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry do
  describe '.tracer' do
    after do
      # Ensure we don't leak custom tracers to other tests
      OpenTelemetry.tracer = nil
    end

    it 'returns instance of Trace::Tracer by default' do
      tracer = OpenTelemetry.tracer
      tracer.must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end

    it 'returns the same instance when accessed multiple times' do
      OpenTelemetry.tracer.must_equal(OpenTelemetry.tracer)
    end

    it 'returns user specified tracer' do
      custom_tracer = 'a custom tracer'
      OpenTelemetry.tracer = custom_tracer
      OpenTelemetry.tracer.must_equal(custom_tracer)
    end
  end

  describe '.meter' do
    after do
      # Ensure we don't leak custom meter to other tests
      OpenTelemetry.meter = nil
    end

    it 'returns instance of Metrics::Meter by default' do
      meter = OpenTelemetry.meter
      meter.must_be_instance_of(OpenTelemetry::Metrics::Meter)
    end

    it 'returns the same instance when accessed multiple times' do
      OpenTelemetry.meter.must_equal(OpenTelemetry.meter)
    end

    it 'returns user specified meter' do
      custom_meter = 'a custom meter'
      OpenTelemetry.meter = custom_meter
      OpenTelemetry.meter.must_equal(custom_meter)
    end
  end

  describe '.distributed_context_manager' do
    after do
      # Ensure we don't leak custom distributed_context_manager to other tests
      OpenTelemetry.distributed_context_manager = nil
    end

    it 'returns instance of DistributedContext::Manager by default' do
      manager = OpenTelemetry.distributed_context_manager
      manager.must_be_instance_of(OpenTelemetry::DistributedContext::Manager)
    end

    it 'returns the same instance when accessed multiple times' do
      OpenTelemetry.distributed_context_manager.must_equal(
        OpenTelemetry.distributed_context_manager
      )
    end

    it 'returns user specified distributed_context_manager' do
      custom_manager = 'a custom distributed_context_manager'
      OpenTelemetry.distributed_context_manager = custom_manager
      OpenTelemetry.distributed_context_manager.must_equal(custom_manager)
    end
  end
end
