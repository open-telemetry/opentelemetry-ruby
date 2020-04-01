# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # The Propagation class provides methods to inject and extract context
      # to pass across process boundaries
      class Propagation
        # Get or set the global http propagator. Use a CompositePropagator
        # to propagate multiple formats.
        attr_accessor :http

        # Get or set the global text propagator. Use a CompositePropagator
        # to propagate multiple formats.
        attr_accessor :text

        def initialize
          @http = @text = Propagator.new(NoopInjector.new, NoopExtractor.new)
        end
      end
    end
  end
end
