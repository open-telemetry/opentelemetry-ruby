# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module MetricsSDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {MeterProvider} is the SDK implementation of {OpenTelemetry::Metrics::MeterProvider}.
      class MeterProvider < OpenTelemetry::Metrics::MeterProvider
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        def initialize
          @registry = {}
          @registry_mutex = Mutex.new
        end

        # Returns a {Meter} instance.
        #
        # @param [optional String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Meter]
        def meter(name = nil, version = nil)
          name ||= ''
          version ||= ''
          OpenTelemetry.logger.warn 'calling MeterProvider#meter without providing a meter name.' if name.empty?
          @registry_mutex.synchronize { @registry[Key.new(name, version)] ||= Meter.new(name, version) }
        end
      end
    end
  end
end
