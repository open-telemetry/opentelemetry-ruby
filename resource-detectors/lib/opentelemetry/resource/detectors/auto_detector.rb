# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resource
    module Detectors
      # AutoDetector contains detect class method for running all detectors
      module AutoDetector
        extend self

        DETECTORS = [
          OpenTelemetry::Resource::Detectors::GoogleCloudPlatform
        ].freeze

        def detect
          resources = DETECTORS.map(&:detect)
          resources.reduce(OpenTelemetry::SDK::Resources::Resource.create) do |accumulated, detected|
            accumulated.merge(detected)
          end
        end
      end
    end
  end
end
