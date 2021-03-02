# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'
require 'opentelemetry/propagator/ottrace/version'

module OpenTelemetry
  module Propagator
    module OTTrace
      TRACE_ID_HEADER = 'ot-tracer-traceid'
      SPAN_ID_HEADER = 'ot-tracer-spanid'
      SAMPLED_HEADER = 'ot-tracer-sampled'
    end
  end
end
