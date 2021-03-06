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
      BAGGAGE_HEADER_PREFIX = 'ot-baggage-'

      # TODO: Is this documented in a specification somewhere? Does check need to happen in all injectors?
      # Taken from JS implementation https://github.com/open-telemetry/opentelemetry-js-contrib/blob/7a87f4105ff432380132d81f56a33e3f5c4e8fb1/propagators/opentelemetry-propagator-ot-trace/src/OTTracePropagator.ts#L53
      VALID_BAGGAGE_HEADER_NAME_CHARS = /^[\^_`a-zA-Z\-0-9!#$%&'*+.|~]+$/.freeze
      # https://github.com/open-telemetry/opentelemetry-js-contrib/blob/7a87f4105ff432380132d81f56a33e3f5c4e8fb1/propagators/opentelemetry-propagator-ot-trace/src/OTTracePropagator.ts#L59
      INVALID_BAGGAGE_HEADER_VALUE_CHARS = /[^\t\u0020-\u007E\u0080-\u00FF]/.freeze
    end
  end
end
