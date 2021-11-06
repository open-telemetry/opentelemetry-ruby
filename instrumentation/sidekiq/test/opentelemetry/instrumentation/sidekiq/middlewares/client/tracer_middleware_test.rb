# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/instrumentation/sidekiq'
require_relative '../../../../../../lib/opentelemetry/instrumentation/sidekiq/middlewares/client/tracer_middleware'

describe OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Client::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:enqueue_span) { spans.first }
  let(:config) { {} }

  before do
    instrumentation.install(config)
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
    Sidekiq::Worker.drain_all
  end

  describe 'process spans' do
    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'traces enqueing' do
      job_id = SimpleJob.perform_async

      _(exporter.finished_spans.size).must_equal 1

      _(enqueue_span.name).must_equal 'default send'
      _(enqueue_span.kind).must_equal :producer
      _(enqueue_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(enqueue_span.attributes['messaging.system']).must_equal 'sidekiq'
      _(enqueue_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
      _(enqueue_span.attributes['messaging.message_id']).must_equal job_id
      _(enqueue_span.attributes['messaging.destination']).must_equal 'default'
      _(enqueue_span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(enqueue_span.events.size).must_equal(1)
      _(enqueue_span.events[0].name).must_equal('created_at')
    end

    it 'traces when enqueued with Active Job' do
      SimpleJobWithActiveJob.perform_later(1, 2)
      _(enqueue_span.name).must_equal('default send')
      _(enqueue_span.attributes['messaging.system']).must_equal('sidekiq')
      _(enqueue_span.attributes['messaging.sidekiq.job_class']).must_equal('SimpleJobWithActiveJob')
      _(enqueue_span.attributes['messaging.destination']).must_equal('default')
      _(enqueue_span.attributes['messaging.destination_kind']).must_equal('queue')
    end

    describe 'when span_naming is job_class' do
      let(:config) { { span_naming: :job_class } }

      it 'uses the job class name for the span name' do
        SimpleJob.perform_async

        _(enqueue_span.name).must_equal('SimpleJob send')
      end

      it 'uses the job class name when enqueued with Active Job' do
        SimpleJobWithActiveJob.perform_later(1, 2)
        _(enqueue_span.name).must_equal('SimpleJobWithActiveJob send')
      end
    end

    describe 'when peer_service config is set' do
      let(:config) { { peer_service: 'MySidekiqService' } }

      it 'after performing a simple job' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(enqueue_span.attributes['peer.service']).must_equal 'MySidekiqService'
      end
    end
  end
end
