# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Config
    # View builder for registering metric views from declarative config.
    module MetricViews
      INSTRUMENT_TYPES = %w[
        counter gauge histogram observable_counter observable_gauge observable_up_down_counter up_down_counter
      ].freeze
      MONOTONIC_INSTRUMENT_TYPES = %i[counter histogram observable_counter].freeze
      private_constant :INSTRUMENT_TYPES, :MONOTONIC_INSTRUMENT_TYPES

      module_function

      # Registers a view on the meter provider from its selector and stream config.
      def add_view(meter_provider, view_cfg)
        selector = view_cfg.selector
        stream = view_cfg.stream
        raise ArgumentError, 'view requires a selector' unless selector
        raise ArgumentError, 'view requires a stream' unless stream

        type = build_instrument_type(selector.instrument_type)
        Metrics.warn_unsupported('selector.meter_schema_url') if selector.meter_schema_url
        Metrics.warn_unsupported('stream.name') if stream.name
        Metrics.warn_unsupported('stream.description') if stream.description
        Metrics.warn_unsupported('stream.attribute_keys') if stream.attribute_keys

        opts = {
          aggregation: build_aggregation(stream.aggregation, type),
          type: type,
          unit: selector.unit,
          meter_name: selector.meter_name,
          meter_version: selector.meter_version,
          aggregation_cardinality_limit: stream.aggregation_cardinality_limit
        }.compact

        meter_provider.add_view(selector.instrument_name, **opts)
      end

      # Converts a schema instrument type to the SDK instrument kind symbol.
      def build_instrument_type(name)
        return unless name
        raise ArgumentError, "unknown instrument_type #{name}" unless INSTRUMENT_TYPES.include?(name)

        name.to_sym
      end

      # Builds an SDK aggregation from config. A view without an SDK aggregation
      # drops its data, so default resolves from the selected instrument type.
      def build_aggregation(cfg, type)
        a = OpenTelemetry::SDK::Metrics::Aggregation

        if cfg&.drop
          a::Drop.new
        elsif cfg&.sum
          a::Sum.new(monotonic: MONOTONIC_INSTRUMENT_TYPES.include?(type))
        elsif cfg&.last_value
          a::LastValue.new
        elsif (hist = cfg&.explicit_bucket_histogram)
          opts = { boundaries: hist.boundaries, record_min_max: hist.record_min_max }.compact
          a::ExplicitBucketHistogram.new(**opts)
        elsif (hist = cfg&.base2_exponential_bucket_histogram)
          opts = { max_scale: hist.max_scale, max_size: hist.max_size, record_min_max: hist.record_min_max }.compact
          a::ExponentialBucketHistogram.new(**opts)
        else
          build_default_aggregation(type)
        end
      end

      # Returns the aggregation the SDK instrument of the given type uses by default.
      def build_default_aggregation(type)
        a = OpenTelemetry::SDK::Metrics::Aggregation

        case type
        when :counter then a::Sum.new(monotonic: true)
        when :observable_counter then a::Sum.new(monotonic: true, instrument_kind: type)
        when :up_down_counter, :observable_up_down_counter
          a::Sum.new(aggregation_temporality: :cumulative, monotonic: false)
        when :histogram then a::ExplicitBucketHistogram.new
        when :gauge, :observable_gauge then a::LastValue.new
        else raise ArgumentError, 'default aggregation requires selector.instrument_type'
        end
      end
    end

    private_constant :MetricViews
  end
end
