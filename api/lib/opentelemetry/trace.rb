# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/samplers'
require 'opentelemetry/trace/span_context'
require 'opentelemetry/trace/span_kind'
require 'opentelemetry/trace/span'
require 'opentelemetry/trace/status'
require 'opentelemetry/trace/trace_flags'
require 'opentelemetry/trace/tracer'

module OpenTelemetry
  # The Trace API allows recording a set of events, triggered as a result of a
  # single logical operation, consolidated across various components of an
  # application.
  module Trace
    INVALID_TRACE_ID = '0' * 32
    INVALID_SPAN_ID = '0' * 16

    private_constant(:INVALID_TRACE_ID, :INVALID_SPAN_ID)

    # Generates a valid trace identifier, a 16-byte array with at least one
    # non-zero byte, encoded as a hexadecimal string.
    #
    # @return [String] a hexadecimal string encoding of a valid trace ID.
    def generate_trace_id
      loop do
        id = Random::DEFAULT.bytes(16).unpack1('H*')
        return id unless id == INVALID_TRACE_ID
      end
    end

    # Generates a valid span identifier, an 8-byte array with at least one
    # non-zero byte, encoded as a hexadecimal string.
    #
    # @return [String] a hexadecimal string encoding of a valid span ID.
    def generate_span_id
      loop do
        id = Random::DEFAULT.bytes(8).unpack1('H*')
        return id unless id == INVALID_SPAN_ID
      end
    end
  end
end
