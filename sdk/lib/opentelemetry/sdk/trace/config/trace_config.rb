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
          DEFAULT_SAMPLER = Samplers::ALWAYS_ON
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

          # The global default max number of {OpenTelemetry::Trace::Event}s per {Span}.
          attr_reader :max_events_count

          # The global default max number of {OpenTelemetry::Trace::Link} entries per {Span}.
          attr_reader :max_links_count

          # The global default max number of attributes per {OpenTelemetry::Trace::Event}.
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

          # @api private
          #
          # Removes oldest entries from {OpenTelemetry::Trace::Event} attributes Hash whose size
          # exceeds {max_attributes_per_event}.
          #
          # @param [Hash] attrs This is modified in place.
          def trim_event_attributes(attrs)
            trim_attributes(attrs, @max_attributes_per_event)
          end

          # @api private
          #
          # Removes oldest entries from {Span} attributes Hash whose size
          # exceeds {max_attributes_count}.
          #
          # @param [Hash] attrs This is modified in place.
          def trim_span_attributes(attrs)
            return if attrs.nil?

            excess = attrs.size - max_attributes_count
            # TODO: with Ruby 2.5, replace with the more efficient
            # attrs.shift(excess) if excess.positive?
            excess.times { attrs.shift } if excess.positive?
            nil
          end

          # @api private
          #
          # Returns a frozen slice of a {OpenTelemetry::Trace::Link}s array of
          # no more than {max_links_count} entries. If links is larger than
          # {max_links_count}, the excess entries will be removed from the
          # front of the array. They are presumed to be the oldest entries.
          #
          # Also trims attributes of each {OpenTelemetry::Trace::Link} to have
          # no more than {max_attributes_per_link} entries.
          #
          # @param [Array<OpenTelemetry::Trace::Link>] links Array of
          #   {OpenTelemetry::Trace::Link}s to trim. May be nil.
          # @return [Array<OpenTelemetry::Trace::Link>] frozen slice of links
          #   param. May be nil.
          def trim_links(links) # rubocop:disable Metrics/AbcSize
            # Fast path (likely) common cases.
            return nil if links.nil?

            unless links.size > @max_links_count || links.any? { |link| link.attributes.size > max_attributes_per_link }
              return links.frozen? ? links : links.clone.freeze
            end

            # Trim attributes for each Link.
            links.last(max_links_count).map! do |link|
              excess = link.attributes.size - max_attributes_per_link
              if excess.positive?
                attrs = Hash[link.attributes] # link.attributes is frozen, so we need an unfrozen copy to adjust.
                excess.times { attrs.shift }
                link = OpenTelemetry::Trace::Link.new(link.context, attrs)
              end
              link
            end.freeze
          end

          # @api private
          #
          # Removes oldest entries from {OpenTelemetry::Trace::Event}s Array whose size exceeds
          # {max_events_count}. Appends {OpenTelemetry::Trace::Event} to the trimmed array.
          #
          # Also trims attributes of the {OpenTelemetry::Trace::Event} to have
          # no more than {max_attributes_per_event} entries.
          #
          # @param [Array<OpenTelemetry::Trace::Event>] events This is modified in-place.
          # @param [OpenTelemetry::Trace::Event] event The event to add.
          # @return [Array<OpenTelemetry::Trace::Event>]
          def append_event(events, event) # rubocop:disable Metrics/AbcSize
            # Fast path (likely) common case.
            return events << event if events.size < max_events_count && event.attributes.size <= max_attributes_per_event

            excess = events.size + 1 - max_events_count
            events.shift(excess) if excess.positive?
            excess = event.attributes.size - max_attributes_per_event
            if excess.positive?
              attrs = Hash[event.attributes] # event.attributes is frozen, so we need an unfrozen copy to adjust.
              excess.times { attrs.shift }
              event = OpenTelemetry::Trace::Event.new(name: event.name, attributes: attrs, timestamp: event.timestamp)
            end
            events << event
          end

          # TODO: from_proto

          # The default {TraceConfig}.
          DEFAULT = new
        end
      end
    end
  end
end
