# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module InstrumentationHelpers
    module HTTP
      # Instrumentation options contains instrumentation helpers for http instrumentation client requests
      module InstrumentationOptions

        def self.included(klass)
          klass.option :hide_query_params, default: true, validate: :boolean if klass.respond_to?(:option)
        end
      end
    end
  end
end
