# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # The Trace API allows recording a set of events, triggered as a result of a
  # single logical operation, consolidated across various components of an
  # application.
  module Trace
    # An invalid trace identifier, a 16-byte string with all zero bytes.
    INVALID_TRACE_ID = ("\0" * 16).b

    # An invalid span identifier, an 8-byte string with all zero bytes.
    INVALID_SPAN_ID = ("\0" * 8).b

    # Generates a valid trace identifier, a 16-byte string with at least one
    # non-zero byte.
    #
    # @return [String] a valid trace ID.
    def self.generate_trace_id
      loop do
        id = Random::DEFAULT.bytes(16)
        return id unless id == INVALID_TRACE_ID
      end
    end

    # Generates a valid span identifier, an 8-byte string with at least one
    # non-zero byte.
    #
    # @return [String] a valid span ID.
    def self.generate_span_id
      loop do
        id = Random::DEFAULT.bytes(8)
        return id unless id == INVALID_SPAN_ID
      end
    end
  end
end

require 'opentelemetry/trace/event'
require 'opentelemetry/trace/link'
require 'opentelemetry/trace/propagation'
require 'opentelemetry/trace/trace_flags'
require 'opentelemetry/trace/span_context'
require 'opentelemetry/trace/span_kind'
require 'opentelemetry/trace/span'
require 'opentelemetry/trace/status'
require 'opentelemetry/trace/tracer'
require 'opentelemetry/trace/tracer_provider'
