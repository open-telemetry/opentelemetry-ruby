# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Exporters::Datadog::DatadogProbabilitySampler do
  DatadogProbabilitySampler = OpenTelemetry::Exporters::Datadog::DatadogProbabilitySampler
  # Tracer = OpenTelemetry::SDK::Trace::Tracer

  let(:tracer_provider) { OpenTelemetry::SDK::Trace::TracerProvider.new }
  let(:tracer) do
    OpenTelemetry.tracer_provider = tracer_provider
    OpenTelemetry.tracer_provider.tracer('component-tracer', '1.0.0')
  end

  let(:probability) { 1.0 }

  let(:default_probability_sampler) do
    Samplers::ProbabilitySampler::DEFAULT
  end

  let(:datadog_probability_sampler) do
    DatadogProbabilitySampler
  end

  describe '#default' do
    it 'returns a sampled span that is recorded' do
      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler::DEFAULT)
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).must_be :sampled?
      _(span).must_be :recording?
    end

    it 'samples and records all spans by default' do
      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler::DEFAULT)
      spans = []
      100.times do |_x|
        spans << tracer.start_root_span('root')
      end

      spans.each do |span|
        _(span.context.trace_flags).must_be :sampled?
        _(span).must_be :recording?
      end
    end
  end

  describe '#default_with_probability' do
    it 'samples and records all spans by default' do
      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler.default_with_probability)
      spans = []
      100.times do |_x|
        spans << tracer.start_root_span('root')
      end

      spans.each do |span|
        _(span.context.trace_flags).must_be :sampled?
        _(span).must_be :recording?
      end
    end

    it 'records but does not sample according to the rate between [0.0-1.0]' do
      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler.default_with_probability(0.0))
      spans = []
      100.times do
        spans << tracer.start_root_span('root')
      end

      spans.each do |span|
        _(span.context.trace_flags).wont_be :sampled?
        _(span).must_be :recording?
      end

      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler.default_with_probability(0.5))
      some_sampled_spans = []
      100.times do |_x|
        some_sampled_spans << tracer.start_root_span('root')
      end

      sampled = []
      not_sampled = []
      some_sampled_spans.each do |span|
        if span.context.trace_flags.sampled?
          sampled << span
        else
          not_sampled << span
        end
      end
      _(sampled.length).must_be_close_to(50, 10)
      _(not_sampled.length).must_be_close_to(50, 10)

      some_sampled_spans.each do |span|
        _(span).must_be :recording?
      end
    end

    it 'raises an error if the rate is not between [0.0-1.0]' do
      assert_raises ArgumentError do
        datadog_probability_sampler.default_with_probability(2)
      end

      assert_raises ArgumentError do
        datadog_probability_sampler.default_with_probability('apple')
      end

      assert_raises ArgumentError do
        datadog_probability_sampler.default_with_probability(-1)
      end
    end
  end

  def activate_trace_config(trace_config)
    tracer_provider.active_trace_config = trace_config
  end
end
