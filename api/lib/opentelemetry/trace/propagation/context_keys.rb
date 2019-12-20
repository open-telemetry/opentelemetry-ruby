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

        EXTRACTED_SPAN_CONTEXT_KEY = 'extracted-span-context'
        CURRENT_SPAN_KEY = 'current-span'

        private_constant :EXTRACTED_SPAN_CONTEXT_KEY, :CURRENT_SPAN_KEY

        def extracted_span_context_key
          EXTRACTED_SPAN_CONTEXT_KEY
        end

        def current_span_key
          CURRENT_SPAN_KEY
        end
      end
    end
  end
end
