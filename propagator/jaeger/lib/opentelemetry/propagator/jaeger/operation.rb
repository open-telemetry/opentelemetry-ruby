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
    # Namespace for OpenTelemetry Jaeger propagation
    module Jaeger
      # Common superclass for classes that perform propagator operations, i.e.
      # TextMapExtractor and TextMapInjector
      class Operation
        IDENTITY_KEY = 'uber-trace-id'
        DEFAULT_FLAG_BIT = 0x0
        SAMPLED_FLAG_BIT = 0x01
        DEBUG_FLAG_BIT   = 0x02

        private_constant :IDENTITY_KEY, :DEFAULT_FLAG_BIT, :SAMPLED_FLAG_BIT, :DEBUG_FLAG_BIT

        private

        def debug_flag_bit
          DEBUG_FLAG_BIT
        end

        def default_flag_bit
          DEFAULT_FLAG_BIT
        end

        def identity_key
          IDENTITY_KEY
        end

        def sampled_flag_bit
          SAMPLED_FLAG_BIT
        end
      end
    end
  end
end
