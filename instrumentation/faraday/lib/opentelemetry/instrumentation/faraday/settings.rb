# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      # The Settings class contains logic to generate the appropriate
      # Faraday default settings
      class Settings < OpenTelemetry::Instrumentation::Settings
        include InstrumentationHelpers::HTTP::InstrumentationOptions

        DEFAULT_SETTINGS = {
          'peer_service' => { default: nil, validate: :string }
        }.freeze

        def defaults
          super.merge(DEFAULT_SETTINGS)
        end
      end
    end
  end
end
