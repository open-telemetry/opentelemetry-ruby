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
      _(config.attribute_per_event_count_limit).must_equal 128
      _(config.attribute_per_link_count_limit).must_equal 128
    end

    it 'reflects environment variables' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new
        _(config.attribute_count_limit).must_equal 1
        _(config.event_count_limit).must_equal 2
        _(config.link_count_limit).must_equal 3
        _(config.attribute_length_limit).must_equal 32
        _(config.attribute_per_event_count_limit).must_equal 1
        _(config.attribute_per_link_count_limit).must_equal 1
      end
    end

    it 'reflects explicit overrides' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '4',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = subject.new(attribute_count_limit: 10,
                             event_count_limit: 11,
                             link_count_limit: 12,
                             attribute_per_event_count_limit: 13,
                             attribute_per_link_count_limit: 14,
                             attribute_length_limit: 32)
        _(config.attribute_count_limit).must_equal 10
        _(config.event_count_limit).must_equal 11
        _(config.link_count_limit).must_equal 12
        _(config.attribute_per_event_count_limit).must_equal 13
        _(config.attribute_per_link_count_limit).must_equal 14
        _(config.attribute_length_limit).must_equal 32
      end
    end
  end
end
