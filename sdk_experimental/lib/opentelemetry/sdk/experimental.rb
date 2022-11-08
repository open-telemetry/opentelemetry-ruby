# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Experimental module contains experimental extensions to the OpenTelemetry reference
    # implementation.
    module Experimental
    end
  end
end

require 'opentelemetry/sdk/experimental/samplers_patch'
require 'opentelemetry/sdk/trace/propagation/trace_context/response_text_map_propagator'
