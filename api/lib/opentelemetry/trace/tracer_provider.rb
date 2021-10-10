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
      # @param [optional String] name Instrumentation package name
      # @param [optional String] version Instrumentation package version
      # @param [optional String] schema_url Instrumentation package schema_url of the emitted telemetry
      #
      # @return [Tracer]
      def tracer(name = nil, version = nil, schema_url = nil)
        @tracer ||= Tracer.new
      end
    end
  end
end
