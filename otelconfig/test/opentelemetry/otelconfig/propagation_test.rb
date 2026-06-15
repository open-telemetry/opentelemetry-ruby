# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OtelConfig do
  describe 'propagator' do
    describe 'composite array' do
      it 'configures a single tracecontext propagator — correct instance and fields' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite:
              - tracecontext:
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagation.fields).must_include 'traceparent'
          _(propagation.fields).must_include 'tracestate'
        end
      end

      it 'configures a single baggage propagator — correct instance and fields' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite:
              - baggage:
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Baggage::Propagation::TextMapPropagator
          _(propagation.fields).must_include 'baggage'
        end
      end

      it 'composes tracecontext and baggage — correct instance, propagator order, and fields' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite:
              - tracecontext:
              - baggage:
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Context::Propagation::CompositeTextMapPropagator

          propagators = propagation.instance_variable_get(:@propagators)
          _(propagators.size).must_equal 2
          _(propagators[0]).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagators[1]).must_be_instance_of OpenTelemetry::Baggage::Propagation::TextMapPropagator

          fields = propagation.fields
          _(fields).must_include 'traceparent'
          _(fields).must_include 'tracestate'
          _(fields).must_include 'baggage'
          _(fields.index('traceparent')).must_be :<, fields.index('baggage')
        end
      end

      it 'silently skips unknown names and still applies the valid propagators' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite:
              - tracecontext:
              - nonexistent_xyz:
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagation.fields).must_include 'traceparent'
        end
      end

      it 'leaves propagation unconfigured when the composite array is empty' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite: []
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          fields = OpenTelemetry.propagation.fields
          _(fields).wont_include 'traceparent'
          _(fields).wont_include 'baggage'
        end
      end
    end

    describe 'composite_list string' do
      it 'configures tracecontext and baggage from a comma-separated list' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite_list: "tracecontext,baggage"
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Context::Propagation::CompositeTextMapPropagator

          propagators = propagation.instance_variable_get(:@propagators)
          _(propagators[0]).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagators[1]).must_be_instance_of OpenTelemetry::Baggage::Propagation::TextMapPropagator

          _(propagation.fields).must_include 'traceparent'
          _(propagation.fields).must_include 'baggage'
        end
      end

      it 'strips whitespace from each entry' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite_list: " tracecontext , baggage "
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          fields = OpenTelemetry.propagation.fields
          _(fields).must_include 'traceparent'
          _(fields).must_include 'baggage'
        end
      end

      it 'silently skips unknown entries and still applies the valid propagators' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite_list: "tracecontext,totally_unknown_propagator"
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagation.fields).must_include 'traceparent'
        end
      end
    end

    describe 'composite and composite_list merging' do
      it 'merges both sources and deduplicates — composite names come first' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          propagator:
            composite:
              - tracecontext:
            composite_list: "baggage,tracecontext"
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          propagation = OpenTelemetry.propagation
          _(propagation).must_be_instance_of OpenTelemetry::Context::Propagation::CompositeTextMapPropagator

          propagators = propagation.instance_variable_get(:@propagators)
          # tracecontext first (from composite), baggage second (from composite_list), no duplicate tracecontext
          _(propagators.size).must_equal 2
          _(propagators[0]).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          _(propagators[1]).must_be_instance_of OpenTelemetry::Baggage::Propagation::TextMapPropagator

          _(propagation.fields).must_include 'traceparent'
          _(propagation.fields).must_include 'baggage'
        end
      end
    end

    describe 'optional gem propagators' do
      %w[b3 b3multi jaeger ottrace google_cloud_trace_context].each do |name|
        it "does not raise and keeps tracecontext when #{name} is requested" do
          with_config(<<~YAML) do |path|
            file_format: "1.0"
            #{TRACER_PROVIDER_YAML}
            propagator:
              composite:
                - #{name}:
                - tracecontext:
          YAML
            sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
            OpenTelemetry.tracer_provider = sdk.tracer_provider
            OpenTelemetry.propagation = sdk.propagator if sdk.propagator

            _(OpenTelemetry.propagation.fields).must_include 'traceparent'
          end
        end
      end

      # xray does not implement a `fields` instance method, so the composite's
      # fields aggregation cannot be used.  Instead we verify the propagator is
      # present in the composite's @propagators array and is the correct type.
      describe 'xray (gem required)' do
        before { require 'opentelemetry-propagator-xray' }

        it 'configures xray alone — propagation is an XRay::TextMapPropagator instance' do
          with_config(<<~YAML) do |path|
            file_format: "1.0"
            #{TRACER_PROVIDER_YAML}
            propagator:
              composite:
                - xray:
          YAML
            sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
            OpenTelemetry.tracer_provider = sdk.tracer_provider
            OpenTelemetry.propagation = sdk.propagator if sdk.propagator

            _(OpenTelemetry.propagation).must_be_instance_of \
              OpenTelemetry::Propagator::XRay::TextMapPropagator
          end
        end

        it 'composes xray with tracecontext — both are present in @propagators in order' do
          with_config(<<~YAML) do |path|
            file_format: "1.0"
            #{TRACER_PROVIDER_YAML}
            propagator:
              composite:
                - xray:
                - tracecontext:
          YAML
            sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
            OpenTelemetry.tracer_provider = sdk.tracer_provider
            OpenTelemetry.propagation = sdk.propagator if sdk.propagator

            propagation = OpenTelemetry.propagation
            _(propagation).must_be_instance_of \
              OpenTelemetry::Context::Propagation::CompositeTextMapPropagator

            propagators = propagation.instance_variable_get(:@propagators)
            _(propagators.size).must_equal 2
            _(propagators[0]).must_be_instance_of OpenTelemetry::Propagator::XRay::TextMapPropagator
            _(propagators[1]).must_be_instance_of OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator
          end
        end
      end
    end

    describe 'when propagator section is absent' do
      it 'leaves propagation unconfigured' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          OpenTelemetry.propagation = sdk.propagator if sdk.propagator

          fields = OpenTelemetry.propagation.fields
          _(fields).wont_include 'traceparent'
          _(fields).wont_include 'baggage'
        end
      end
    end
  end
end
