# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Configurator do
  let(:configurator) { OpenTelemetry::SDK::Configurator.new }

  describe '#logger' do
    it 'returns a logger instance' do
      _(configurator.logger).must_be_instance_of(Logger)
    end
  end

  describe '#use' do
    it 'can be called multiple times' do
      configurator.use('TestAdapter', enabled: true)
      configurator.use('TestAdapter1')
    end
  end

  describe '#use, #use_all' do
    describe 'should be used mutually exclusively' do
      it 'raises when use_all called after use' do
        configurator.use('TestAdapter', enabled: true)
        _(-> { configurator.use_all }).must_raise(StandardError)
      end

      it 'raises when use called after use_all' do
        configurator.use_all
        _(-> { configurator.use('TestAdapter', enabled: true) })
          .must_raise(StandardError)
      end
    end
  end

  describe '#configure' do
    after do
      reset_globals
    end

    describe 'tracer_factory' do
      it 'is an instance of SDK::Trace::TracerFactory' do
        configurator.configure

        _(OpenTelemetry.tracer_factory).must_be_instance_of(
          OpenTelemetry::SDK::Trace::TracerFactory
        )
      end
    end

    describe 'span processors' do
      it 'defaults to SimpleSpanProcessor w/ ConsoleSpanExporter' do
        configurator.configure

        processors = active_span_processors

        _(processors.size).must_equal(1)
        _(processors.first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
      end

      it 'reflects configured value' do
        configurator.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            exporter: OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
          )
        )

        configurator.configure
        processors = active_span_processors

        _(processors.size).must_equal(1)
        _(processors.first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
      end
    end

    describe 'instrumentation installation' do
      before do
        TestAdapter = Class.new(OpenTelemetry::Instrumentation::Adapter) do
          install { 1 + 1 }
          present { true }
        end
      end

      after do
        Object.send(:remove_const, :TestAdapter)
      end

      it 'installs single adapter' do
        registry = OpenTelemetry.instrumentation_registry
        adapter = registry.lookup('TestAdapter')
        _(adapter).wont_be_nil
        _(adapter).wont_be(:installed?)
        configurator.use 'TestAdapter', opt: true
        configurator.configure
        _(adapter).must_be(:installed?)
        _(adapter.config).must_equal(opt: true)
      end

      it 'installs all' do
        registry = OpenTelemetry.instrumentation_registry
        adapter = registry.lookup('TestAdapter')
        _(adapter).wont_be_nil
        _(adapter).wont_be(:installed?)
        configurator.use_all 'TestAdapter' => { opt: true }
        configurator.configure
        _(adapter).must_be(:installed?)
        _(adapter.config).must_equal(opt: true)
      end
    end
  end

  def active_span_processors
    OpenTelemetry.tracer_factory.active_span_processor.instance_variable_get(:@span_processors)
  end

  def reset_globals
    OpenTelemetry.instance_variables.each do |iv|
      OpenTelemetry.instance_variable_set(iv, nil)
    end
    OpenTelemetry.logger = Logger.new(STDOUT)
  end
end
