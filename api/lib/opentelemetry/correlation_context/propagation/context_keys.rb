# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module CorrelationContext
    module Propagation
      # The ContextKeys module contains the keys used to store correlations
      # in a {Context} instance
      module ContextKeys
        extend self

        # Returns the context key that correlations are stored under
        #
        # @return [String]
        def correlation_context_key
          'correlation-context'
        end
      end
    end
  end
end
