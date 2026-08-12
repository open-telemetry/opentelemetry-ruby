# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config do
  describe '.parse' do
    it 'returns the configuration model' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        disabled: true
      YAML
        config = OpenTelemetry::Config.parse(path)

        _(config).must_be_instance_of OpenTelemetry::Config::Model::OpenTelemetryConfiguration
        _(config.disabled).must_equal true
      end
    end

    it 'returns nil when no path is given' do
      _(OpenTelemetry::Config.parse(nil)).must_be_nil
    end

    it 'returns nil when the file does not exist' do
      _(OpenTelemetry::Config.parse('/nonexistent/otel-config.yaml')).must_be_nil
    end
  end

  describe '.create' do
    it 'builds providers without modifying global state' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
      YAML
        sdk = OpenTelemetry::Config.create(OpenTelemetry::Config.parse(path))

        _(sdk.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
        _(OpenTelemetry.tracer_provider).wont_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
      end
    end

    it 'returns a no-op SDK when the configuration is absent' do
      sdk = OpenTelemetry::Config.create(nil)

      _(sdk.tracer_provider).must_be_instance_of OpenTelemetry::Trace::TracerProvider
      _(sdk.propagator).must_be_instance_of OpenTelemetry::Context::Propagation::NoopTextMapPropagator
    end
  end

  describe '.install' do
    it 'assigns the globals and returns the same SDK' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
        propagator:
          composite:
            - tracecontext:
      YAML
        sdk = OpenTelemetry::Config.create(OpenTelemetry::Config.parse(path))

        _(OpenTelemetry::Config.install(sdk)).must_be_same_as sdk
        _(OpenTelemetry.tracer_provider).must_be_same_as sdk.tracer_provider
        _(OpenTelemetry.propagation).must_be_same_as sdk.propagator
      end
    end
  end

  describe '.configure' do
    it 'parses, creates, and installs the file named by OTEL_CONFIG_FILE' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
      YAML
        OpenTelemetry::TestHelpers.with_env('OTEL_CONFIG_FILE' => path) do
          sdk = OpenTelemetry::Config.configure

          _(OpenTelemetry.tracer_provider).must_be_same_as sdk.tracer_provider
        end
      end
    end
  end

  describe 'RubySDK#shutdown' do
    it 'shuts down the configured providers' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
      YAML
        sdk = OpenTelemetry::Config.configure_from_file(path)
        sdk.shutdown

        _(sdk.tracer_provider.instance_variable_get(:@stopped)).must_equal true
      end
    end

    it 'skips providers that do not respond to shutdown' do
      sdk = OpenTelemetry::Config::RubySDK.new(tracer_provider: OpenTelemetry::Trace::TracerProvider.new)

      _(sdk.shutdown).must_be_nil
    end
  end

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
        OpenTelemetry::Config.configure_from_file(path)

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
        sdk = OpenTelemetry::Config.configure_from_file(path)
        OpenTelemetry.tracer_provider = sdk.tracer_provider

        _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
      end
    end
  end

  describe 'when provider sections are absent' do
    it 'does not install a tracer provider' do
      with_config(<<~YAML) do |path|
        file_format: "1.0"
      YAML
        OpenTelemetry::Config.configure_from_file(path)

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
        sdk = OpenTelemetry::Config.configure_from_file(path)
        OpenTelemetry.tracer_provider = sdk.tracer_provider
        OpenTelemetry.propagation = sdk.propagator

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
