# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Config
        # Class that holds global trace parameters.
        class TraceConfig
          # The global default sampler (see {Samplers}).
          attr_reader :sampler

          # The global default max number of attributes per {Span}.
          attr_reader :max_attributes_count

          # The global default max length of attribute value per {Span}.
          attr_reader :max_attributes_length

          # The global default max number of {OpenTelemetry::SDK::Trace::Event}s per {Span}.
          attr_reader :max_events_count

          # The global default max number of {OpenTelemetry::Trace::Link} entries per {Span}.
          attr_reader :max_links_count

          # The global default max number of attributes per {OpenTelemetry::SDK::Trace::Event}.
          attr_reader :max_attributes_per_event

          # The global default max number of attributes per {OpenTelemetry::Trace::Link}.
          attr_reader :max_attributes_per_link

          # Returns a {TraceConfig} with the desired values.
          #
          # @return [TraceConfig] with the desired values.
          # @raise [ArgumentError] if any of the max numbers are not positive.
          def initialize(sampler: sampler_from_environment(Samplers.parent_based(root: Samplers::ALWAYS_ON)), # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
                         max_attributes_count: Integer(ENV.fetch('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT', 128)),
                         max_attributes_length: ENV['OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT'],
                         max_events_count: Integer(ENV.fetch('OTEL_SPAN_EVENT_COUNT_LIMIT', 128)),
                         max_links_count: Integer(ENV.fetch('OTEL_SPAN_LINK_COUNT_LIMIT', 128)),
                         max_attributes_per_event: max_attributes_count,
                         max_attributes_per_link: max_attributes_count)
            raise ArgumentError, 'max_attributes_count must be positive' unless max_attributes_count.positive?
            raise ArgumentError, 'max_attributes_length must not be less than 32' unless max_attributes_length.nil? || Integer(max_attributes_length) >= 32
            raise ArgumentError, 'max_events_count must be positive' unless max_events_count.positive?
            raise ArgumentError, 'max_links_count must be positive' unless max_links_count.positive?
            raise ArgumentError, 'max_attributes_per_event must be positive' unless max_attributes_per_event.positive?
            raise ArgumentError, 'max_attributes_per_link must be positive' unless max_attributes_per_link.positive?

            @sampler = sampler
            @max_attributes_count = max_attributes_count
            @max_attributes_length = max_attributes_length.nil? ? nil : Integer(max_attributes_length)
            @max_events_count = max_events_count
            @max_links_count = max_links_count
            @max_attributes_per_event = max_attributes_per_event
            @max_attributes_per_link = max_attributes_per_link
          end

          # TODO: from_proto
          private

          def sampler_from_environment(default_sampler) # rubocop:disable Metrics/CyclomaticComplexity
            case ENV['OTEL_TRACES_SAMPLER']
            when 'always_on' then Samplers::ALWAYS_ON
            when 'always_off' then Samplers::ALWAYS_OFF
            when 'traceidratio' then Samplers.trace_id_ratio_based(Float(ENV.fetch('OTEL_TRACES_SAMPLER_ARG', 1.0)))
            when 'parentbased_always_on' then Samplers.parent_based(root: Samplers::ALWAYS_ON)
            when 'parentbased_always_off' then Samplers.parent_based(root: Samplers::ALWAYS_OFF)
            when 'parentbased_traceidratio' then Samplers.parent_based(root: Samplers.trace_id_ratio_based(Float(ENV.fetch('OTEL_TRACES_SAMPLER_ARG', 1.0))))
            else default_sampler
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: "installing default sampler #{default_sampler.description}")
            default_sampler
          end

          # The default {TraceConfig}.
          DEFAULT = new
        end
      end
    end
  end
end
