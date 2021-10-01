# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    class Settings
      DEFAULT_SETTINGS = {}.freeze

      private_constant :DEFAULT_SETTINGS

      def defaults
        DEFAULT_SETTINGS
      end
    end
  end
end