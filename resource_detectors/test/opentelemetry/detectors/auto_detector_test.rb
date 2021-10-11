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
  let(:detected_resource_schema_url) { detected_resource.schema_url.to_s }
  let(:expected_resource_schema_url) { "https://opentelemetry.io/schemas/#{OpenTelemetry::SemanticConventions::VERSION}" }

  describe '.detect' do
    it 'returns detected resources' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
      _(detected_resource_schema_url).must_equal(expected_resource_schema_url)
    end
  end
end
