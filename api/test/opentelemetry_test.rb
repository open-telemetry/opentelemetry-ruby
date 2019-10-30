# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'tempfile'

describe OpenTelemetry do
  describe '.tracer_factory' do
    after do
      # Ensure we don't leak custom tracer factories and tracers to other tests
      OpenTelemetry.tracer_factory = nil
    end

    it 'returns instance of Trace::TracerFactory by default' do
      tracer_factory = OpenTelemetry.tracer_factory
      _(tracer_factory).must_be_instance_of(OpenTelemetry::Trace::TracerFactory)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.tracer_factory).must_equal(OpenTelemetry.tracer_factory)
    end

    it 'returns user specified tracer factory' do
      custom_tracer_factory = 'a custom tracer factory'
      OpenTelemetry.tracer_factory = custom_tracer_factory
      _(OpenTelemetry.tracer_factory).must_equal(custom_tracer_factory)
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

  describe '.meter' do
    after do
      # Ensure we don't leak custom meter to other tests
      OpenTelemetry.meter = nil
    end

    it 'returns instance of Metrics::Meter by default' do
      meter = OpenTelemetry.meter
      _(meter).must_be_instance_of(OpenTelemetry::Metrics::Meter)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.meter).must_equal(OpenTelemetry.meter)
    end

    it 'returns user specified meter' do
      custom_meter = 'a custom meter'
      OpenTelemetry.meter = custom_meter
      _(OpenTelemetry.meter).must_equal(custom_meter)
    end
  end

  describe '.distributed_context_manager' do
    after do
      # Ensure we don't leak custom distributed_context_manager to other tests
      OpenTelemetry.distributed_context_manager = nil
    end

    it 'returns instance of DistributedContext::Manager by default' do
      manager = OpenTelemetry.distributed_context_manager
      _(manager).must_be_instance_of(OpenTelemetry::DistributedContext::Manager)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.distributed_context_manager).must_equal(
        OpenTelemetry.distributed_context_manager
      )
    end

    it 'returns user specified distributed_context_manager' do
      custom_manager = 'a custom distributed_context_manager'
      OpenTelemetry.distributed_context_manager = custom_manager
      _(OpenTelemetry.distributed_context_manager).must_equal(custom_manager)
    end
  end
end
