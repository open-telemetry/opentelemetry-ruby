# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::TracerProvider do
  let(:samplers) { OpenTelemetry::SDK::Trace::Samplers }
  let(:subject) { OpenTelemetry::SDK::Trace::TracerProvider }
  let(:tracer_provider) do
    OpenTelemetry.tracer_provider = subject.new
  end

  describe '#initialize' do
    it 'activates a default SpanLimits and Sampler' do
      _(tracer_provider.span_limits).must_equal(SpanLimits::DEFAULT)
      _(tracer_provider.sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_ON)
    end

    it 'configures samplers from environment' do
      sampler = with_env('OTEL_TRACES_SAMPLER' => 'always_on') { subject.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_ON

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'always_off') { subject.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_OFF

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'traceidratio', 'OTEL_TRACES_SAMPLER_ARG' => '0.1') { subject.new.sampler }
      _(sampler).must_equal samplers.trace_id_ratio_based(0.1)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'traceidratio') { subject.new.sampler }
      _(sampler).must_equal samplers.trace_id_ratio_based(1.0)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_always_on') { subject.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_ON)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_always_off') { subject.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_OFF)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_traceidratio', 'OTEL_TRACES_SAMPLER_ARG' => '0.2') { subject.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers.trace_id_ratio_based(0.2))

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_traceidratio') { subject.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers.trace_id_ratio_based(1.0))
    end
  end

  describe '#shutdown' do
    let(:mock_span_processor)  { Minitest::Mock.new }
    let(:mock_span_processor2) { Minitest::Mock.new }

    it 'notifies the span processor' do
      mock_span_processor.expect(:shutdown, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.shutdown
      mock_span_processor.verify
    end

    it 'warns if called more than once' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:warn, nil, [String])
      tracer_provider.shutdown
      OpenTelemetry.stub :logger, mock_logger do
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

    it 'supports multiple span processors' do
      mock_span_processor.expect(:shutdown, nil, [{ timeout: nil }])
      mock_span_processor2.expect(:shutdown, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.add_span_processor(mock_span_processor2)
      tracer_provider.shutdown
      mock_span_processor.verify
      mock_span_processor2.verify
    end

    it 'does not deadlock if span processor is traced' do
      span_processor = OpenTelemetry::SDK::Trace::SpanProcessor.new
      tracer_provider.add_span_processor(span_processor)
      span_processor.stub(:shutdown, ->(timeout: nil) { tracer_provider.tracer.in_span('shutdown') {} }) do # rubocop:disable Lint/UnusedBlockArgument
        tracer_provider.shutdown
      end
      pass 'no deadlock'
    end
  end

  describe '#force_flush' do
    let(:mock_span_processor)  { Minitest::Mock.new }
    let(:mock_span_processor2) { Minitest::Mock.new }

    it 'notifies the span processor' do
      mock_span_processor.expect(:force_flush, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.force_flush
      mock_span_processor.verify
    end

    it 'supports multiple span processors' do
      mock_span_processor.expect(:force_flush, nil, [{ timeout: nil }])
      mock_span_processor2.expect(:force_flush, nil, [{ timeout: nil }])
      tracer_provider.add_span_processor(mock_span_processor)
      tracer_provider.add_span_processor(mock_span_processor2)
      tracer_provider.force_flush
      mock_span_processor.verify
      mock_span_processor2.verify
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

  describe '#tracer' do
    before do
      @log_stream = StringIO.new
      @_logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(@log_stream, level: 'WARN')
    end

    after do
      OpenTelemetry.logger = @_logger
    end

    it 'returns the same tracer for the same arguments' do
      tracer1 = tracer_provider.tracer('component', '1.0')
      tracer2 = tracer_provider.tracer('component', '1.0')
      _(tracer1).must_equal(tracer2)
      _(@log_stream.string).must_be_empty
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

    it 'warn when no name is passed for the tracer' do
      tracer_provider.tracer
      _(@log_stream.string).must_match(/calling TracerProvider#tracer without providing a tracer name./)
    end
  end
end
