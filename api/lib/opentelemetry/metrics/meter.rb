# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of Meter.
    module Meter
      extend self

      NOOP_DOUBLE_MEASURE = DoubleMeasure.new
      NOOP_LONG_MEASURE = LongMeasure.new

      private_constant(:NOOP_DOUBLE_MEASURE, :NOOP_LONG_MEASURE)

      def record(*measurements, distributed_context: nil, exemplar: nil); end

      def create_measure(name, description: nil, unit: nil, type: :double)
        raise ArgumentError if name.nil? # TODO: The Java implementation also constrains the name to be printable and 255 chars or less.

        case type
        when :double
          NOOP_DOUBLE_MEASURE
        when :long
          NOOP_LONG_MEASURE
        else
          raise ArgumentError
        end
      end

      # TODO: I contemplated using '..., **constant_labels)' here instead of the optional named arg, but that allocates an empty hash if no additional args are passed.
      def create_double_gauge(name, description: nil, unit: nil, component: nil, resource: nil, label_keys: nil, constant_labels: nil)
        raise ArgumentError if name.nil?
        raise ArgumentError if label_keys&.any?(nil)
        raise ArgumentError if constant_labels&.any? { |k, v| k.nil? || v.nil? }

        DoubleGauge.new(label_keys_size: label_keys&.size || 0)
      end

      def create_long_gauge(name, description: nil, unit: nil, component: nil, resource: nil, label_keys: nil, constant_labels: nil)
        raise ArgumentError if name.nil?
        raise ArgumentError if label_keys&.any?(nil)
        raise ArgumentError if constant_labels&.any? { |k, v| k.nil? || v.nil? }

        LongGauge.new(label_keys_size: label_keys&.size || 0)
      end

      def create_double_counter(name, description: nil, unit: nil, component: nil, resource: nil, label_keys: nil, constant_labels: nil)
        raise ArgumentError if name.nil?
        raise ArgumentError if label_keys&.any?(nil)
        raise ArgumentError if constant_labels&.any? { |k, v| k.nil? || v.nil? }

        DoubleCounter.new(label_keys_size: label_keys&.size || 0)
      end

      def create_long_counter(name, description: nil, unit: nil, component: nil, resource: nil, label_keys: nil, constant_labels: nil)
        raise ArgumentError if name.nil?
        raise ArgumentError if label_keys&.any?(nil)
        raise ArgumentError if constant_labels&.any? { |k, v| k.nil? || v.nil? }

        LongCounter.new(label_keys_size: label_keys&.size || 0)
      end
    end
  end
end
