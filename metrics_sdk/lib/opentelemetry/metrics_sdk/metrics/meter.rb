# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module MetricsSDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {Meter} is the SDK implementation of {OpenTelemetry::Metrics::Meter}.
      class Meter < OpenTelemetry::Metrics::Meter
        # @api private
        #
        # Returns a new {Meter} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [TracerProvider] tracer_provider TracerProvider that initialized the tracer
        #
        # @return [Tracer]
        def initialize(name, version)
          @mutex = Mutex.new
          @registry = {}
          @instrumentation_library = InstrumentationLibrary.new(name, version)
        end

        def create_counter(name, unit: nil, description: nil)
          create_instrument(:counter, name, unit, description, nil) { OpenTelemetry::MetricsSDK::Metrics::Instrument::Counter.new }
        end
      end
    end
  end
end
