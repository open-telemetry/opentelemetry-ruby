# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Resources
      module Detectors
        # Telemetry contains detect class method for determining instrumentation resource labels
        module Telemetry
          extend self

          def detect
            resource_labels = {}
            resource_labels[TELEMETRY_SDK_RESOURCE[:name]] = 'OpenTelemetry'
            resource_labels[TELEMETRY_SDK_RESOURCE[:language]] = 'ruby'
            resource_labels[TELEMETRY_SDK_RESOURCE[:version]] = "semver:#{OpenTelemetry::SDK::VERSION}"
            Resource.create(resource_labels)
          end
        end
      end
    end
  end
end
