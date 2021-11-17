# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resource
    module Detectors
      # AutoDetector contains detect class method for running all detectors
      module AutoDetector
        extend self

        DETECTORS = [
          OpenTelemetry::Resource::Detectors::GoogleCloudPlatform,
          OpenTelemetry::Resource::Detectors::Deployment
        ].freeze

        def detect
          DETECTORS.map(&:detect).reduce(:merge)
        end
      end
    end
  end
end
