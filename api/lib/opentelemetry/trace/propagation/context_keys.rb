# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Propagation
      # Contains the keys used to store the current span, or extracted span
      # context in a {Context} instance
      module ContextKeys
        extend self

        # Returns the context key that an extracted span context is stored under
        #
        # @return [String]
        def extracted_span_context_key
          'extracted-span-context'
        end

        # Returns the context key that the current span is stored under
        #
        # @return [String]
        def current_span_key
          'current-span'
        end
      end
    end
  end
end
