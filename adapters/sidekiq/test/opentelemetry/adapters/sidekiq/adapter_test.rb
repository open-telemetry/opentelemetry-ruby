# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/adapters/sidekiq'

class SimpleEnqueueingJob
  include Sidekiq::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Sidekiq::Worker

  def perform
  end
end

describe OpenTelemetry::Adapters::Sidekiq::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Sidekiq::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:root_span) { spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID } }

  before { exporter.reset }

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after performing a simple job' do
      job_id = SimpleJob.perform_async
      SimpleJob.drain

      _(exporter.finished_spans.size).must_equal 2

      _(root_span.name).must_equal 'SimpleJob'
      _(root_span.kind).must_equal :producer
      _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(root_span.attributes['messaging.message_id']).must_equal job_id
      _(root_span.attributes['messaging.destination']).must_equal 'default'
      _(root_span.events.size).must_equal(1)
      _(root_span.events[0].name).must_equal('created_at')

      child_span = exporter.finished_spans.last
      _(child_span.name).must_equal 'SimpleJob'
      _(child_span.kind).must_equal :consumer
      _(child_span.parent_span_id).must_equal root_span.span_id
      _(child_span.attributes['messaging.message_id']).must_equal job_id
      _(child_span.attributes['messaging.destination']).must_equal 'default'
      _(child_span.events.size).must_equal(2)
      _(child_span.events[0].name).must_equal('created_at')
      _(child_span.events[1].name).must_equal('enqueued_at')

      _(child_span.trace_id).must_equal root_span.trace_id
    end

    it 'after performing a simple job enqueuer' do
      SimpleEnqueueingJob.perform_async
      Sidekiq::Worker.drain_all

      _(exporter.finished_spans.size).must_equal 4

      _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(root_span.name).must_equal 'SimpleEnqueueingJob'
      _(root_span.kind).must_equal :producer

      child_span_1 = spans.find { |s| s.parent_span_id == root_span.span_id }
      _(child_span_1.name).must_equal 'SimpleEnqueueingJob'
      _(child_span_1.kind).must_equal :consumer

      child_span_2 = spans.find { |s| s.parent_span_id == child_span_1.span_id }
      _(child_span_2.name).must_equal 'SimpleJob'
      _(child_span_2.kind).must_equal :producer

      child_span_3 = spans.find { |s| s.parent_span_id == child_span_2.span_id }
      _(child_span_3.name).must_equal 'SimpleJob'
      _(child_span_3.kind).must_equal :consumer
    end
  end
end
