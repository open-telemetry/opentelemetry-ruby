# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of a tracer factory.
    class TracerFactory
      BINARY_FORMAT = Propagation::BinaryFormat.new
      private_constant :BINARY_FORMAT

      # Returns a {Tracer} instance.
      #
      # @param [optional String] name Instrumentation package name
      # @param [optional String] version Instrumentation package version
      #
      # @return [Tracer]
      def tracer(name = nil, version = nil)
        @tracer ||= Tracer.new
      end

      def binary_format
        BINARY_FORMAT
      end
    end
  end
end
