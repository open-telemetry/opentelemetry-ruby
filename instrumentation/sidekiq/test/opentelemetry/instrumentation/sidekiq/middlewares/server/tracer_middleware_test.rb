# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/instrumentation/sidekiq'
require_relative '../../../../../../lib/opentelemetry/instrumentation/sidekiq/middlewares/server/tracer_middleware'

describe OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:enqueuer_span) { spans.first }
  let(:job_span) { spans.last }
  let(:root_span) { spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID } }
  let(:config) { {} }

  before do
    instrumentation.install(config)
    exporter.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe 'enqueue spans' do
    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'traces processing' do
      job_id = SimpleJob.perform_async
      SimpleJob.drain

      _(exporter.finished_spans.size).must_equal 2

      _(job_span.name).must_equal 'default process'
      _(job_span.kind).must_equal :consumer
      _(job_span.attributes['messaging.system']).must_equal 'sidekiq'
      _(job_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
      _(job_span.attributes['messaging.message_id']).must_equal job_id
      _(job_span.attributes['messaging.destination']).must_equal 'default'
      _(job_span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(job_span.attributes['messaging.operation']).must_equal 'process'
      _(job_span.attributes['peer.service']).must_be_nil
      _(job_span.events.size).must_equal(2)
      _(job_span.events[0].name).must_equal('created_at')
      _(job_span.events[1].name).must_equal('enqueued_at')
    end

    it 'traces when enqueued with Active Job' do
      SimpleJobWithActiveJob.perform_later(1, 2)
      Sidekiq::Worker.drain_all

      _(job_span.name).must_equal('default process')
      _(job_span.attributes['messaging.system']).must_equal('sidekiq')
      _(job_span.attributes['messaging.sidekiq.job_class']).must_equal('SimpleJobWithActiveJob')
      _(job_span.attributes['messaging.destination']).must_equal('default')
      _(job_span.attributes['messaging.destination_kind']).must_equal('queue')
      _(job_span.attributes['messaging.operation']).must_equal 'process'
    end

    it 'defaults to using links to the enqueing span but does not continue the trace' do
      SimpleJob.perform_async
      SimpleJob.drain

      _(job_span.links.first.span_context.span_id).must_equal(enqueuer_span.span_id)
      _(job_span.links.first.span_context.trace_id).must_equal(enqueuer_span.trace_id)

      _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
      _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
    end

    describe 'when peer_service config is set' do
      let(:config) { { peer_service: 'MySidekiqService' } }

      it 'after performing a simple job' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(job_span.attributes['peer.service']).must_equal 'MySidekiqService'
      end
    end

    describe 'when span_naming is job_class' do
      let(:config) { { span_naming: :job_class } }

      it 'uses the job class name for the span name' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(job_span.name).must_equal('SimpleJob process')
      end

      it 'uses the job class name when enqueued with Active Job' do
        SimpleJobWithActiveJob.perform_later(1, 2)
        Sidekiq::Worker.drain_all

        _(job_span.name).must_equal('SimpleJobWithActiveJob process')
      end
    end

    describe 'when propagation_style is link' do
      let(:config) { { propagation_style: :link } }

      it 'continues the enqueuer trace to the job process' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(job_span.links.first.span_context.span_id).must_equal(enqueuer_span.span_id)
        _(job_span.links.first.span_context.trace_id).must_equal(enqueuer_span.trace_id)

        _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
        _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
      end

      it 'fan out jobs are linked' do
        SimpleEnqueueingJob.perform_async
        Sidekiq::Worker.drain_all

        _(exporter.finished_spans.size).must_equal 4

        # root job that enqueues another job
        _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
        _(root_span.name).must_equal 'default send'
        _(root_span.kind).must_equal :producer

        # process span is linked to the root enqueuing job
        child_span1 = spans.find { |s| s.links && s.links.first.span_context.span_id == root_span.span_id }
        _(child_span1.name).must_equal 'default process'
        _(child_span1.kind).must_equal :consumer

        # enquene span is child to the parent process job
        child_span2 = spans.find { |s| s.parent_span_id == child_span1.span_id }
        _(child_span2.name).must_equal 'default send'
        _(child_span2.kind).must_equal :producer

        # last process job is linked back to the process job that enqueued it
        child_span3 = spans.find { |s| s.links && s.links.first.span_context.span_id == child_span2.span_id }
        _(child_span3.name).must_equal 'default process'
        _(child_span3.kind).must_equal :consumer
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageTestingJob.perform_async
        end

        Sidekiq::Worker.drain_all

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ExceptionTestingJob.perform_async
        _(-> { Sidekiq::Worker.drain_all }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[2].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[2].attributes['exception.message']).must_equal('a little hell')
        _(ev[2].attributes['exception.stacktrace']).wont_be_nil
      end
    end

    describe 'when propagation_style is child' do
      let(:config) { { propagation_style: :child } }

      it 'continues the enqueuer trace to the job process' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(job_span.parent_span_id).must_equal(enqueuer_span.span_id)
        _(job_span.trace_id).must_equal(enqueuer_span.trace_id)
      end

      it 'fan out jobs are a continous trace' do
        SimpleEnqueueingJob.perform_async
        Sidekiq::Worker.drain_all

        _(exporter.finished_spans.size).must_equal 4

        _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
        _(root_span.name).must_equal 'default send'
        _(root_span.kind).must_equal :producer

        child_span1 = spans.find { |s| s.parent_span_id == root_span.span_id }
        _(child_span1.name).must_equal 'default process'
        _(child_span1.kind).must_equal :consumer

        child_span2 = spans.find { |s| s.parent_span_id == child_span1.span_id }
        _(child_span2.name).must_equal 'default send'
        _(child_span2.kind).must_equal :producer

        child_span3 = spans.find { |s| s.parent_span_id == child_span2.span_id }
        _(child_span3.name).must_equal 'default process'
        _(child_span3.kind).must_equal :consumer
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageTestingJob.perform_async
        end

        Sidekiq::Worker.drain_all

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ExceptionTestingJob.perform_async
        _(-> { Sidekiq::Worker.drain_all }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[2].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[2].attributes['exception.message']).must_equal('a little hell')
        _(ev[2].attributes['exception.stacktrace']).wont_be_nil
      end
    end

    describe 'when propagation_style is none' do
      let(:config) { { propagation_style: :none } }

      it 'continues the enqueuer trace to the job process' do
        SimpleJob.perform_async
        SimpleJob.drain

        _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
        _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageTestingJob.perform_async
        end

        Sidekiq::Worker.drain_all

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ExceptionTestingJob.perform_async
        _(-> { Sidekiq::Worker.drain_all }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[2].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[2].attributes['exception.message']).must_equal('a little hell')
        _(ev[2].attributes['exception.stacktrace']).wont_be_nil
      end
    end
  end
end
