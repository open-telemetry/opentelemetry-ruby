# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Config
        # Class that holds global trace parameters.
        class TraceConfig
          DEFAULT_SAMPLER = Samplers.parent_based(root: Samplers::ALWAYS_ON)
          DEFAULT_MAX_ATTRIBUTES_COUNT = 32
          DEFAULT_MAX_EVENTS_COUNT = 128
          DEFAULT_MAX_LINKS_COUNT = 32
          DEFAULT_MAX_ATTRIBUTES_PER_EVENT = 32
          DEFAULT_MAX_ATTRIBUTES_PER_LINK = 32

          private_constant(:DEFAULT_SAMPLER,
                           :DEFAULT_MAX_ATTRIBUTES_COUNT,
                           :DEFAULT_MAX_EVENTS_COUNT,
                           :DEFAULT_MAX_LINKS_COUNT,
                           :DEFAULT_MAX_ATTRIBUTES_PER_EVENT,
                           :DEFAULT_MAX_ATTRIBUTES_PER_LINK)

          # The global default sampler (see {Samplers}).
          attr_reader :sampler

          # The global default max number of attributes per {Span}.
          attr_reader :max_attributes_count

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
          def initialize(sampler: DEFAULT_SAMPLER,
                         max_attributes_count: DEFAULT_MAX_ATTRIBUTES_COUNT,
                         max_events_count: DEFAULT_MAX_EVENTS_COUNT,
                         max_links_count: DEFAULT_MAX_LINKS_COUNT,
                         max_attributes_per_event: DEFAULT_MAX_ATTRIBUTES_PER_EVENT,
                         max_attributes_per_link: DEFAULT_MAX_ATTRIBUTES_PER_LINK)
            raise ArgumentError, 'max_attributes_count must be positive' unless max_attributes_count.positive?
            raise ArgumentError, 'max_events_count must be positive' unless max_events_count.positive?
            raise ArgumentError, 'max_links_count must be positive' unless max_links_count.positive?
            raise ArgumentError, 'max_attributes_per_event must be positive' unless max_attributes_per_event.positive?
            raise ArgumentError, 'max_attributes_per_link must be positive' unless max_attributes_per_link.positive?

            @sampler = sampler
            @max_attributes_count = max_attributes_count
            @max_events_count = max_events_count
            @max_links_count = max_links_count
            @max_attributes_per_event = max_attributes_per_event
            @max_attributes_per_link = max_attributes_per_link
          end

          # TODO: from_proto

          # The default {TraceConfig}.
          DEFAULT = new
        end
      end
    end
  end
end
