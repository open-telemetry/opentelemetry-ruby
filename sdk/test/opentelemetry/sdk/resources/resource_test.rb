# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Resources::Resource do
  Resource = OpenTelemetry::SDK::Resources::Resource

  before do
    @log_stream = StringIO.new
    @_logger = OpenTelemetry.logger
    OpenTelemetry.logger = ::Logger.new(@log_stream)
  end

  after do
    # Ensure we don't leak custom loggers and error handlers to other tests
    OpenTelemetry.logger = @_logger
  end

  describe '.new' do
    it 'is private' do
      _(proc { Resource.new({ 'k1' => 'v1' }, 'some_schema_url') }).must_raise(NoMethodError)
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

    it 'can be initialized with schema_url' do
      expected_attributes = { 'k1' => 'v1', 'k2' => 'v2' }
      expected_schema_url = 'https://opentelemetry.io/schemas/1.6.1'
      resource = Resource.create(expected_attributes, expected_schema_url)
      _(resource.schema_url).must_equal(expected_schema_url)
    end

    it 'can be an empty schema_url' do
      resource = Resource.create({})
      assert_nil(resource.schema_url)
    end

    it 'enforces schema_url is a string' do
      _(proc { Resource.create({}, 42) }).must_raise(ArgumentError)
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
      resource_default = Resource.default
      resource_attributes = resource_default.attribute_enumerator.to_h
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

    it 'contains default schema_url' do
      resource_default = Resource.default
      resource_schema_url = resource_default.schema_url
      _(resource_schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end
  end

  describe '.telemetry_sdk' do
    it 'returns a resource for the telemetry sdk' do
      resource_telemetry_sdk = Resource.telemetry_sdk
      resource_attributes = resource_telemetry_sdk.attribute_enumerator.to_h
      resource_schema_url = resource_telemetry_sdk.schema_url
      _(resource_attributes['telemetry.sdk.name']).must_equal('opentelemetry')
      _(resource_attributes['telemetry.sdk.language']).must_equal('ruby')
      _(resource_attributes['telemetry.sdk.version']).must_match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}/)
      _(resource_schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
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

      let(:expected_schema_url) { "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}" }

      it 'includes environment resources' do
        with_env('OTEL_RESOURCE_ATTRIBUTES' => 'key1=value1,key2=value2') do
          resource_telemetry_sdk = Resource.telemetry_sdk
          resource_attributes = resource_telemetry_sdk.attribute_enumerator.to_h
          resource_schema_url = resource_telemetry_sdk.schema_url
          _(resource_attributes).must_equal(expected_resource_attributes)
          _(resource_schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
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

    let(:expected_schema_url) { "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}" }

    it 'returns a resource for the process and runtime' do
      resource_process = Resource.process
      resource_attributes = resource_process.attribute_enumerator.to_h
      resource_schema_url = resource_process.schema_url
      _(resource_attributes).must_equal(expected_resource_attributes)
      _(resource_schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end
  end

  describe '#merge' do
    it 'merges two resources into a third' do
      res1 = Resource.create({ 'k1' => 'v1', 'k2' => 'v2' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res2 = Resource.create({ 'k3' => 'v3', 'k4' => 'v4' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2',
                                                   'k3' => 'v3', 'k4' => 'v4')
      _(res1.attribute_enumerator.to_h).must_equal('k1' => 'v1', 'k2' => 'v2')
      _(res2.attribute_enumerator.to_h).must_equal('k3' => 'v3', 'k4' => 'v4')
      _(res1.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      _(res2.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      _(res3.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end

    it 'overwrites receiver\'s keys' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create('k2' => '2v2', 'k3' => '2v3')
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => '2v2',
                                                   'k3' => '2v3')
    end

    it 'overwrites receiver\'s empty schema_url when merging schema_url is present' do
      res1 = Resource.create('k1' => 'v1', 'k2' => 'v2')
      res2 = Resource.create({ 'k2' => '2v2', 'k3' => '2v3' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => '2v2',
                                                   'k3' => '2v3')

      _(res3.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end

    it 'does not overwrite receiver\'s present schema_url when merging schema_url is empty' do
      res1 = Resource.create({ 'k1' => 'v1', 'k2' => 'v2' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res2 = Resource.create('k2' => '2v2', 'k3' => '2v3')
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => '2v2',
                                                   'k3' => '2v3')

      _(res3.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end

    it 'does not overwrite receiver\'s present schema_url when merging schema_url is present and matches' do
      res1 = Resource.create({ 'k1' => 'v1', 'k2' => 'v2' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res2 = Resource.create({ 'k2' => '2v2', 'k3' => '2v3' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res3 = res1.merge(res2)

      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => '2v2',
                                                   'k3' => '2v3')

      _(res3.schema_url).must_equal("https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
    end

    it 'returns old resource when both resources schema_url are present and do not match and logs an error log' do
      res1 = Resource.create({ 'k1' => 'v1', 'k2' => 'v2' }, "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}")
      res2 = Resource.create({ 'k2' => '2v2', 'k3' => '2v3' }, 'arbitrary_other_other')
      res3 = res1.merge(res2)
      _(res3.attribute_enumerator.to_h).must_equal('k1' => 'v1',
                                                   'k2' => 'v2')

      _(res3).must_equal(res1)

      _(@log_stream.string).must_include("ERROR -- : Failed to merge resources: The two schemas https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION} and arbitrary_other_other are incompatible")
    end
  end
end
