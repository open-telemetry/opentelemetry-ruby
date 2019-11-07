# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Propagation
      # @todo add module documentation
      module ContextKeys
        extend self

        SPAN_CONTEXT_KEY = 'span-context'
        private_constant(:SPAN_CONTEXT_KEY)

        def span_context_key
          SPAN_CONTEXT_KEY
        end
      end
    end
  end
end
