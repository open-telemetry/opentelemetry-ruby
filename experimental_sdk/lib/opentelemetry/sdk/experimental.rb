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

# TODO: I don't think this is quite the way to do this - we should only add if neither is present.
require 'opentelemetry/sdk/trace/samplers_patch' unless (OpenTelemetry::SDK::Trace::Samplers.singleton_methods & %i[consistent_probability_based parent_consistent_probability_based]).empty?
