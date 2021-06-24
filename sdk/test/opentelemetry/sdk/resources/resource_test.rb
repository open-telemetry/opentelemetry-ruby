# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Resources::Resource do
  Resource = OpenTelemetry::SDK::Resources::Resource

  describe '.new' do
    it 'is private' do
      _(proc { Resource.new('k1' => 'v1') }).must_raise(NoMethodError)
    end
  end

  describe '.create' do
    it 'can be initialized with attributes' do
      expected_attributes = { 'k1' => 'v1', 'k2' => 'v2' }
      resource = Resource.create(expected_attributes)
      _(resource.attribute_enumerator.to_h).must_equal(expected_attributes)
    end

    it 'can be empty' do
      resource = Resource.create
      _(resource.attribute_enumerator.to_h).must_be_empty
    end

    it 'enforces keys are strings' do
      _(proc { Resource.create(k1: 'v1') }).must_raise(ArgumentError)
    end

    it 'enforces values are strings, ints, floats, or booleans' do
      _(proc { Resource.create('k1' => :v1) }).must_raise(ArgumentError)
      values = ['v1', 123, 456.78, false, true]
      values.each do |value|
        resource = Resource.create('k1' => value)
        _(resource.attribute_enumerator.first.last).must_equal(value)
      end
    end
  end

  describe '.default' do
    before do
      Resource.instance_variable_set(:@default, nil)
    end

    after do
      Resource.instance_variable_set(:@default, nil)
    end

    it 'contains telemetry sdk attributes' do
      resource_attributes = Resource.default.attribute_enumerator.to_h
      _(resource_attributes).must_include('telemetry.sdk.name')
      _(resource_attributes).must_include('telemetry.sdk.language')
      _(resource_attributes).must_include('telemetry.sdk.version')
    end

    it 'contains process attributes' do
      resource_attributes = Resource.default.attribute_enumerator.to_h
      _(resource_attributes).must_include('process.pid')
      _(resource_attributes).must_include('process.command')
      _(resource_attributes).must_include('process.runtime.name')
      _(resource_attributes).must_include('process.runtime.version')
      _(resource_attributes).must_include('process.runtime.description')
    end

    it 'contains a default value for service.name' do
      resource_attributes = Resource.default.attribute_enumerator.to_h
      _(resource_attributes).must_include('service.name')
      _(resource_attributes['service.name']).must_equal('unknown_service')
    end

    it 'allows overriding the default service.name with the OTEL_SERVICE_NAME environment variable' do
      with_env('OTEL_SERVICE_NAME' => 'svc') do
        resource_attributes = Resource.default.attribute_enumerator.to_h
        _(resource_attributes).must_include('service.name')
        _(resource_attributes['service.name']).must_equal('svc')
      end
    end

    it 'allows overriding the default service.name with the OTEL_RESOURCE_ATTRIBUTES environment variable' do
      with_env('OTEL_RESOURCE_ATTRIBUTES' => 'service.name=svc') do
        resource_attributes = Resource.default.attribute_enumerator.to_h
        _(resource_attributes).must_include('service.name')
        _(resource_attributes['service.name']).must_equal('svc')
      end
    end

    it 'lets the OTEL_SERVICE_NAME environment variable take precedence over the OTEL_RESOURCE_ATTRIBUTES environment variable' do
      with_env('OTEL_SERVICE_NAME' => 'svc-ok', 'OTEL_RESOURCE_ATTRIBUTES' => 'service.name=svc-bad') do
        resource_attributes = Resource.default.attribute_enumerator.to_h
        _(resource_attributes).must_include('service.name')
        _(resource_attributes['service.name']).must_equal('svc-ok')
      end
    end
  end

  describe '.telemetry_sdk' do
    it 'returns a resource for the telemetry sdk' do
      resource_attributes = Resource.telemetry_sdk.attribute_enumerator.to_h
      _(resource_attributes['telemetry.sdk.name']).must_equal('opentelemetry')
      _(resource_attributes['telemetry.sdk.language']).must_equal('ruby')
      _(resource_attributes['telemetry.sdk.version']).must_match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}/)
    end

    describe 'when the environment variable is present' do
      let(:expected_resource_attributes) do
        {
          'key1' => 'value1',
          'key2' => 'value2',
          'telemetry.sdk.name' => 'opentelemetry',
          'telemetry.sdk.language' => 'ruby',
          'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION
        }
      end

      it 'includes environment resources' do
        with_env('OTEL_RESOURCE_ATTRIBUTES' => 'key1=value1,key2=value2') do
          resource_attributes = Resource.telemetry_sdk.attribute_enumerator.to_h
          _(resource_attributes).must_equal(expected_resource_attributes)
        end
      end
    end
  end

  describe '.process' do
    let(:expected_resource_attributes) do
      {
        'process.pid' => Process.pid,
        'process.command' => $PROGRAM_NAME,
        'process.runtime.name' => RUBY_ENGINE,
        'process.runtime.version' => RUBY_VERSION,
        'process.runtime.description' => RUBY_DESCRIPTION
      }
    end

    it 'returns a resource for the process and runtime' do
      resource_attributes = Resource.process.attribute_enumerator.to_h
      _(resource_attributes).must_equal(expected_resource_attributes)
    end
  end

  describe '#merge' do
    it 'merges two resources into a third' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create('k3' => 'v3', 'k4' => 'v4')
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2',
                                                   'k3' => 'v3', 'k4' => 'v4')
      _(res1.attribute_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2')
      _(res2.attribute_enumerator.to_h).must_equal('k3' => 'v3', 'k4' => 'v4')
    end

    it 'overwrites receiver\'s keys' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create('k2' => '2v2', 'k3' => '2v3')
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => '2v2',
                                                   'k3' => '2v3')
    end
  end
end
