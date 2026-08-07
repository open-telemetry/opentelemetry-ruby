# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OtelConfig do
  describe 'resource attributes' do
    describe 'attributes array with no type field' do
      it 'stores a plain string value' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "my-service"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'my-service'
        end
      end

      it 'stores a YAML-parsed integer as-is' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: instance.count
                value: 3
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['instance.count']).must_equal 3
        end
      end

      it 'stores a YAML-parsed boolean as-is' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: feature.enabled
                value: true
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['feature.enabled']).must_equal true
        end
      end
    end

    describe 'attributes array with type: string' do
      it 'converts an integer value to its string representation' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: build.number
                value: 42
                type: string
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['build.number']).must_equal '42'
          _(attrs['build.number']).must_be_kind_of String
        end
      end

      it 'keeps an existing string value as a string' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.namespace
                value: "payments"
                type: string
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.namespace']).must_equal 'payments'
        end
      end
    end

    describe 'attributes array with typed fields' do
      it 'coerces each supported type correctly' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: debug.enabled
                value: true
                type: bool
              - name: debug.disabled
                value: false
                type: bool
              - name: flag.true
                value: "true"
                type: bool
              - name: flag.false
                value: "false"
                type: bool
              - name: max.retries
                value: 5
                type: int
              - name: sample.ratio
                value: 0.25
                type: double
              - name: host.tags
                value: [web, api, gateway]
                type: string_array
              - name: feature.flags
                value: [true, false, true]
                type: bool_array
              - name: allowed.ports
                value: [8080, 8443, 9000]
                type: int_array
              - name: cpu.percentages
                value: [0.25, 0.50, 0.75]
                type: double_array
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h

          # bool: native YAML booleans
          _(attrs['debug.enabled']).must_equal true
          _(attrs['debug.disabled']).must_equal false

          # bool: string coercion
          _(attrs['flag.true']).must_equal true
          _(attrs['flag.false']).must_equal false

          # int
          _(attrs['max.retries']).must_equal 5
          _(attrs['max.retries']).must_be_kind_of Integer

          # double
          _(attrs['sample.ratio']).must_equal 0.25
          _(attrs['sample.ratio']).must_be_kind_of Float

          # string_array
          _(attrs['host.tags']).must_equal %w[web api gateway]

          # bool_array
          _(attrs['feature.flags']).must_equal [true, false, true]

          # int_array
          _(attrs['allowed.ports']).must_equal [8080, 8443, 9000]

          # double_array
          _(attrs['cpu.percentages']).must_equal [0.25, 0.50, 0.75]
        end
      end
    end

    describe 'attributes array with invalid entries' do
      it 'skips entries that have no name key' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - value: "orphan"
              - name: service.name
                value: "valid"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'valid'
          _(attrs.value?('orphan')).must_equal false
        end
      end

      it 'skips entries whose value is null (YAML ~)' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: empty.key
                value: ~
              - name: service.name
                value: "present"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs.key?('empty.key')).must_equal false
          _(attrs['service.name']).must_equal 'present'
        end
      end
    end

    describe 'multiple attributes together' do
      it 'includes all named attributes regardless of type' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "inventory-api"
              - name: deployment.environment
                value: "production"
              - name: service.version
                value: "2.1.0"
              - name: max.connections
                value: 100
                type: int
              - name: sample.ratio
                value: 0.5
                type: double
              - name: debug.enabled
                value: false
                type: bool
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'inventory-api'
          _(attrs['deployment.environment']).must_equal 'production'
          _(attrs['service.version']).must_equal '2.1.0'
          _(attrs['max.connections']).must_equal 100
          _(attrs['sample.ratio']).must_equal 0.5
          _(attrs['debug.enabled']).must_equal false
        end
      end
    end

    describe 'attributes_list' do
      it 'parses a single key=value pair' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes_list: "env=production"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['env']).must_equal 'production'
        end
      end

      it 'parses multiple comma-separated key=value pairs' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes_list: "region=us-east-1,team=platform,tier=backend"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['region']).must_equal 'us-east-1'
          _(attrs['team']).must_equal 'platform'
          _(attrs['tier']).must_equal 'backend'
        end
      end

      it 'preserves a value containing = by splitting only on the first =' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes_list: "auth.token=abc=def=ghi"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['auth.token']).must_equal 'abc=def=ghi'
        end
      end
    end

    describe 'priority: attributes array over attributes_list' do
      it 'keeps the attributes-array value when both sources define the same key' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "from-array"
            attributes_list: "service.name=from-list"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'from-array'
        end
      end

      it 'still includes keys that appear only in attributes_list' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "from-array"
            attributes_list: "service.name=from-list,extra.key=bonus-value"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'from-array'
          _(attrs['extra.key']).must_equal 'bonus-value'
        end
      end

      it 'still includes keys that appear only in the attributes array' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: only-in-array
                value: "here"
            attributes_list: "only-in-list=there"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['only-in-array']).must_equal 'here'
          _(attrs['only-in-list']).must_equal 'there'
        end
      end
    end

    describe 'schema_url' do
      it 'does not raise and still applies all attributes' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            schema_url: "https://opentelemetry.io/schemas/1.21.0"
            attributes:
              - name: service.name
                value: "schema-test"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'schema-test'
        end
      end
    end

    describe 'detection/development' do
      it 'does not raise for an unknown detector and preserves explicit attributes' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            detection/development:
              detectors:
                - unknown_detector_xyz:
            attributes:
              - name: service.name
                value: "detection-test"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'detection-test'
        end
      end

      it 'applies included pattern filtering without raising' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            detection/development:
              detectors:
                - unknown_detector_xyz:
              attributes:
                included:
                  - "process.*"
                excluded: []
            attributes:
              - name: service.name
                value: "filter-test"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'filter-test'
        end
      end

      it 'applies excluded pattern filtering without raising' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            detection/development:
              detectors:
                - unknown_detector_xyz:
              attributes:
                included: []
                excluded:
                  - "host.*"
            attributes:
              - name: service.name
                value: "exclude-test"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'exclude-test'
        end
      end
    end

    describe 'merged with default SDK resource' do
      it 'preserves built-in telemetry.sdk.* attributes alongside custom ones' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "sdk-merge-test"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          attrs = OpenTelemetry.tracer_provider
                               .instance_variable_get(:@resource)
                               .attribute_enumerator.to_h
          _(attrs['service.name']).must_equal 'sdk-merge-test'
          _(attrs).must_include 'telemetry.sdk.name'
          _(attrs).must_include 'telemetry.sdk.language'
        end
      end
    end

    describe 'resource shared across all providers' do
      it 'applies the same resource attributes to the tracer_provider' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          resource:
            attributes:
              - name: service.name
                value: "shared-service"
              - name: deployment.environment
                value: "staging"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          tp_attrs = OpenTelemetry.tracer_provider
                                  .instance_variable_get(:@resource)
                                  .attribute_enumerator.to_h

          _(tp_attrs['service.name']).must_equal 'shared-service'
          _(tp_attrs['deployment.environment']).must_equal 'staging'
        end
      end
    end
  end
end
