# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative './jaeger/text_map_propagator'

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

      TEXT_MAP_PROPAGATOR = TextMapPropagator.new

      private_constant :TEXT_MAP_PROPAGATOR

      # Returns a text map propagator that propagates context in the Jaeger
      # format.
      def text_map_propagator
        TEXT_MAP_PROPAGATOR
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
