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
    puts 'Simple work accomplished'
  end
end

describe OpenTelemetry::Adapters::Sidekiq::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Sidekiq::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:root_span) { spans.find { |s| s.parent_span_id == '0000000000000000' } }

  before { exporter.reset }

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after performing a simple job' do
      job_id = Sidekiq::Testing.inline! { SimpleJob.perform_async }
      _(exporter.finished_spans.size).must_equal 2

      _(root_span.attributes['job_id']).must_equal job_id
      _(root_span.attributes['messaging.destination']).must_equal 'default'
      _(root_span.attributes['created_at']).wont_be_nil
      _(root_span.name).must_equal 'SimpleJob'
      _(root_span.kind).must_equal :producer
      _(root_span.parent_span_id).must_equal '0000000000000000'

      child_span = exporter.finished_spans.last
      _(child_span.attributes['job_id']).must_equal job_id
      _(child_span.attributes['messaging.destination']).must_equal 'default'
      _(child_span.attributes['created_at']).wont_be_nil
      _(child_span.name).must_equal 'SimpleJob'
      _(child_span.kind).must_equal :consumer
      _(child_span.parent_span_id).must_equal root_span.span_id

      _(child_span.trace_id).must_equal root_span.trace_id
    end

    it 'after performing a simple job enqueuer' do
      job_id = Sidekiq::Testing.inline! { SimpleEnqueueingJob.perform_async }
      _(exporter.finished_spans.size).must_equal 4

      _(root_span.parent_span_id).must_equal '0000000000000000'
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
