# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/resources/detectors/google_cloud_platform'
require 'opentelemetry/sdk/resources/detectors/telemetry'

module OpenTelemetry
  module SDK
    module Resources
      # AutoDetector contains detect class method for running all detectors
      module AutoDetector
        extend self

        DETECTORS = [
          OpenTelemetry::SDK::Resources::Detectors::GoogleCloudPlatform,
          OpenTelemetry::SDK::Resources::Detectors::Telemetry
        ].freeze

        def detect
          resources = DETECTORS.map(&:detect)
          resources.reduce(OpenTelemetry::SDK::Resources::Resource.create) do |empty_resource, detected_resource|
            empty_resource.merge(detected_resource)
          end
        end
      end
    end
  end
end
