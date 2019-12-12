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

        REMOTE_SPAN_CONTEXT_KEY = 'remote-span-context'
        CURRENT_SPAN_KEY = 'current-span'

        private_constant :REMOTE_SPAN_CONTEXT_KEY, :CURRENT_SPAN_KEY

        def remote_span_context_key
          REMOTE_SPAN_CONTEXT_KEY
        end

        def current_span_key
          CURRENT_SPAN_KEY
        end
      end
    end
  end
end
