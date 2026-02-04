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
      # @param [optional String] schema_url Specifies the Schema URL
      # @param [optional Hash] attributes Specifies the scope attributes
      #
      # @return [Tracer]
      def tracer(name = nil, version = nil, schema_url = nil, attributes = nil)
        @tracer ||= Tracer.new
      end
    end
  end
end
