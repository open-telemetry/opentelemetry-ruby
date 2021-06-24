# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/context/propagation/noop_text_map_propagator'

module OpenTelemetry
  module SDK
    class Context
      # A stub definition of the Context::Propgation module
      # for the SDK's implementation of the NoopTextMapPropagator.
      module Propagation
      end
    end
  end
end
