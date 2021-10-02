# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module InstrumentationHelpers
    module HTTP
      # InstrumentationOptions contains instrumentation helpers for http instrumentation client requests
      module InstrumentationOptions
        def self.included(base)
          base.include(ClassMethods)
        end

        # ClassMethods contains inheritable default settings for http client instrumentation
        module ClassMethods
          DEFAULT_SETTINGS = {
            hide_query_params: { default: true, validate: :boolean }
          }.freeze

          def defaults
            super.merge(DEFAULT_SETTINGS)
          end
        end
      end
    end
  end
end
