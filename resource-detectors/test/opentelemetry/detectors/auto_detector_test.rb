# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::AutoDetector do
  let(:auto_detector) { OpenTelemetry::Resource::Detectors::AutoDetector }
  let(:detected_resource) { auto_detector.detect }
  let(:detected_resource_labels) { detected_resource.label_enumerator.to_h }
  let(:expected_resource_labels) { {} }

  describe '.detect' do
    it 'returns detected resources' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_labels).must_equal(expected_resource_labels)
    end
  end
end
