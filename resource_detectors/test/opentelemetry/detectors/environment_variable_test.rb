# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::EnvironmentVariable do
  let(:detector) { OpenTelemetry::Resource::Detectors::EnvironmentVariable }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_labels) { detected_resource.label_enumerator.to_h }
    let(:expected_resource_labels) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_labels).must_equal(expected_resource_labels)
    end

    describe 'when the environment variable is present' do
      before { ENV['OTEL_RESOURCE_ATTRIBUTES'] = 'key1=value1,key2=value2' }
      after { ENV['OTEL_RESOURCE_ATTRIBUTES'] = nil }
      let(:expected_resource_labels) do
        {
          'key1' => 'value1',
          'key2' => 'value2'
        }
      end
      it 'returns an empty resource' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_labels).must_equal(expected_resource_labels)
      end
    end
  end
end
