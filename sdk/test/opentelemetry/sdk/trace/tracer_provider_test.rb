# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::TracerProvider do
  let(:tracer_provider) do
    OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
  end

  describe '#initialize' do
    it 'activates a default TraceConfig' do
      _(tracer_provider.active_trace_config).must_equal(TraceConfig::DEFAULT)
    end
  end

  describe '#shutdown' do
    let(:mock_span_processor) { Minitest::Mock.new }

    it 'notifies the span processor' do
      mock_span_processor.expect(:shutdown, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.shutdown
      mock_span_processor.verify
    end

    it 'warns if called more than once' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:warn, nil, [String])
      OpenTelemetry.stub :logger, mock_logger do
        tracer_provider.shutdown
        tracer_provider.shutdown
      end
      mock_logger.verify
    end

    it 'only notifies the span processor once' do
      mock_span_processor.expect(:shutdown, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.shutdown
      tracer_provider.shutdown
      mock_span_processor.verify
    end
  end

  describe '#add_span_processor' do
    it 'does not add the processor if stopped' do
      mock_span_processor = Minitest::Mock.new
      tracer_provider.shutdown
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.tracer.in_span('span') {}
      mock_span_processor.verify
    end

    it 'adds the span processor to the active span processors' do
      mock_span_processor = Minitest::Mock.new
      mock_span_processor.expect(:on_start, nil, [Span, Context])
      mock_span_processor.expect(:on_finish, nil, [Span])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.tracer.in_span('span') {}
      mock_span_processor.verify
    end

    it 'adds multiple span processors to the active span processors' do
      mock_processors = Array.new(2) { MiniTest::Mock.new }
      mock_processors.each do |p|
        p.expect(:on_start, nil, [Span, Context])
        p.expect(:on_finish, nil, [Span])
        tracer_provider.add_span_processor(p)
      end

      tracer_provider.tracer.in_span('span') {}
      mock_processors.each(&:verify)
    end
  end

  describe '.tracer' do
    it 'returns the same tracer for the same arguments' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '1.0')
      _(tracer1).must_equal(tracer2)
    end

    it 'returns a default name-less version-less tracer' do
      tracer = tracer_provider.tracer
      _(tracer.name).must_equal('')
      _(tracer.version).must_equal('')
    end

    it 'returns different tracers for different names' do
      tracer1 = tracer_provider.tracer('component1', '1.0')
      tracer2 = tracer_provider.tracer('component2', '1.0')
      _(tracer1).wont_equal(tracer2)
    end

    it 'returns different tracers for different versions' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '2.0')
      _(tracer1).wont_equal(tracer2)
    end
  end
end
