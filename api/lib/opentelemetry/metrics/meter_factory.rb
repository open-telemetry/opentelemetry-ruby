# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of a meter factory.
    class MeterFactory
      # Returns a {Meter} instance.
      #
      # @param [optional String] name Instrumentation package name
      # @param [optional String] version Instrumentation package version
      #
      # @return [Meter]
      def meter(name = nil, version = nil)
        @meter ||= Meter.new
      end
    end
  end
end
