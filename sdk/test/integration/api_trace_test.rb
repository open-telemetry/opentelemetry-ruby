# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK, 'API_trace' do
  let(:sdk) { OpenTelemetry::SDK }
  let(:exporter) { sdk::Trace::Export::InMemorySpanExporter.new }
  let(:span_processor) { sdk::Trace::Export::SimpleSpanProcessor.new(exporter) }
  let(:provider) do
    OpenTelemetry.tracer_provider = sdk::Trace::TracerProvider.new.tap do |provider|
      provider.add_span_processor(span_processor)
    end
  end
  let(:tracer) { provider.tracer(__FILE__, sdk::VERSION) }
  let(:remote_span_context) do
    OpenTelemetry::Trace::SpanContext.new(remote: true, trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED)
  end

  describe 'tracing root spans' do
    before do
      @root_span = tracer.start_root_span('root')

      OpenTelemetry::Trace.with_span(@root_span) do
        tracer.in_span('child of root') do |span|
          @child_of_root = span
        end
      end
    end

    it 'traces root spans' do
      _(@root_span.name).must_equal 'root'
    end

    it 'root has a child' do
      _(@child_of_root.to_span_data.parent_span_id).must_equal @root_span.to_span_data.span_id
    end

    it 'root has accurate total_recorded_links' do
      _(@root_span.to_span_data.total_recorded_links).must_equal 0
    end

    it "doesn't have links" do
      assert_nil @child_of_root.links
    end
  end

  describe 'tracing child-of-remote spans' do
    let(:context_with_remote_parent) do
      OpenTelemetry::Trace.context_with_span(
        OpenTelemetry::Trace.non_recording_span(remote_span_context),
        parent_context: OpenTelemetry::Context.empty
      )
    end

    before do
      @remote_span = tracer.start_span('remote', with_parent: context_with_remote_parent)
      @child_of_remote = tracer.start_span('child1', with_parent: OpenTelemetry::Trace.context_with_span(@remote_span))
    end

    it 'has a child' do
      _(@child_of_remote.to_span_data.parent_span_id).must_equal @remote_span.to_span_data.span_id
    end
  end

  describe 'tracing child-of-local spans' do
    before do
      @local_parent_span = tracer.start_span('local')
      parent_ctx = OpenTelemetry::Trace.context_with_span(@local_parent_span)
      OpenTelemetry::Trace.with_span(tracer.start_span('child1', with_parent: parent_ctx)) do |child|
        @child_of_local = child
      end
    end

    it 'traces child-of-local spans' do
      _(@child_of_local.to_span_data.parent_span_id).must_equal @local_parent_span.to_span_data.span_id
    end
  end

  describe 'tracing with links' do
    let(:attributes) do
      { 'component' => 'rack',
        'span.kind' => 'server',
        'http.method' => 'GET',
        'http.url' => 'blogs/index' }
    end
    let(:number_of_links) { 3 }
    let(:links) do
      Array.new(number_of_links) do
        OpenTelemetry::Trace::Link.new(remote_span_context, attributes)
      end
    end

    before do
      tracer.in_span('root') do
        tracer.in_span('child_with_links', links: links) do |span|
          @child_span_with_links = span
        end
      end
    end

    it 'span has links' do
      _(@child_span_with_links.to_span_data.links.size).must_equal number_of_links
    end
  end
end
