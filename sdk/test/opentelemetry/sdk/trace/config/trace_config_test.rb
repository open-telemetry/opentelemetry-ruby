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
      _(config.max_attributes_count).must_equal 1000
      _(config.max_events_count).must_equal 1000
      _(config.max_links_count).must_equal 1000
      _(config.max_attributes_per_event).must_equal 1000
      _(config.max_attributes_per_link).must_equal 1000
    end

    it 'reflects environment variables' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_TRACE_SAMPLER' => 'always_on') do
        config = trace_config.new
        _(config.sampler).must_equal samplers::ALWAYS_ON
        _(config.max_attributes_count).must_equal 1
        _(config.max_events_count).must_equal 2
        _(config.max_links_count).must_equal 3
        _(config.max_attributes_per_event).must_equal 1
        _(config.max_attributes_per_link).must_equal 1
      end
    end

    it 'reflects explicit overrides' do
      with_env('OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' => '1',
               'OTEL_SPAN_EVENT_COUNT_LIMIT' => '2',
               'OTEL_SPAN_LINK_COUNT_LIMIT' => '3',
               'OTEL_TRACE_SAMPLER' => 'always_on') do
        config = trace_config.new(sampler: samplers::ALWAYS_OFF,
                                  max_attributes_count: 10,
                                  max_events_count: 11,
                                  max_links_count: 12,
                                  max_attributes_per_event: 13,
                                  max_attributes_per_link: 14)
        _(config.sampler).must_equal samplers::ALWAYS_OFF
        _(config.max_attributes_count).must_equal 10
        _(config.max_events_count).must_equal 11
        _(config.max_links_count).must_equal 12
        _(config.max_attributes_per_event).must_equal 13
        _(config.max_attributes_per_link).must_equal 14
      end
    end

    it 'configures samplers from environment' do
      sampler = with_env('OTEL_TRACE_SAMPLER' => 'always_on') { trace_config.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_ON

      sampler = with_env('OTEL_TRACE_SAMPLER' => 'always_off') { trace_config.new.sampler }
      _(sampler).must_equal samplers::ALWAYS_OFF

      sampler = with_env('OTEL_TRACE_SAMPLER' => 'traceidratio', 'OTEL_TRACE_SAMPLER_ARG' => '0.1') { trace_config.new.sampler }
      _(sampler).must_equal samplers.trace_id_ratio_based(0.1)

      sampler = with_env('OTEL_TRACE_SAMPLER' => 'parentbased_always_on') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_ON)

      sampler = with_env('OTEL_TRACE_SAMPLER' => 'parentbased_always_off') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers::ALWAYS_OFF)

      sampler = with_env('OTEL_TRACE_SAMPLER' => 'parentbased_traceidratio', 'OTEL_TRACE_SAMPLER_ARG' => '0.2') { trace_config.new.sampler }
      _(sampler).must_equal samplers.parent_based(root: samplers.trace_id_ratio_based(0.2))
    end

    it 'requires OTEL_TRACE_SAMPLER_ARG for traceidratio' do
    end

    it 'requires OTEL_TRACE_SAMPLER_ARG for parentbased_traceidratio' do
    end
  end
end
