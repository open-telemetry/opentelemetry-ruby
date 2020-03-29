# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/propagation/trace_context/trace_parent'
require 'opentelemetry/trace/propagation/trace_context/text_extractor'
require 'opentelemetry/trace/propagation/trace_context/text_injector'

module OpenTelemetry
  module Trace
    module Propagation
      # The TraceContext module contains injectors, extractors, and utilties
      # for context propagation in the W3C Trace Context format.
      module TraceContext
        extend self

        TEXT_EXTRACTOR = TextExtractor.new
        TEXT_INJECTOR = TextInjector.new
        RACK_EXTRACTOR = TextExtractor.new(
          traceparent_header_key: 'HTTP_TRACEPARENT',
          tracestate_header_key: 'HTTP_TRACESTATE'
        )
        RACK_INJECTOR = TextInjector.new(
          traceparent_header_key: 'HTTP_TRACEPARENT',
          tracestate_header_key: 'HTTP_TRACESTATE'
        )

        private_constant :TEXT_INJECTOR, :TEXT_EXTRACTOR,
                         :RACK_INJECTOR, :RACK_EXTRACTOR

        # Returns an extractor that extracts context using the W3C Trace Context
        # format
        def text_extractor
          TEXT_EXTRACTOR
        end

        # Returns an injector that injects context using the W3C Trace Context
        # format
        def text_injector
          TEXT_INJECTOR
        end

        # Returns an extractor that extracts context using the W3C Trace Context
        # with Rack normalized keys (upcased and prefixed with HTTP_)
        def rack_extractor
          RACK_EXTRACTOR
        end

        # Returns an injector that injects context using the W3C Trace Context
        # format with Rack normalized keys (upcased and prefixed with HTTP_)
        def rack_injector
          RACK_INJECTOR
        end
      end
    end
  end
end
