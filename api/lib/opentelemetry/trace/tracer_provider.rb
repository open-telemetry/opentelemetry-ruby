# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of a tracer provider.
    class TracerProvider
      # Returns a {Tracer} instance.
      #
      # Supports both positional arguments (legacy) and keyword arguments:
      #   tracer('name', '1.0')                                    # legacy positional
      #   tracer(name: 'name', version: '1.0', attributes: {...})  # keyword
      #
      # When both positional and keyword arguments are provided for the same
      # parameter, the keyword argument takes precedence.
      #
      # @param [String] name Instrumentation scope name
      # @param [String] version Instrumentation scope version
      # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
      #   Instrumentation scope attributes
      #
      # @return [Tracer]
      def tracer(deprecated_name = nil, deprecated_version = nil, name: nil, version: nil, attributes: nil)
        @tracer ||= Tracer.new
      end
    end
  end
end
