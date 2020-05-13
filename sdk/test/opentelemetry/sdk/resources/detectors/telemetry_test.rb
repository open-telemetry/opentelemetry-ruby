# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Resources::Detectors::Telemetry do
  let(:detector) { OpenTelemetry::SDK::Resources::Detectors::Telemetry }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_labels) { detected_resource.label_enumerator.to_h }
    let(:expected_resource_labels) do
      {
        'telemetry.sdk.name' => 'OpenTelemetry',
        'telemetry.sdk.language' => 'ruby',
        'telemetry.sdk.version' => 'semver:0.4.0'
      }
    end

    it 'returns a resource with telemetry attributes' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_labels).must_equal(expected_resource_labels)
    end
  end
end
