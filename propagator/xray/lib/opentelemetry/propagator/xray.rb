# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.

require_relative './xray/text_map_extractor'
require_relative './xray/text_map_injector'

module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      extend self

      DEBUG_CONTEXT_KEY = Context.create_key('xray-debug-key')
      private_constant :DEBUG_CONTEXT_KEY

      # @api private
      # Returns a new context with the xray debug flag enabled
      def context_with_debug(context)
        context.set_value(DEBUG_CONTEXT_KEY, true)
      end

      # @api private
      # Read the XRay debug flag from the provided context
      def debug?(context)
        context.value(DEBUG_CONTEXT_KEY)
      end

      # @api private
      # Convert an id from a hex encoded string to byte array. Assumes the input id has already been
      # validated to be 35 characters in length.
      def to_trace_id(hex_id)
        Array(hex_id[2..8] + hex_id[10..]).pack('H*')
      end

      # @api private
      # Convert an id from a hex encoded string to byte array.
      def to_span_id(hex_id)
        Array(hex_id).pack('H*')
      end

      XRAY_CONTEXT_KEY = 'X-Amzn-Trace-Id'
      TEXT_MAP_EXTRACTOR = TextMapExtractor.new
      TEXT_MAP_INJECTOR = TextMapInjector.new

      private_constant :XRAY_CONTEXT_KEY, :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR

      # Returns an extractor that extracts context in the XRay single header
      # format
      def text_map_injector
        TEXT_MAP_INJECTOR
      end

      # Returns an injector that injects context in the XRay single header
      # format
      def text_map_extractor
        TEXT_MAP_EXTRACTOR
      end
    end
  end
end

require_relative './xray/version'
