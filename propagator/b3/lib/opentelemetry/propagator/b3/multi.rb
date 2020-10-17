# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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
  module Propagator
    # Namespace for OpenTelemetry propagator extension libraries
    module B3
      # Namespace for OpenTelemetry b3 multi header encoding
      module Multi
        extend self

        TEXT_MAP_EXTRACTOR = TextMapExtractor.new
        TEXT_MAP_INJECTOR = TextMapInjector.new
        RACK_KEYS = {
          b3_trace_id_key: 'HTTP_X_B3_TRACEID',
          b3_span_id_key: 'HTTP_X_B3_SPANID',
          b3_sampled_key: 'HTTP_X_B3_SAMPLED',
          b3_flags_key: 'HTTP_X_B3_FLAGS'
        }.freeze
        RACK_EXTRACTOR = TextMapExtractor.new(**RACK_KEYS)
        RACK_INJECTOR = TextMapInjector.new(**RACK_KEYS)

        private_constant :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR, :RACK_INJECTOR,
                         :RACK_EXTRACTOR, :RACK_KEYS

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

        # Returns an extractor that extracts context in the B3 multi header
        # format with Rack normalized keys (upcased and prefixed with
        # HTTP_)
        def rack_injector
          RACK_INJECTOR
        end

        # Returns an injector that injects context in the B3 multi header
        # format with Rack normalized keys (upcased and prefixed with
        # HTTP_)
        def rack_extractor
          RACK_EXTRACTOR
        end
      end
    end
  end
end
