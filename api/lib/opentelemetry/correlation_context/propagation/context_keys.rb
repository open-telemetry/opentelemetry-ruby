# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module CorrelationContext
    module Propagation
      # The ContextKeys module contains the keys used to index correlations
      # in a {Context} instance
      module ContextKeys
        extend self

        CORRELATION_CONTEXT_KEY = Context.create_key('correlation-context')
        private_constant :CORRELATION_CONTEXT_KEY

        # Returns the context key that correlations are indexed by
        #
        # @return [Context::Key]
        def correlation_context_key
          CORRELATION_CONTEXT_KEY
        end
      end
    end
  end
end
