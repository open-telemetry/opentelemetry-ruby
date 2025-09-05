# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Common do
  let(:exporter) { OpenTelemetry::Exporter::OTLP::Common }

  describe 'span flags' do
    let(:trace_id) { OpenTelemetry::Trace.generate_trace_id }
    let(:span_id) { OpenTelemetry::Trace.generate_span_id }
    let(:parent_span_id) { OpenTelemetry::Trace.generate_span_id }
    let(:local_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: parent_span_id, remote: false) }
    let(:remote_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: parent_span_id, remote: true) }
    let(:resource) { OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test-service') }
    let(:instrumentation_scope) { OpenTelemetry::SDK::InstrumentationScope.new('test-lib', '1.0.0') }

    describe 'build_span_flags' do
      it 'sets flags to 0x100 for local parent span context' do
        flags = exporter.send(:build_span_flags, local_span_context, 0)
        _(flags).must_equal(0x100) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
      end

      it 'sets flags to 0x300 for remote parent span context' do
        flags = exporter.send(:build_span_flags, remote_span_context, 0)
        _(flags).must_equal(0x300) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK | SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK
      end

      it 'sets flags to 0x100 for nil parent span context' do
        flags = exporter.send(:build_span_flags, nil, 0)
        _(flags).must_equal(0x100) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
      end

      it 'preserves base trace flags' do
        flags = exporter.send(:build_span_flags, local_span_context, 0x01) # SAMPLED flag
        _(flags).must_equal(0x101) # 0x01 (SAMPLED) | 0x100 (HAS_IS_REMOTE_MASK)
      end
    end

    describe 'as_otlp_span with flags' do
      it 'sets flags to 0x100 for local parent span context' do
        span_data = create_span_data(parent_span_context: local_span_context)
        span = exporter.send(:as_otlp_span, span_data)
        _(span.flags).must_equal(0x100) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
      end

      it 'sets flags to 0x300 for remote parent span context' do
        span_data = create_span_data(parent_span_context: remote_span_context)
        span = exporter.send(:as_otlp_span, span_data)
        _(span.flags).must_equal(0x300) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK | SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK
      end

      it 'sets flags to 0x100 for nil parent span context' do
        span_data = create_span_data(parent_span_context: nil)
        span = exporter.send(:as_otlp_span, span_data)
        _(span.flags).must_equal(0x100) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
      end
    end

    describe 'as_otlp_span with link flags' do
      it 'sets link flags to 0x100 for local link context' do
        local_link = create_link(local_span_context)
        span_data = create_span_data(links: [local_link])
        span = exporter.send(:as_otlp_span, span_data)
        _(span.links.first.flags).must_equal(0x100) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
      end

      it 'sets link flags to 0x300 for remote link context' do
        remote_link = create_link(remote_span_context)
        span_data = create_span_data(links: [remote_link])
        span = exporter.send(:as_otlp_span, span_data)
        _(span.links.first.flags).must_equal(0x300) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK | SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK
      end
    end

    describe 'as_etsr with flags' do
      it 'includes flags in exported spans' do
        span_data = create_span_data(parent_span_context: remote_span_context)
        etsr = exporter.as_etsr([span_data])
        exported_span = etsr.resource_spans.first.scope_spans.first.spans.first
        _(exported_span.flags).must_equal(0x300) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK | SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK
      end

      it 'includes flags in exported links' do
        remote_link = create_link(remote_span_context)
        span_data = create_span_data(links: [remote_link])
        etsr = exporter.as_etsr([span_data])
        exported_link = etsr.resource_spans.first.scope_spans.first.spans.first.links.first
        _(exported_link.flags).must_equal(0x300) # SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK | SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK
      end
    end

    private

    def create_span_data(parent_span_context: nil, links: [])
      OpenTelemetry::SDK::Trace::SpanData.new(
        'test-span',                    # name
        :internal,                      # kind
        OpenTelemetry::Trace::Status::OK, # status
        parent_span_id,                 # parent_span_id
        0,                             # total_recorded_attributes
        0,                             # total_recorded_events
        links.size,                    # total_recorded_links
        Time.now.to_i * 1_000_000_000, # start_timestamp
        Time.now.to_i * 1_000_000_000, # end_timestamp
        {},                            # attributes
        links,                         # links
        [],                            # events
        resource,                      # resource
        instrumentation_scope,         # instrumentation_scope
        span_id,                       # span_id
        trace_id,                      # trace_id
        OpenTelemetry::Trace::TraceFlags::DEFAULT, # trace_flags
        OpenTelemetry::Trace::Tracestate.new, # tracestate
        parent_span_context            # parent_span_context
      )
    end

    def create_link(span_context)
      OpenTelemetry::Trace::Link.new(span_context, { 'link-attribute' => 'link-value' })
    end
  end
end
