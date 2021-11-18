# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::Deployment do
  let(:detector) { OpenTelemetry::Resource::Detectors::Deployment }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    it 'returns an empty resource' do
      with_env({}) do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when rails is used' do
      it 'return rails env when present' do
        allow(::Rails).to receive(:env).and_return('env from rails')
        with_env({}) do
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal('deployment.environment' => 'env from rails')
        end
      end
    end

    describe 'when sinatra is used' do
      it 'return sinatra env if already required' do
        module MockSinatraBase  # rubocop:disable Lint/ConstantDefinitionInBlock
          def self.environment
            'env from sinatra'
          end
        end

        stub_const('::Sinatra::Base', MockSinatraBase)
        with_env({}) do
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal('deployment.environment' => 'env from sinatra')
        end
      end

      it 'when sinatra not yet initialized, but environment set in ENV' do
        with_env({ 'APP_ENV' => 'env from sinatra environment variables' }) do
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal('deployment.environment' => 'env from sinatra environment variables')
        end
      end
    end

    describe 'when in a rack environment' do
      it 'returns a resource with rack environment' do
        with_env('RACK_ENV' => 'env from rack') do
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal('deployment.environment' => 'env from rack')
        end
      end
    end
  end
end
