# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # The Export module contains the built-in exporters and span processors for the OpenTelemetry
      # reference implementation.
      module Export
        # Raised when an export fails; spans are available via :spans accessor
        class ExportError < OpenTelemetry::Error
          # Returns the {Span} array for this exception
          #
          # @return [Array<OpenTelemetry::SDK::Trace::Span>]
          attr_reader :spans, :error

          # @param [Array<OpenTelemetry::SDK::Trace::Span>] spans the array of spans that failed to export
          def initialize(spans)
            super("Unable to export #{spans.size} spans")
            @spans = spans
            @error = error
          end
        end

        # ExportResult encapsulates the result of an export operation with optional error context.
        # It maintains backwards compatibility by responding to integer comparisons.
        class ExportResult
          attr_reader :code, :error, :message

          # @param code [Integer] The result code (SUCCESS, FAILURE, or TIMEOUT)
          # @param error [Exception, nil] Optional exception that caused the failure
          # @param message [String, nil] Optional error message
          def initialize(code, error: nil, message: nil)
            @code = code
            @error = error
            @message = message
          end

          # Enables backwards compatibility with integer comparisons
          # @param other [Integer, ExportResult] value to compare against
          # @return [Boolean]
          def ==(other)
            case other
            when Integer
              @code == other
            when ExportResult
              @code == other.code
            else
              super
            end
          end

          # @return [Integer] the result code
          def to_i
            @code
          end

          # @return [Boolean] true if the export was successful
          def success?
            @code == SUCCESS
          end

          # @return [Boolean] true if the export failed
          def failure?
            @code == FAILURE
          end
        end

        # Result codes for the SpanExporter#export method and the SpanProcessor#force_flush and SpanProcessor#shutdown methods.

        # The operation finished successfully.
        SUCCESS = 0

        # The operation finished with an error.
        FAILURE = 1

        # Additional result code for the SpanProcessor#force_flush and SpanProcessor#shutdown methods.

        # The operation timed out.
        TIMEOUT = 2

        # Factory method for creating a success result
        # @return [ExportResult]
        def self.success
          ExportResult.new(SUCCESS)
        end

        # Factory method for creating a failure result with optional error context
        # @param error [Exception, nil] Optional exception that caused the failure
        # @param message [String, nil] Optional error message
        # @return [ExportResult]
        def self.failure(error: nil, message: nil)
          ExportResult.new(FAILURE, error: error, message: message)
        end

        # Factory method for creating a timeout result
        # @return [ExportResult]
        def self.timeout
          ExportResult.new(TIMEOUT)
        end
      end
    end
  end
end

require 'opentelemetry/sdk/trace/export/batch_span_processor'
require 'opentelemetry/sdk/trace/export/console_span_exporter'
require 'opentelemetry/sdk/trace/export/in_memory_span_exporter'
require 'opentelemetry/sdk/trace/export/metrics_reporter'
require 'opentelemetry/sdk/trace/export/span_exporter'
require 'opentelemetry/sdk/trace/export/simple_span_processor'
