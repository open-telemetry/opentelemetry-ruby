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
          parent_context = Context.empty
          parent_span = Span::INVALID
          @tracer_provider.internal_create_span(name, kind, attributes, links, start_timestamp, parent_context, parent_span, @instrumentation_library)
        end

        def start_span(name, with_parent: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          parent_context = with_parent || Context.current
          parent_span = OpenTelemetry::Trace.current_span(parent_context)
          @tracer_provider.internal_create_span(name, kind, attributes, links, start_timestamp, parent_context, parent_span, @instrumentation_library)
        end
      end
    end
  end
end
