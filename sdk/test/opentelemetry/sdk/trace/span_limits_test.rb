# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::SpanLimits do
  let(:subject) { OpenTelemetry::SDK::Trace::SpanLimits }

  describe '#initialize' do
    it 'provides defaults' do
      config = subject.new
      _(config.attribute_count_limit).must_equal 128
      _(config.event_count_limit).must_equal 128
      _(config.link_count_limit).must_equal 128
      _(config.event_attribute_count_limit).must_equal 128
      _(config.link_attribute_count_limit).must_equal 128
    end

    it 'reflects environment variables' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33',
               'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
               'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
               'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new
        _(config.attribute_count_limit).must_equal 1
        _(config.event_count_limit).must_equal 2
        _(config.link_count_limit).must_equal 3
        _(config.attribute_length_limit).must_equal 33
        _(config.span_attribute_length_limit).must_equal 32
        _(config.event_attribute_count_limit).must_equal 5
        _(config.link_attribute_count_limit).must_equal 6
      end
    end

    it 'attribute length limit is default if only span length limit is set' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
               'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
               'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new
        _(config.attribute_count_limit).must_equal 1
        _(config.event_count_limit).must_equal 2
        _(config.link_count_limit).must_equal 3
        _(config.attribute_length_limit).must_equal nil
        _(config.span_attribute_length_limit).must_equal 32
        _(config.event_attribute_count_limit).must_equal 5
        _(config.link_attribute_count_limit).must_equal 6
      end
    end

    it 'span attribute value length limit uses global if not set' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33',
               'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
               'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new
        _(config.attribute_count_limit).must_equal 1
        _(config.event_count_limit).must_equal 2
        _(config.link_count_limit).must_equal 3
        _(config.attribute_length_limit).must_equal 33
        _(config.span_attribute_length_limit).must_equal 33
        _(config.event_attribute_count_limit).must_equal 5
        _(config.link_attribute_count_limit).must_equal 6
      end
    end

    it 'reflects old environment variable for attribute value length limit' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
               'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '5',
               'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '6',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new
        _(config.attribute_count_limit).must_equal 1
        _(config.event_count_limit).must_equal 2
        _(config.link_count_limit).must_equal 3
        _(config.attribute_length_limit).must_equal 32
        _(config.event_attribute_count_limit).must_equal 5
        _(config.link_attribute_count_limit).must_equal 6
      end
    end
    it 'reflects explicit overrides' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '4',
               'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '5',
               'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' => '6',
               'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' => '7',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new(attribute_count_limit: 10,
                             event_count_limit: 11,
                             link_count_limit: 12,
                             event_attribute_count_limit: 13,
                             link_attribute_count_limit: 14,
                             attribute_length_limit: 32,
                             span_attribute_length_limit: 33)
        _(config.attribute_count_limit).must_equal 10
        _(config.event_count_limit).must_equal 11
        _(config.link_count_limit).must_equal 12
        _(config.event_attribute_count_limit).must_equal 13
        _(config.link_attribute_count_limit).must_equal 14
        _(config.attribute_length_limit).must_equal 32
        _(config.span_attribute_length_limit).must_equal 33
      end
    end
  end
end
