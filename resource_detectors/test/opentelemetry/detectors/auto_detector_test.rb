# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::AutoDetector do
  let(:auto_detector) { OpenTelemetry::Resource::Detectors::AutoDetector }
  let(:detected_resource) { auto_detector.detect }
  let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
  let(:expected_resource_attributes) { {} }

  describe '.detect' do
    it 'returns detected resources' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end
  end
end
