# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'
require 'opentelemetry/propagator/ottrace/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry OTTrace propagation
    module OTTrace
      extend self

      TRACE_ID_HEADER = 'ot-tracer-traceid'
      SPAN_ID_HEADER = 'ot-tracer-spanid'
      SAMPLED_HEADER = 'ot-tracer-sampled'
      BAGGAGE_HEADER_PREFIX = 'ot-baggage-'

      # https://github.com/open-telemetry/opentelemetry-specification/blob/14d123c121b6caa53bffd011292c42a181c9ca26/specification/context/api-propagators.md#textmap-propagator0
      VALID_BAGGAGE_HEADER_NAME_CHARS = /^[\^_`a-zA-Z\-0-9!#$%&'*+.|~]+$/.freeze
      INVALID_BAGGAGE_HEADER_VALUE_CHARS = /[^\t\u0020-\u007E\u0080-\u00FF]/.freeze

      ## Returns an extractor that extracts context from OTTrace carrier
      def text_map_extractor
        TextMapExtractor.new
      end

      ## Returns an injector that injects context into a carrier
      def text_map_injector
        TextMapInjector.new
      end
    end
  end
end

require_relative './ottrace/text_map_injector'
require_relative './ottrace/text_map_extractor'
