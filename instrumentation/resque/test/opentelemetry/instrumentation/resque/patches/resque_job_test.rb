# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/resque'
require_relative '../../../../../lib/opentelemetry/instrumentation/resque/patches/resque_job'

describe OpenTelemetry::Instrumentation::Resque::Patches::ResqueJob do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Resque::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:job_span) { finished_spans.last }
  let(:config) { {} }

  before do
    instrumentation.install(config)
    exporter.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#perform' do
    it 'traces' do
      ::Resque.enqueue(DummyJob)
      work_off_jobs

      _(job_span.name).must_equal('super_urgent process')
      _(job_span.attributes['messaging.system']).must_equal('resque')
      _(job_span.attributes['messaging.resque.job_class']).must_equal('DummyJob')
      _(job_span.attributes['messaging.destination']).must_equal('super_urgent')
      _(job_span.attributes['messaging.destination_kind']).must_equal('queue')
    end

    it 'traces when enqueued with Active Job' do
      DummyJobWithActiveJob.perform_later(1, 2)
      work_off_jobs

      _(job_span.name).must_equal('super_urgent process')
      _(job_span.attributes['messaging.system']).must_equal('resque')
      _(job_span.attributes['messaging.resque.job_class']).must_equal('DummyJobWithActiveJob')
      _(job_span.attributes['messaging.destination']).must_equal('super_urgent')
      _(job_span.attributes['messaging.destination_kind']).must_equal('queue')
    end

    it 'defaults to using links to the enqueing span but does not continue the trace' do
      ::Resque.enqueue(DummyJob)
      work_off_jobs

      enqueuer_span = finished_spans.first
      _(job_span.links.first.span_context.span_id).must_equal(enqueuer_span.span_id)
      _(job_span.links.first.span_context.trace_id).must_equal(enqueuer_span.trace_id)

      _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
      _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
    end

    describe 'when span_naming is job_class' do
      let(:config) { { span_naming: :job_class } }

      it 'uses the job class name for the span name' do
        ::Resque.enqueue(DummyJob)
        work_off_jobs

        _(job_span.name).must_equal('DummyJob process')
      end

      it 'uses the job class name when enqueued with Active Job' do
        DummyJobWithActiveJob.perform_later(1, 2)
        work_off_jobs

        _(job_span.name).must_equal('DummyJobWithActiveJob process')
      end
    end

    describe 'when propagation_style is link' do
      let(:config) { { propagation_style: :link } }

      it 'continues the enqueuer trace to the job process' do
        ::Resque.enqueue(DummyJob)
        work_off_jobs

        enqueuer_span = finished_spans.first
        _(job_span.links.first.span_context.span_id).must_equal(enqueuer_span.span_id)
        _(job_span.links.first.span_context.trace_id).must_equal(enqueuer_span.trace_id)

        enqueuer_span = finished_spans.first

        _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
        _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          ::Resque.enqueue(BaggageTestingJob)
        end

        work_off_jobs

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ::Resque.enqueue(ExceptionTestingJob)
        _(-> { work_off_jobs }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[0].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[0].attributes['exception.message']).must_equal('a little hell')
        _(ev[0].attributes['exception.stacktrace']).wont_be_nil
      end
    end

    describe 'when propagation_style is child' do
      let(:config) { { propagation_style: :child } }

      it 'continues the enqueuer trace to the job process' do
        ::Resque.enqueue(DummyJob)
        work_off_jobs

        enqueuer_span = finished_spans.first
        _(job_span.parent_span_id).must_equal(enqueuer_span.span_id)
        _(job_span.trace_id).must_equal(enqueuer_span.trace_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          ::Resque.enqueue(BaggageTestingJob)
        end

        work_off_jobs

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ::Resque.enqueue(ExceptionTestingJob)
        _(-> { work_off_jobs }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[0].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[0].attributes['exception.message']).must_equal('a little hell')
        _(ev[0].attributes['exception.stacktrace']).wont_be_nil
      end
    end

    describe 'when propagation_style is none' do
      let(:config) { { propagation_style: :none } }

      it 'continues the enqueuer trace to the job process' do
        ::Resque.enqueue(DummyJob)
        work_off_jobs

        enqueuer_span = finished_spans.first

        _(job_span.parent_span_id).wont_equal(enqueuer_span.span_id)
        _(job_span.trace_id).wont_equal(enqueuer_span.trace_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          ::Resque.enqueue(BaggageTestingJob)
        end

        work_off_jobs

        _(job_span.attributes['success']).must_equal(true)
      end

      it 'records exceptions' do
        ::Resque.enqueue(ExceptionTestingJob)
        _(-> { work_off_jobs }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[0].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[0].attributes['exception.message']).must_equal('a little hell')
        _(ev[0].attributes['exception.stacktrace']).wont_be_nil
      end
    end
  end unless ENV['OMIT_SERVICES']

  private

  def work_off_jobs
    while (job = ::Resque.reserve(:super_urgent))
      job.perform
    end
  end
end
