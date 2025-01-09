# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

def left_boundary(scale, inds)
  while scale > 0 && inds < -1022
    inds /= 2.to_f
    scale -= 1
  end

  result = 2.0**inds

  scale.times { result = Math.sqrt(result) }
  result
end

def right_boundary(scale, index)
  result = 2**index

  scale.abs.times do
    result *= result
  end

  result
end

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram do
  MAX_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_EXPONENT
  MIN_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MIN_NORMAL_EXPONENT
  MAX_NORMAL_VALUE = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_VALUE
  MIN_NORMAL_VALUE = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MIN_NORMAL_VALUE

  describe 'logarithm_mapping' do
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

  describe 'exponent_mapping' do
    let(:exponent_mapping_min_scale) { -10 }

    it 'test_exponent_mapping_zero' do
      exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(0)

      # This is the equivalent to 1.1 in hexadecimal
      hex_one_one = 1 + (1.0 / 16)

      # Testing with values near +inf
      _(exponent_mapping.map_to_index(MAX_NORMAL_VALUE)).must_equal(MAX_NORMAL_EXPONENT)
      _(exponent_mapping.map_to_index(MAX_NORMAL_VALUE)).must_equal(1023)
      _(exponent_mapping.map_to_index(2**1023)).must_equal(1022)
      _(exponent_mapping.map_to_index(2**1022)).must_equal(1021)
      _(exponent_mapping.map_to_index(hex_one_one * (2**1023))).must_equal(1023)
      _(exponent_mapping.map_to_index(hex_one_one * (2**1022))).must_equal(1022)

      # Testing with values near 1
      _(exponent_mapping.map_to_index(4)).must_equal(1)
      _(exponent_mapping.map_to_index(3)).must_equal(1)
      _(exponent_mapping.map_to_index(2)).must_equal(0)
      _(exponent_mapping.map_to_index(1)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.75)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.51)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.5)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.26)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.25)).must_equal(-3)
      _(exponent_mapping.map_to_index(0.126)).must_equal(-3)
      _(exponent_mapping.map_to_index(0.125)).must_equal(-4)

      # Testing with values near 0
      _(exponent_mapping.map_to_index(2**-1022)).must_equal(-1023)
      _(exponent_mapping.map_to_index(hex_one_one * (2**-1022))).must_equal(-1022)
      _(exponent_mapping.map_to_index(2**-1021)).must_equal(-1022)
      _(exponent_mapping.map_to_index(hex_one_one * (2**-1021))).must_equal(-1021)
      _(exponent_mapping.map_to_index(2**-1022)).must_equal(MIN_NORMAL_EXPONENT - 1)
      _(exponent_mapping.map_to_index(2**-1021)).must_equal(MIN_NORMAL_EXPONENT)

      # The smallest subnormal value is 2 ** -1074 = 5e-324.
      # This value is also the result of:
      # s = 1
      # while s / 2:
      #     s = s / 2
      # s == 5e-324
      _(exponent_mapping.map_to_index(2**-1074)).must_equal(MIN_NORMAL_EXPONENT - 1)
    end

    it 'test_exponent_mapping_negative_one' do
      exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(-1)
      _(exponent_mapping.map_to_index(17)).must_equal(2)
      _(exponent_mapping.map_to_index(16)).must_equal(1)
      _(exponent_mapping.map_to_index(15)).must_equal(1)
      _(exponent_mapping.map_to_index(9)).must_equal(1)
      _(exponent_mapping.map_to_index(8)).must_equal(1)
      _(exponent_mapping.map_to_index(5)).must_equal(1)
      _(exponent_mapping.map_to_index(4)).must_equal(0)
      _(exponent_mapping.map_to_index(3)).must_equal(0)
      _(exponent_mapping.map_to_index(2)).must_equal(0)
      _(exponent_mapping.map_to_index(1.5)).must_equal(0)
      _(exponent_mapping.map_to_index(1)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.75)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.5)).must_equal(-1)
      _(exponent_mapping.map_to_index(0.25)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.20)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.13)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.125)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.10)).must_equal(-2)
      _(exponent_mapping.map_to_index(0.0625)).must_equal(-3)
      _(exponent_mapping.map_to_index(0.06)).must_equal(-3)
    end

    it 'test_exponent_mapping_negative_four' do
      exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(-4)

      _(exponent_mapping.map_to_index(0x1.to_f)).must_equal(-1)
      _(exponent_mapping.map_to_index(0x10.to_f)).must_equal(0)
      _(exponent_mapping.map_to_index(0x100.to_f)).must_equal(0)
      _(exponent_mapping.map_to_index(0x1000.to_f)).must_equal(0)
      _(exponent_mapping.map_to_index(0x10000.to_f)).must_equal(0) # base == 2 ** 16
      _(exponent_mapping.map_to_index(0x100000.to_f)).must_equal(1)
      _(exponent_mapping.map_to_index(0x1000000.to_f)).must_equal(1)
      _(exponent_mapping.map_to_index(0x10000000.to_f)).must_equal(1)
      _(exponent_mapping.map_to_index(0x100000000.to_f)).must_equal(1) # base == 2 ** 32

      _(exponent_mapping.map_to_index(0x1000000000.to_f)).must_equal(2)
      _(exponent_mapping.map_to_index(0x10000000000.to_f)).must_equal(2)
      _(exponent_mapping.map_to_index(0x100000000000.to_f)).must_equal(2)
      _(exponent_mapping.map_to_index(0x1000000000000.to_f)).must_equal(2) # base == 2 ** 48

      _(exponent_mapping.map_to_index(0x10000000000000.to_f)).must_equal(3)
      _(exponent_mapping.map_to_index(0x100000000000000.to_f)).must_equal(3)
      _(exponent_mapping.map_to_index(0x1000000000000000.to_f)).must_equal(3)
      _(exponent_mapping.map_to_index(0x10000000000000000.to_f)).must_equal(3) # base == 2 ** 64

      _(exponent_mapping.map_to_index(0x100000000000000000.to_f)).must_equal(4)
      _(exponent_mapping.map_to_index(0x1000000000000000000.to_f)).must_equal(4)
      _(exponent_mapping.map_to_index(0x10000000000000000000.to_f)).must_equal(4)
      _(exponent_mapping.map_to_index(0x100000000000000000000.to_f)).must_equal(4) # base == 2 ** 80
      _(exponent_mapping.map_to_index(0x1000000000000000000000.to_f)).must_equal(5)

      _(exponent_mapping.map_to_index(1 / 0x1.to_f)).must_equal(-1)
      _(exponent_mapping.map_to_index(1 / 0x10.to_f)).must_equal(-1)
      _(exponent_mapping.map_to_index(1 / 0x100.to_f)).must_equal(-1)
      _(exponent_mapping.map_to_index(1 / 0x1000.to_f)).must_equal(-1)
      _(exponent_mapping.map_to_index(1 / 0x10000.to_f)).must_equal(-2) # base == 2 ** -16
      _(exponent_mapping.map_to_index(1 / 0x100000.to_f)).must_equal(-2)
      _(exponent_mapping.map_to_index(1 / 0x1000000.to_f)).must_equal(-2)
      _(exponent_mapping.map_to_index(1 / 0x10000000.to_f)).must_equal(-2)
      _(exponent_mapping.map_to_index(1 / 0x100000000.to_f)).must_equal(-3) # base == 2 ** -32
      _(exponent_mapping.map_to_index(1 / 0x1000000000.to_f)).must_equal(-3)
      _(exponent_mapping.map_to_index(1 / 0x10000000000.to_f)).must_equal(-3)
      _(exponent_mapping.map_to_index(1 / 0x100000000000.to_f)).must_equal(-3)
      _(exponent_mapping.map_to_index(1 / 0x1000000000000.to_f)).must_equal(-4) # base == 2 ** -48
      _(exponent_mapping.map_to_index(1 / 0x10000000000000.to_f)).must_equal(-4)
      _(exponent_mapping.map_to_index(1 / 0x100000000000000.to_f)).must_equal(-4)
      _(exponent_mapping.map_to_index(1 / 0x1000000000000000.to_f)).must_equal(-4)
      _(exponent_mapping.map_to_index(1 / 0x10000000000000000.to_f)).must_equal(-5) # base == 2 ** -64
      _(exponent_mapping.map_to_index(1 / 0x100000000000000000.to_f)).must_equal(-5)

      _(exponent_mapping.map_to_index(Float::MAX)).must_equal(63)
      _(exponent_mapping.map_to_index(2**1023)).must_equal(63)
      _(exponent_mapping.map_to_index(2**1019)).must_equal(63)
      _(exponent_mapping.map_to_index(2**1009)).must_equal(63)
      _(exponent_mapping.map_to_index(2**1008)).must_equal(62)
      _(exponent_mapping.map_to_index(2**1007)).must_equal(62)
      _(exponent_mapping.map_to_index(2**1000)).must_equal(62)
      _(exponent_mapping.map_to_index(2**993)).must_equal(62)
      _(exponent_mapping.map_to_index(2**992)).must_equal(61)
      _(exponent_mapping.map_to_index(2**991)).must_equal(61)

      _(exponent_mapping.map_to_index(2**-1074)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1073)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1072)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1057)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1056)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1041)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1040)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1025)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1024)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1023)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1022)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1009)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1008)).must_equal(-64)
      _(exponent_mapping.map_to_index(2**-1007)).must_equal(-63)
      _(exponent_mapping.map_to_index(2**-993)).must_equal(-63)
      _(exponent_mapping.map_to_index(2**-992)).must_equal(-63)
      _(exponent_mapping.map_to_index(2**-991)).must_equal(-62)
      _(exponent_mapping.map_to_index(2**-977)).must_equal(-62)
      _(exponent_mapping.map_to_index(2**-976)).must_equal(-62)
      _(exponent_mapping.map_to_index(2**-975)).must_equal(-61)
    end

    it 'test_exponent_mapping_min_scale_negative_10' do
      exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(exponent_mapping_min_scale)
      _(exponent_mapping.map_to_index(1.000001)).must_equal(0)
      _(exponent_mapping.map_to_index(1)).must_equal(-1)
      _(exponent_mapping.map_to_index(Float::MAX)).must_equal(0)
      _(exponent_mapping.map_to_index(Float::MIN)).must_equal(-1)
    end

    it 'test_exponent_index_max' do
      (-10...0).each do |scale|
        exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(scale)

        inds = exponent_mapping.map_to_index(MAX_NORMAL_VALUE)
        max_index = ((MAX_NORMAL_EXPONENT + 1) >> -scale) - 1

        _(inds).must_equal(max_index)

        boundary = exponent_mapping.get_lower_boundary(inds)
        _(boundary).must_equal(right_boundary(scale, max_index))

        error = assert_raises(StandardError) do
          exponent_mapping.get_lower_boundary(inds + 1)
        end
        assert_equal('mapping underflow', error.message)
      end
    end

    it 'test_exponent_index_min' do
      (-10..0).each do |scale|
        exponent_mapping = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(scale)

        min_index = exponent_mapping.map_to_index(MIN_NORMAL_VALUE)
        boundary = exponent_mapping.get_lower_boundary(min_index)

        correct_min_index = MIN_NORMAL_EXPONENT >> -scale

        correct_min_index -= 1 if MIN_NORMAL_EXPONENT % (1 << -scale) == 0

        # We do not check for correct_min_index to be greater than the
        # smallest integer because the smallest integer in Ruby is -Float::INFINITY.

        _(correct_min_index).must_equal(min_index)

        correct_boundary = right_boundary(scale, correct_min_index)

        # truffleruby will fail because truffleruby `must_equal` check the exact precision of float point
        _(correct_boundary).must_equal(boundary) if RUBY_ENGINE != 'truffleruby'
        _(right_boundary(scale, correct_min_index + 1)).must_be :>, boundary

        _(correct_min_index).must_equal(exponent_mapping.map_to_index(MIN_NORMAL_VALUE / 2))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(MIN_NORMAL_VALUE / 3))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(MIN_NORMAL_VALUE / 100))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(2**-1050))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(2**-1073))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(1.1 * (2**-1073)))
        _(correct_min_index).must_equal(exponent_mapping.map_to_index(2**-1074))

        error = assert_raises(StandardError) do
          exponent_mapping.get_lower_boundary(min_index - 1)
        end
        assert_equal('mapping underflow', error.message)

        _(exponent_mapping.map_to_index(Float::MIN.next_float)).must_equal(MIN_NORMAL_EXPONENT >> -scale)
      end
    end
  end
end
