# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/propagation/trace_context/trace_parent'
require 'opentelemetry/trace/propagation/trace_context/text_map_extractor'
require 'opentelemetry/trace/propagation/trace_context/text_map_injector'

module OpenTelemetry
  module Trace
    module Propagation
      # The TraceContext module contains injectors, extractors, and utilties
      # for context propagation in the W3C Trace Context format.
      module TraceContext
        extend self
        TRACEPARENT_KEY = 'traceparent'
        TRACESTATE_KEY = 'tracestate'
        TEXT_MAP_EXTRACTOR = TextMapExtractor.new
        TEXT_MAP_INJECTOR = TextMapInjector.new

        private_constant :TRACEPARENT_KEY, :TRACESTATE_KEY,
                         :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR

        # Returns an extractor that extracts context using the W3C Trace Context
        # format
        def text_map_extractor
          TEXT_MAP_EXTRACTOR
        end

        # Returns an injector that injects context using the W3C Trace Context
        # format
        def text_map_injector
          TEXT_MAP_INJECTOR
        end
      end
    end
  end
end
