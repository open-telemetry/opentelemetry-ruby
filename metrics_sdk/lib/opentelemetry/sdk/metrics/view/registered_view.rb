# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module View
        # RegisteredView is an internal class used to match Views with a given {MetricStream}
        class RegisteredView
          attr_reader :name, :aggregation, :attribute_keys, :included_attribute_keys, :excluded_attribute_keys, :regex, :aggregation_cardinality_limit

          INCLUDE_EXCLUDE_KEYS = %i[included excluded].freeze

          def initialize(name, **options)
            @name = name
            @options = options
            @aggregation = options[:aggregation]
            @attribute_keys = options[:attribute_keys]
            @aggregation_cardinality_limit = options[:aggregation_cardinality_limit]

            @included_attribute_keys, @excluded_attribute_keys = parse_attribute_keys(@attribute_keys)

            generate_regex_pattern(name)
          end

          # Returns the attributes to record in this view's metric stream, keeping only the
          # attributes allowed by the view's +attribute_keys+ configuration. The measurement
          # attributes are never modified; a new Hash is returned whenever filtering applies.
          def filter_attributes(attributes)
            attributes ||= {}
            return attributes if @included_attribute_keys.nil? && @excluded_attribute_keys.nil?

            filtered = @included_attribute_keys ? attributes.select { |key, _value| @included_attribute_keys.include?(key.to_s) } : attributes.dup
            filtered.reject! { |key, _value| @excluded_attribute_keys.include?(key.to_s) } if @excluded_attribute_keys
            filtered
          end

          # Returns whether this view applies to the given metric stream.
          def match_instrument?(metric_stream)
            return false if @name && !name_match(metric_stream.name)
            return false if @options[:type] && @options[:type] != metric_stream.instrument_kind
            return false if @options[:unit] && @options[:unit] != metric_stream.unit
            return false if @options[:meter_name] && @options[:meter_name] != metric_stream.instrumentation_scope.name
            return false if @options[:meter_version] && @options[:meter_version] != metric_stream.instrumentation_scope.version

            true
          end

          # Returns whether stream_name matches this view's name pattern.
          def name_match(stream_name) # rubocop:disable Naming/PredicateMethod
            !!@regex&.match(stream_name)
          end

          # Returns whether this view's aggregation is an SDK Aggregation instance.
          def valid_aggregation?
            @aggregation.class.name.rpartition('::')[0] == 'OpenTelemetry::SDK::Metrics::Aggregation'
          end

          private

          # Normalizes the +attribute_keys+ option into allow-list/exclude-list of string keys.
          # If nil, no restriction.
          # If Hash, it should have :included and/or :excluded keys.
          # Else, it is treated as an allow-list of attribute keys (default legacy behavior {'a' => 'b'})
          def parse_attribute_keys(attribute_keys)
            case attribute_keys
            when nil
              [nil, nil]
            when Hash
              parse_attribute_keys_hash(attribute_keys)
            else
              [normalize_attribute_keys(attribute_keys), nil]
            end
          end

          # An empty Hash carries no configuration, and used to be the default value of this
          # option, so it is treated the same as an omitted option.
          def parse_attribute_keys_hash(attribute_keys)
            attribute_keys = attribute_keys.transform_keys do |key|
              key.is_a?(String) && INCLUDE_EXCLUDE_KEYS.map(&:to_s).include?(key) ? key.to_sym : key
            end

            return [nil, nil] if attribute_keys.empty?
            return [normalize_attribute_keys(attribute_keys.keys), nil] unless (attribute_keys.keys - INCLUDE_EXCLUDE_KEYS).empty?

            included = normalize_attribute_keys(attribute_keys[:included])
            excluded = normalize_attribute_keys(attribute_keys[:excluded])

            OpenTelemetry.logger.warn("attribute_keys #{overlap.inspect} are both included and excluded. They will be treated as excluded.") if included && excluded && included.intersect?(excluded)
            [included, excluded]
          end

          # Return an array of normalized attribute keys as strings, or nil if no keys are provided.
          def normalize_attribute_keys(keys)
            return nil if keys.nil?

            Array(keys).map(&:to_s).uniq
          end

          def generate_regex_pattern(view_name)
            regex_pattern = Regexp.escape(view_name)

            regex_pattern.gsub!('\*', '.*')
            regex_pattern.gsub!('\?', '.')

            @regex = Regexp.new("^#{regex_pattern}$")
          rescue StandardError
            @regex = nil
          end
        end
      end
    end
  end
end
