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
    it 'returns an sampled span that is recorded' do
      activate_trace_config OpenTelemetry::SDK::Trace::Config::TraceConfig.new(sampler: datadog_probability_sampler::DEFAULT)
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).must_be :sampled?
      _(span).must_be :recording?
    end
  end

  def activate_trace_config(trace_config)
    tracer_provider.active_trace_config = trace_config
  end
end
