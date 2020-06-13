# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # Implements a sampler returning a constant result.
        class ConstantSampler
          attr_reader :description

          def initialize(result:, description:)
            @result = result
            @description = description
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            # All arguments ignored for sampling decision.
            @result
          end
        end
      end
    end
  end
end
