# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # The manually specified tracer provider configuring for the SDK to use.
      class TracerProviderConfig
        attr_accessor :sampler, :id_generator, :span_limits, :span_processors

        def initialize
          @span_processors = []
        end

        def add_span_processor(processor)
          @span_processors << processor
        end
      end
    end
  end
end
