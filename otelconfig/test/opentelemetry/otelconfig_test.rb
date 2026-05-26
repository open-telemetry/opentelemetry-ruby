# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OtelConfig do
  describe 'disabled flag' do
    it 'skips SDK provider setup when disabled: true' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        disabled: true
        tracer_provider:
          processors:
            - simple:
                exporter:
                  console:
      YAML
        OpenTelemetry::OtelConfig.configure_from_file(path)

        _(OpenTelemetry.tracer_provider).wont_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
      end
    end

    it 'applies SDK provider setup when disabled: false' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        disabled: false
        tracer_provider:
          processors:
            - simple:
                exporter:
                  console:
      YAML
        OpenTelemetry::OtelConfig.configure_from_file(path)

        _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
      end
    end
  end

  describe 'when provider sections are absent' do
    it 'does not install a tracer provider' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
      YAML
        OpenTelemetry::OtelConfig.configure_from_file(path)

        _(OpenTelemetry.tracer_provider).wont_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
      end
    end
  end

  describe 'tracer_provider and propagator configured together' do
    it 'creates the SDK tracer_provider with the shared resource and correct processors' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        resource:
          attributes:
            - name: service.name
              value: "full-stack-test"
        tracer_provider:
          processors:
            - simple:
                exporter:
                  console:
        propagator:
          composite:
            - tracecontext:
            - baggage:
      YAML
        OpenTelemetry::OtelConfig.configure_from_file(path)

        _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider

        tp_attrs = OpenTelemetry.tracer_provider
                                .instance_variable_get(:@resource)
                                .attribute_enumerator.to_h
        _(tp_attrs['service.name']).must_equal 'full-stack-test'

        fields = OpenTelemetry.propagation.fields
        _(fields).must_include 'traceparent'
        _(fields).must_include 'baggage'
      end
    end
  end
end
