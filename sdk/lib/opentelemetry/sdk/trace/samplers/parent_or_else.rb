# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # This is a composite sampler. It either respects the parent span's sampling
        # decision or delegates to delegate_sampler for root spans.
        class ParentOrElse
          def initialize(delegate_sampler)
            @delegate_sampler = delegate_sampler
          end

          # @api private
          #
          # See {Samplers}.
          def description
            "ParentOrElse{#{@delegate_sampler.description}}"
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            if parent_context.nil?
              @delegate_sampler.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
            elsif parent_context.trace_flags.sampled?
              RECORD_AND_SAMPLED
            else
              NOT_RECORD
            end
          end
        end
      end
    end
  end
end
