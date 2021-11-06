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

require_relative './xray/text_map_propagator'

module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      extend self

      DEBUG_CONTEXT_KEY = Context.create_key('xray-debug-key')
      TEXT_MAP_PROPAGATOR = TextMapPropagator.new
      private_constant :DEBUG_CONTEXT_KEY, :TEXT_MAP_PROPAGATOR

      # @api private
      # Returns a new context with the xray debug flag enabled
      def context_with_debug(context)
        context.set_value(DEBUG_CONTEXT_KEY, true)
      end

      # @api private
      # Read the XRay debug flag from the provided context
      def debug?(context)
        !context.value(DEBUG_CONTEXT_KEY).nil?
      end

      # Returns a text map propagator that propagates context in the XRay
      # format.
      def text_map_propagator
        TEXT_MAP_PROPAGATOR
      end
    end
  end
end

require_relative './xray/version'
require_relative './xray/id_generator'
