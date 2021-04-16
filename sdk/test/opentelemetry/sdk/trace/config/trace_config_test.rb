# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Config::TraceConfig do
  let(:trace_config) { OpenTelemetry::SDK::Trace::Config::TraceConfig }
  let(:samplers) { OpenTelemetry::SDK::Trace::Samplers }

  describe '#initialize' do
    it 'provides defaults' do
      config = trace_config.new
      _(config.sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_ON)
      _(config.max_attributes_count).must_equal 128
      _(config.max_events_count).must_equal 128
      _(config.max_links_count).must_equal 128
      _(config.max_attributes_per_event).must_equal 128
      _(config.max_attributes_per_link).must_equal 128
    end

    it 'reflects environment variables' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = trace_config.new
        _(config.sampler).must_equal samplers::ALWAYS_ON
        _(config.max_attributes_count).must_equal 1
        _(config.max_events_count).must_equal 2
        _(config.max_links_count).must_equal 3
        _(config.max_attributes_length).must_equal 32
        _(config.max_attributes_per_event).must_equal 1
        _(config.max_attributes_per_link).must_equal 1
      end
    end

    it 'reflects explicit overrides' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_RUBY_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '4',
               'OTEL_TRACES_SAMPLER' => 'always_on') do
        config = trace_config.new(sampler: samplers::ALWAYS_OFF,
                                  max_attributes_count: 10,
                                  max_events_count: 11,
                                  max_links_count: 12,
                                  max_attributes_per_event: 13,
                                  max_attributes_per_link: 14,
                                  max_attributes_length: 32)
        _(config.sampler).must_equal samplers::ALWAYS_OFF
        _(config.max_attributes_count).must_equal 10
        _(config.max_events_count).must_equal 11
        _(config.max_links_count).must_equal 12
        _(config.max_attributes_per_event).must_equal 13
        _(config.max_attributes_per_link).must_equal 14
        _(config.max_attributes_length).must_equal 32
      end
    end

    it 'configures samplers from environment' do
      sampler = with_env('OTEL_TRACES_SAMPLER' => 'always_on') { trace_config.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_ON

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'always_off') { trace_config.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_OFF

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'traceidratio', 'OTEL_TRACES_SAMPLER_ARG' => '0.1') { trace_config.new.sampler }
      _(sampler).must_equal samplers.trace_id_ratio_based(0.1)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'traceidratio') { trace_config.new.sampler }
      _(sampler).must_equal samplers.trace_id_ratio_based(1.0)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_always_on') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_ON)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_always_off') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_OFF)

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_traceidratio', 'OTEL_TRACES_SAMPLER_ARG' => '0.2') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers.trace_id_ratio_based(0.2))

      sampler = with_env('OTEL_TRACES_SAMPLER' => 'parentbased_traceidratio') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers.trace_id_ratio_based(1.0))
    end
  end
end
