# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative './jaeger/text_map_extractor'
require_relative './jaeger/text_map_injector'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry Jaeger propagation
    module Jaeger
      extend self

      DEBUG_CONTEXT_KEY = Context.create_key('jaeger-debug-key')
      private_constant :DEBUG_CONTEXT_KEY

      TEXT_MAP_EXTRACTOR = TextMapExtractor.new
      TEXT_MAP_INJECTOR = TextMapInjector.new

      private_constant :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR

      IDENTITY_KEY = 'uber-trace-id'
      DEFAULT_FLAG_BIT = 0x0
      SAMPLED_FLAG_BIT = 0x01
      DEBUG_FLAG_BIT   = 0x02

      private_constant :IDENTITY_KEY, :DEFAULT_FLAG_BIT, :SAMPLED_FLAG_BIT, :DEBUG_FLAG_BIT

      # Returns an extractor that extracts context in the Jaeger single header
      # format
      def text_map_injector
        TEXT_MAP_INJECTOR
      end

      # Returns an injector that injects context in the Jaeger single header
      # format
      def text_map_extractor
        TEXT_MAP_EXTRACTOR
      end

      # @api private
      # Returns a new context with the jaeger debug flag enabled
      def context_with_debug(context)
        context.set_value(DEBUG_CONTEXT_KEY, true)
      end

      # @api private
      # Read the Jaeger debug flag from the provided context
      def debug?(context)
        !context.value(DEBUG_CONTEXT_KEY).nil?
      end
    end
  end
end
