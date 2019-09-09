# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module DistributedContext
    module Propagation
      # A TraceParent is an implemenation of the W3C trace context specification
      # {SpanContext}
      class TraceParent
        InvalidFormatError = Class.new(Error)
        InvalidVersionError = Class.new(Error)
        InvalidTraceIDError = Class.new(Error)
        InvalidSpanIDError = Class.new(Error)

        TRACE_PARENT_HEADER = 'traceparent'
        SUPPORTED_VERSION = 0
        private_constant :SUPPORTED_VERSION
        MAX_VERSION = 254
        private_constant :MAX_VERSION

        REGEXP = /^(?<version>[A-Fa-f0-9]{2})-(?<trace_id>[A-Fa-f0-9]{32})-(?<span_id>[A-Fa-f0-9]{16})-(?<flags>[A-Fa-f0-9]{2})(?<ignored>-.*)?$/.freeze
        private_constant :REGEXP

        attr_reader :version, :trace_id, :span_id, :flags

        private_class_method :new

        def sampled?
          flags.sampled?
        end

        def to_s
          "00-#{trace_id}-#{span_id}-#{flags}"
        end

        def self.from_context(ctx)
          new(trace_id: ctx.trace_id, span_id: ctx.span_id, flags: ctx.trace_flags)
        end

        def self.from_string(string)
          matches = match_input(string)

          version = parse_version(matches[:version])
          raise InvalidFormatError if version > SUPPORTED_VERSION && string.length < 55

          trace_id = parse_trace_id(matches[:trace_id])
          span_id = parse_span_id(matches[:span_id])
          flags = parse_flags(matches[:flags])

          new(trace_id: trace_id, span_id: span_id, flags: flags)
        end

        private

        def initialize(trace_id: nil, span_id: nil, version: SUPPORTED_VERSION, flags: Trace::TraceFlags::DEFAULT)
          raise ArgumentError, 'flags must be a TraceFlags' unless flags.is_a?(Trace::TraceFlags)

          @trace_id = trace_id
          @span_id = span_id
          @version = version
          @flags = flags
        end

        class << self
          def match_input(string)
            matches = REGEXP.match(string)
            raise InvalidFormatError, 'regexp match failed' if !matches || matches.length < 6

            matches
          end

          def parse_version(string)
            v = string.to_i(16)
            raise InvalidFormatError, string unless v

            raise InvalidVersionError, v if v > MAX_VERSION

            v
          end

          def parse_trace_id(string)
            raise InvalidTraceIDError, string if string == OpenTelemetry::Trace::INVALID_TRACE_ID

            string.downcase!
            string
          end

          def parse_span_id(string)
            raise InvalidSpanIDError, string if string == OpenTelemetry::Trace::INVALID_SPAN_ID

            string.downcase!
            string
          end

          def parse_flags(string)
            OpenTelemetry::Trace::TraceFlags.from_byte(string.to_i(16))
          end
        end
      end
    end
  end
end
