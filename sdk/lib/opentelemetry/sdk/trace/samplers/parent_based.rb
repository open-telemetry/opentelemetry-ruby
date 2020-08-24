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
        # This is a composite sampler. ParentBased helps distinguished between the
        # following cases:
        #   * No parent (root span).
        #   * Remote parent (SpanContext.remote? with trace_flags.sampled?)
        #   * Remote parent (SpanContext.remote? with !trace_flags.sampled?)
        #   * Local parent (!SpanContext.remote? with trace_flags.sampled?)
        #   * Local parent (!SpanContext.remote? with !trace_flags.sampled?)
        class ParentBased
          def initialize(root, remote_parent_sampled, remote_parent_not_sampled, local_parent_sampled, local_parent_not_sampled)
            @root = root
            @remote_parent_sampled = remote_parent_sampled
            @remote_parent_not_sampled = remote_parent_not_sampled
            @local_parent_sampled = local_parent_sampled
            @local_parent_not_sampled = local_parent_not_sampled
          end

          # @api private
          #
          # See {Samplers}.
          def description
            "ParentBased{root=#{@root.description}, remote_parent_sampled=#{@remote_parent_sampled.description}, remote_parent_not_sampled=#{@remote_parent_not_sampled.description}, local_parent_sampled=#{@local_parent_sampled.description}, local_parent_not_sampled=#{@local_parent_not_sampled.description}}"
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            delegate = if parent_context.nil?
                         @root
                       elsif parent_context.remote?
                         parent_context.trace_flags.sampled? ? @remote_parent_sampled : @remote_parent_not_sampled
                       else
                         parent_context.trace_flags.sampled? ? @local_parent_sampled : @local_parent_not_sampled
                       end
            delegate.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
          end
        end
      end
    end
  end
end
