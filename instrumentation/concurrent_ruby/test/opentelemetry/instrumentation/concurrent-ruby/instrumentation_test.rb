# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/concurrent_ruby'

describe OpenTelemetry::Instrumentation::ConcurrentRuby::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ConcurrentRuby::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:tracer) { instrumentation.tracer }
  let(:unmodified_future) { @unmodified_future }

  before do
    exporter.reset
    @unmodified_future = ::Concurrent::ThreadPoolExecutor.dup
  end

  after do
    # Force re-install of instrumentation
    ::Concurrent.send(:remove_const, :ThreadPoolExecutor)
    ::Concurrent.const_set('ThreadPoolExecutor', unmodified_future)
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'propagates context in Future threads' do
      outer_span = tracer.start_span('outer_span')
      inner_span = nil
      OpenTelemetry::Trace.with_span(outer_span) do
        future = ::Concurrent::Future.new do
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

    it 'propagates context in Promises' do
      skip 'Concurrent::Promises is not defined' unless ::Concurrent.const_defined?(:Promises)
      outer_span = tracer.start_span('outer_span')
      inner_span = nil
      OpenTelemetry::Trace.with_span(outer_span) do
        future = ::Concurrent::Promises.future do
          inner_span = tracer.start_span('inner_span')
          inner_span.finish
        end
        future.value
      end
      outer_span.finish

      _(exporter.finished_spans.size).must_equal 2
      _(inner_span.parent_span_id).must_equal outer_span.context.span_id
    end

    it 'propagates context in Async mixins' do
      skip 'Concurrent::Async is not defined' unless ::Concurrent.const_defined?(:Async)
      outer_span = tracer.start_span('outer_span')
      async_inner_span = nil
      await_inner_span = nil

      worker = Class.new do
        include Concurrent::Async
        def initialize(tracer)
          @tracer = tracer
        end

        def action
          inner_span = @tracer.start_span('inner_span')
          inner_span.finish
        end
      end.new(tracer)

      OpenTelemetry::Trace.with_span(outer_span) do
        result = worker.await.action
        await_inner_span = result.value
        result = worker.async.action
        async_inner_span = result.value
      end
      outer_span.finish

      _(exporter.finished_spans.size).must_equal 3
      _(async_inner_span.parent_span_id).must_equal outer_span.context.span_id
      _(await_inner_span.parent_span_id).must_equal outer_span.context.span_id
    end
  end
end
