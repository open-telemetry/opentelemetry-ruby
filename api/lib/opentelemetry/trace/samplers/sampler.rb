# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Samplers
      # {Sampler} is an abstract class that defines the Sampler interface and
      # provides functionality to type check arguments
      class Sampler
        # Returns the sampling {Decision} for a {Span} to be created
        #
        # @param [SpanContext] span_context The {SpanContext} of a parent span,
        #   typically extracted from the wire. Can be nil for a root span.
        # @param [Boolean] extracted_context True if span_context was extracted
        #   from the wire. Can be nil for a root span.
        # @param [Integer] trace_id The trace_id of the {Span} to be created
        # @param [Integer] span_id The span_id of the {Span} to be created
        # @param [String] span_name Name of the {Span} to be created
        # @param [Enumerable<Link>] links A collection of links to be associated
        #   with the {Span} to be created. Can be nil.
        # @return [Decision] The sampling decision
        def should_sample(span_context: nil,
                          extracted_context: nil,
                          trace_id:,
                          span_id:,
                          span_name:,
                          links: nil)
          raise NotImplementedError, 'subclasses must implement a `should_sample` method'
        end

        # Returns a description of the sampler
        #
        # @return [String]
        def description
          raise NotImplementedError, 'subclasses must implement a `description` method'
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def check_arguments(span_context: nil,
                            extracted_context: nil,
                            trace_id:,
                            span_id:,
                            span_name:,
                            links: nil)
          raise ArgumentError, "expected span_context to be a SpanContext, not #{span_context.class}" if span_context && !span_context.is_a?(SpanContext)
          raise ArgumentError, "expected extracted_context to be a Boolean, not #{extracted_context.class}" if !extracted_context.nil? && !Internal.boolean?(extracted_context)
          raise ArgumentError, "expected trace_id to be an Integer, not #{trace_id.class}" unless trace_id.is_a?(Integer)
          raise ArgumentError, "expected span_id to be an Integer, not #{span_id.class}" unless span_id.is_a?(Integer)
          raise ArgumentError, "expected span_name to be a String, not #{span_name.class}" unless span_name.is_a?(String)
          raise ArgumentError, 'expected links to be an Enumerable' if links && !links.class.include?(Enumerable)
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      end
    end
  end
end
