# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram do
  describe 'logarithm_mapping' do
    it 'test_init_called_once' do
      # Test that creating multiple instances with the same scale works correctly
      # This tests that initialization doesn't interfere between instances
      mapping1 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(3)
      mapping2 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(3)

      # Both instances should work independently and have the same scale
      _(mapping1.scale).must_equal(3)
      _(mapping2.scale).must_equal(3)

      # Both should produce the same mapping results
      test_value = 2.5
      _(mapping1.map_to_index(test_value)).must_equal(mapping2.map_to_index(test_value))
    end

    it 'test_logarithm_mapping_scale_one' do
      logarithm_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(1)
      _(logarithm_mapping.scale).must_equal(1)
      _(logarithm_mapping.map_to_index(15)).must_equal(7)
      _(logarithm_mapping.map_to_index(9)).must_equal(6)
      _(logarithm_mapping.map_to_index(7)).must_equal(5)
      _(logarithm_mapping.map_to_index(5)).must_equal(4)
      _(logarithm_mapping.map_to_index(3)).must_equal(3)
      _(logarithm_mapping.map_to_index(2.5)).must_equal(2)
      _(logarithm_mapping.map_to_index(1.5)).must_equal(1)
      _(logarithm_mapping.map_to_index(1.2)).must_equal(0)
      # This one is actually an exact test
      _(logarithm_mapping.map_to_index(1)).must_equal(-1)
      _(logarithm_mapping.map_to_index(0.75)).must_equal(-1)
      _(logarithm_mapping.map_to_index(0.55)).must_equal(-2)
      _(logarithm_mapping.map_to_index(0.45)).must_equal(-3)
    end

    it 'test_logarithm_boundary' do
      [1, 2, 3, 4, 10, 15].each do |scale|
        logarithm_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(scale)

        [-100, -10, -1, 0, 1, 10, 100].each do |inds|
          lower_boundary = logarithm_mapping.get_lower_boundary(inds)
          mapped_index = logarithm_mapping.map_to_index(lower_boundary)

          _(mapped_index).must_be :<=, inds
          _(mapped_index).must_be :>=, inds - 1

          left_boundary_value = left_boundary(scale, inds)
          _(lower_boundary).must_be_within_epsilon left_boundary_value, 1e-9
        end
      end
    end

    it 'test_logarithm_index_max' do
      (1..20).each do |scale|
        logarithm_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(scale)

        inds = logarithm_mapping.map_to_index(OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_VALUE)
        max_index = ((OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_EXPONENT + 1) << scale) - 1

        _(inds).must_equal(max_index)

        boundary = logarithm_mapping.get_lower_boundary(inds)
        base = logarithm_mapping.get_lower_boundary(1)

        _(boundary).must_be :<, OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_VALUE

        _((OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_VALUE - boundary) / boundary).must_be_within_epsilon base - 1, 1e-6

        error = assert_raises(StandardError) do
          logarithm_mapping.get_lower_boundary(inds + 1)
        end
        assert_equal('mapping overflow', error.message)

        error = assert_raises(StandardError) do
          logarithm_mapping.get_lower_boundary(inds + 2)
        end
        assert_equal('mapping overflow', error.message)
      end
    end

    it 'test_logarithm_index_min' do
      (1..20).each do |scale|
        logarithm_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(scale)

        min_index = logarithm_mapping.map_to_index(MIN_NORMAL_VALUE)
        correct_min_index = (MIN_NORMAL_EXPONENT << scale) - 1

        _(min_index).must_equal(correct_min_index)

        correct_mapped = left_boundary(scale, correct_min_index)
        _(correct_mapped).must_be :<, MIN_NORMAL_VALUE

        correct_mapped_upper = left_boundary(scale, correct_min_index + 1)
        _(correct_mapped_upper).must_equal(MIN_NORMAL_VALUE)

        mapped = logarithm_mapping.get_lower_boundary(min_index + 1)
        _(mapped).must_be_within_epsilon MIN_NORMAL_VALUE, 1e-6

        _(logarithm_mapping.map_to_index(MIN_NORMAL_VALUE / 2)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(MIN_NORMAL_VALUE / 3)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(MIN_NORMAL_VALUE / 100)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(2**-1050)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(2**-1073)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(1.1 * 2**-1073)).must_equal(correct_min_index)
        _(logarithm_mapping.map_to_index(2**-1074)).must_equal(correct_min_index)

        mapped_lower = logarithm_mapping.get_lower_boundary(min_index)
        _(correct_mapped).must_be_within_epsilon mapped_lower, 1e-6

        error = assert_raises(StandardError) do
          logarithm_mapping.get_lower_boundary(min_index - 1)
        end
        assert_equal('mapping underflow', error.message)
      end
    end
  end
end
