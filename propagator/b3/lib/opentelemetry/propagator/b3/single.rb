# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative './single/text_map_propagator'

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
      # Namespace for OpenTelemetry B3 single header encoding
      module Single
        extend self

        TEXT_MAP_PROPAGATOR = TextMapPropagator.new

        private_constant :TEXT_MAP_PROPAGATOR

        # Returns a text map propagator that propagates context using the
        # B3 single header format.
        def text_map_propagator
          TEXT_MAP_PROPAGATOR
        end
      end
    end
  end
end
