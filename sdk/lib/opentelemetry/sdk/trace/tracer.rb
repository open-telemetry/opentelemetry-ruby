# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer < OpenTelemetry::Trace::Tracer
        # @api private
        #
        # Returns a new {Tracer} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [TracerProvider] tracer_provider TracerProvider that initialized the tracer
        #
        # @return [Tracer]
        def initialize(name, version, tracer_provider)
          @instrumentation_library = InstrumentationLibrary.new(name, version)
          @tracer_provider = tracer_provider
        end

        def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          start_span(name, with_parent: Context.empty, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind)
        end

        def start_span(name, with_parent: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          name ||= 'empty'

          with_parent ||= Context.current
          parent_span_context = OpenTelemetry::Trace.current_span(with_parent).context
          if parent_span_context.valid?
            parent_span_id = parent_span_context.span_id
            trace_id = parent_span_context.trace_id
          end
          @tracer_provider.internal_create_span(name, kind, trace_id, parent_span_id, attributes, links, start_timestamp, with_parent, @instrumentation_library)
        end
      end
    end
  end
end
