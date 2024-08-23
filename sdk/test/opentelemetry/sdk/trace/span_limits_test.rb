# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::SpanLimits do
  let(:span_limits) { OpenTelemetry::SDK::Trace::SpanLimits.new }

  describe '#initialize' do
    it 'provides defaults' do
      _(span_limits.attribute_count_limit).must_equal 128
      _(span_limits.attribute_length_limit).must_be_nil
      _(span_limits.event_count_limit).must_equal 128
      _(span_limits.link_count_limit).must_equal 128
      _(span_limits.event_attribute_count_limit).must_equal 128
      _(span_limits.event_attribute_length_limit).must_be_nil
      _(span_limits.link_attribute_count_limit).must_equal 128
    end

    it 'prioritizes specific environment variables for attribute value length limits' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '35',
                                          'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33',
                                          'OTEL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32') do
        _(span_limits.attribute_length_limit).must_equal 33
        _(span_limits.event_attribute_length_limit).must_equal 32
      end
    end

    it 'uses general attribute value length limits in the absence of more specific ones' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '35') do
        _(span_limits.attribute_length_limit).must_equal 35
        _(span_limits.event_attribute_length_limit).must_equal 35
      end
    end

    it 'reflects environment variables' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
                                          'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
                                          'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
                                          'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
                                          'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
                                          'OTEL_TRACES_SAMPLER' => 'always_on') do
        _(span_limits.attribute_count_limit).must_equal 1
        _(span_limits.event_count_limit).must_equal 2
        _(span_limits.link_count_limit).must_equal 3
        _(span_limits.attribute_length_limit).must_equal 32
        _(span_limits.event_attribute_count_limit).must_equal 5
        _(span_limits.event_attribute_length_limit).must_be_nil
        _(span_limits.link_attribute_count_limit).must_equal 6
      end
    end

    it 'reflects old environment variable for attribute value length limit' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
                                          'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
                                          'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
                                          'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
                                          'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
                                          'OTEL_TRACES_SAMPLER' => 'always_on') do
        _(span_limits.attribute_count_limit).must_equal 1
        _(span_limits.event_count_limit).must_equal 2
        _(span_limits.link_count_limit).must_equal 3
        _(span_limits.attribute_length_limit).must_equal 32
        _(span_limits.event_attribute_count_limit).must_equal 5
        _(span_limits.event_attribute_length_limit).must_be_nil
        _(span_limits.link_attribute_count_limit).must_equal 6
      end
    end

    it 'reflects explicit overrides' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
                                          'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
                                          'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '4',
                                          'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
                                          'OTEL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
                                          'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
                                          'OTEL_TRACES_SAMPLER' => 'always_on') do
        span_limits = OpenTelemetry::SDK::Trace::SpanLimits.new(attribute_count_limit: 10,
                                                                event_count_limit: 11,
                                                                link_count_limit: 12,
                                                                event_attribute_count_limit: 13,
                                                                event_attribute_length_limit: 40,
                                                                link_attribute_count_limit: 14,
                                                                attribute_length_limit: 32)
        _(span_limits.attribute_count_limit).must_equal 10
        _(span_limits.event_count_limit).must_equal 11
        _(span_limits.link_count_limit).must_equal 12
        _(span_limits.event_attribute_count_limit).must_equal 13
        _(span_limits.event_attribute_length_limit).must_equal 40
        _(span_limits.link_attribute_count_limit).must_equal 14
        _(span_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'reflects generic attribute env vars' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32') do
        _(span_limits.attribute_count_limit).must_equal 1
        _(span_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'prefers model-specific attribute env vars over generic attribute env vars' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_ATTRIBUTE_COUNT_LIMIT' => '2',
                                          'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
                                          'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33') do
        _(span_limits.attribute_count_limit).must_equal 1
        _(span_limits.attribute_length_limit).must_equal 32
      end
    end
  end
end
