# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/concurrent-ruby'

describe OpenTelemetry::Adapters::ConcurrentRuby::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::ConcurrentRuby::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:tracer) { adapter.tracer }
  let(:unmodified_future) { @unmodified_future }

  before do
    exporter.reset
    @unmodified_future = ::Concurrent::Future.dup
  end

  after do
    # Force re-install of instrumentation
    ::Concurrent.send(:remove_const, :Future)
    ::Concurrent.const_set('Future', unmodified_future)
    adapter.instance_variable_set(:@installed, false)
  end

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'propagates context in Future threads' do
      outer_span = tracer.start_span('outer_span')
      inner_span = nil
      tracer.with_span(outer_span) do
        future = Concurrent::Future.new do
          inner_span = tracer.start_span('inner_span')
          inner_span.finish
        end
        future.execute

        future.wait
      end
      outer_span.finish

      _(exporter.finished_spans.size).must_equal 2
      _(inner_span.parent_span_id).must_equal outer_span.context.span_id
    end
  end
end
