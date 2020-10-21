# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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
      PADDING = '0' * 16
      private_constant :DEBUG_CONTEXT_KEY, :PADDING

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

      # @api private
      # Convert an id from a hex encoded string to byte array, optionally left
      # padding to the correct length. Assumes the input id has already been
      # validated to be 16 or 32 characters in length.
      def to_trace_id(hex_id)
        if hex_id.length == 32
          Array(hex_id).pack('H*')
        else
          [0, hex_id].pack('qH*')
        end
      end

      # @api private
      # Convert an id from a hex encoded string to byte array.
      def to_span_id(hex_id)
        Array(hex_id).pack('H*')
      end
    end
  end
end

require_relative './b3/version'
require_relative './b3/multi'
require_relative './b3/single'
