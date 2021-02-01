# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative './multi/text_map_extractor'
require_relative './multi/text_map_injector'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry B3 propagation
    module B3
      # Namespace for OpenTelemetry b3 multi header encoding
      module Multi
        extend self

        B3_TRACE_ID_KEY = 'X-B3-TraceId'
        B3_SPAN_ID_KEY = 'X-B3-SpanId'
        B3_SAMPLED_KEY = 'X-B3-Sampled'
        B3_FLAGS_KEY = 'X-B3-Flags'
        TEXT_MAP_EXTRACTOR = TextMapExtractor.new
        TEXT_MAP_INJECTOR = TextMapInjector.new

        private_constant :B3_TRACE_ID_KEY, :B3_SPAN_ID_KEY, :B3_SAMPLED_KEY,
                         :B3_FLAGS_KEY, :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR

        # Returns an extractor that extracts context in the B3 multi header
        # format
        def text_map_injector
          TEXT_MAP_INJECTOR
        end

        # Returns an injector that injects context in the B3 multi header
        # format
        def text_map_extractor
          TEXT_MAP_EXTRACTOR
        end
      end
    end
  end
end
