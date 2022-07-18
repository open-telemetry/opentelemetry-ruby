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
        # The ParentConsistentProbabilityBased sampler is meant as an optional
        # replacement for the ParentBased sampler. It is required to first validate
        # the tracestate and then respect the sampled flag in the W3C traceparent.
        #
        # The ParentConsistentProbabilityBased Sampler constructor takes a single
        # Sampler argument, which is the Sampler to use in case the
        # ParentConsistentProbabilityBased Sampler is called for a root span.
        class ParentConsistentProbabilityBased
          include ConsistentProbabilityTraceState

          def initialize(root)
            @root = root
          end

          def ==(other)
            @root == other.root
          end

          # @api private
          #
          # See {Samplers}.
          def description
            "ParentConsistentProbabilityBased{root=#{@root.description}}"
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            parent_span_context = OpenTelemetry::Trace.current_span(parent_context).context
            if !parent_span_context.valid?
              @root.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
            else
              tracestate = sanitized_tracestate(parent_span_context)
              if parent_span_context.trace_flags.sampled?
                Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
              else
                Result.new(decision: Decision::DROP, tracestate: tracestate)
              end
            end
          end

          protected

          attr_reader :root

          private

          # sanitized_tracestate returns an OpenTelemetry Tracestate object with the
          # tracestate sanitized according to the Context invariants defined in the
          # tracestate probability sampling spec.
          #
          # @param span_context [OpenTelemetry::Trace::SpanContext] the parent span context
          # @return [OpenTelemetry::Trace::Tracestate] the sanitized tracestate
          def sanitized_tracestate(span_context)
            sampled = span_context.trace_flags.sampled?
            tracestate = span_context.tracestate
            parse_ot_vendor_tag(tracestate) do |p, r, rest|
              if !r.nil? && r > 62
                p = r = nil
              elsif !p.nil? && p > 63
                p = nil
              elsif !p.nil? && !r.nil? && !invariant(p, r, sampled)
                p = nil
              else
                return tracestate
              end
              update_tracestate(tracestate, p, r, rest)
            end
          end
        end
      end
    end
  end
end
