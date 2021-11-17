# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::Deployment do
  let(:detector) { OpenTelemetry::Resource::Detectors::Deployment }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end

    describe 'when in a rack environment' do
      it 'returns a resource with rack environment' do
        old_env = ENV['RACK_ENV']
        ENV['RACK_ENV'] = 'env from test'
        begin
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal('deployment.environment' => 'env from test')
        ensure
          ENV['RACK_ENV'] = old_env
        end
      end
    end
  end
end
