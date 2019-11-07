# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    module Propagation
      # @todo add module documentation
      module ContextKeys
        extend self

        BAGGAGE_KEY = 'baggage'
        private_constant(:BAGGAGE_KEY)

        def span_context_key
          BAGGAGE_KEY
        end
      end
    end
  end
end
