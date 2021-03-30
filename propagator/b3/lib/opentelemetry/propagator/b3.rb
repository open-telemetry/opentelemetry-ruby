# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

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
      extend self

      DEBUG_CONTEXT_KEY = Context.create_key('b3-debug-key')
      private_constant :DEBUG_CONTEXT_KEY

      # @api private
      # Returns a new context with the b3 debug flag enabled
      def context_with_debug(context)
        context.set_value(DEBUG_CONTEXT_KEY, true)
      end

      # @api private
      # Read the B3 debug flag from the provided context
      def debug?(context)
        context.value(DEBUG_CONTEXT_KEY)
      end
    end
  end
end

require_relative './b3/version'
require_relative './b3/text_map_extractor'
require_relative './b3/multi'
require_relative './b3/single'
