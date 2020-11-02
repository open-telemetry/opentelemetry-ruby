# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/delayed_job'
require_relative '../../../../../lib/opentelemetry/instrumentation/delayed_job/middlewares/tracer_middleware'

describe OpenTelemetry::Instrumentation::DelayedJob::Middlewares::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::DelayedJob::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }

  before do
    TestHelper.setup_active_record

    stub_const('BasicPayload', Class.new do
      def perform; end
    end)
    @basic_payload = BasicPayload

    stub_const('ErrorPayload', Class.new do
      def perform
        raise ArgumentError, 'This job failed'
      end
    end)
    @error_payload = ErrorPayload

    stub_const('ActiveJobPayload', Class.new do
      def perform; end

      def job_data
        { 'job_class' => 'UnderlyingJobClass' }
      end
    end)
    @active_job_payload = ActiveJobPayload

    instrumentation.install
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagator = OpenTelemetry.propagation.http
    propagator = OpenTelemetry::Context::Propagation::Propagator.new(
      OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector,
      OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor
    )
    OpenTelemetry.propagation.http = propagator
  end

  after do
    OpenTelemetry.propagation.http = @orig_propagator

    TestHelper.teardown_active_record
  end

  describe 'enqueue callback' do
    let(:job_params) { {} }
    let(:job_enqueue) { Delayed::Job.enqueue(@basic_payload.new, job_params) }
    let(:span) { exporter.finished_spans.first }

    it 'creates an enqueue span' do
      _(exporter.finished_spans).must_equal []
      job_enqueue
      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'delayed_job.enqueue'

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.attributes['component']).must_equal 'delayed_job'
      _(span.attributes['delayed_job.name']).must_equal 'BasicPayload'
      _(span.attributes['delayed_job.id']).must_be_kind_of Integer
      _(span.attributes['delayed_job.queue']).must_equal nil
      _(span.attributes['delayed_job.priority']).must_equal 0
      _(span.attributes['delayed_job.queue']).must_equal nil

      _(span.events.size).must_equal 2
      _(span.events[0].name).must_equal 'created_at'
      _(span.events[0].timestamp).must_be_kind_of Time
      _(span.events[1].name).must_equal 'run_at'
      _(span.events[1].timestamp).must_be_kind_of Time
    end

    describe 'when queue name is set' do
      let(:job_params) { { queue: 'foobar_queue' } }

      it 'span tags include queue name' do
        job_enqueue
        _(span.attributes['delayed_job.queue']).must_equal 'foobar_queue'
      end
    end

    describe 'when priority is set' do
      let(:job_params) { { priority: 123 } }

      it 'span tags include priority' do
        job_enqueue
        _(span.attributes['delayed_job.priority']).must_equal 123
      end
    end

    describe 'when the job looks like Active Job' do
      let(:job_enqueue) { Delayed::Job.enqueue(@active_job_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_enqueue
        _(span.attributes['delayed_job.name']).must_equal 'UnderlyingJobClass'
      end
    end
  end

  describe 'invoke_job callback' do
    let(:job_params) { {} }
    let(:job_enqueue) { Delayed::Job.enqueue(@basic_payload.new, job_params) }
    let(:job_run) do
      job_enqueue
      Delayed::Worker.new.work_off
    end

    it 'creates an invoke span' do
      _(exporter.finished_spans).must_equal []
      job_enqueue
      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.first.name).must_equal 'delayed_job.enqueue'
      job_run
      _(exporter.finished_spans.size).must_equal 2
      _(span.name).must_equal 'delayed_job.invoke'

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.attributes['component']).must_equal 'delayed_job'
      _(span.attributes['delayed_job.name']).must_equal 'BasicPayload'
      _(span.attributes['delayed_job.id']).must_be_kind_of Integer
      _(span.attributes['delayed_job.queue']).must_equal nil
      _(span.attributes['delayed_job.priority']).must_equal 0
      _(span.attributes['delayed_job.queue']).must_equal nil
      _(span.attributes['delayed_job.attempts']).must_equal 0
      _(span.attributes['delayed_job.locked_by']).must_be_kind_of String

      _(span.events.size).must_equal 3
      _(span.events[0].name).must_equal 'created_at'
      _(span.events[0].timestamp).must_be_kind_of Time
      _(span.events[1].name).must_equal 'run_at'
      _(span.events[1].timestamp).must_be_kind_of Time
      _(span.events[2].name).must_equal 'locked_at'
      _(span.events[2].timestamp).must_be_kind_of Time
    end

    describe 'when queue name is set' do
      let(:job_params) { { queue: 'foobar_queue' } }

      it 'span tags include queue name' do
        job_run
        _(span.attributes['delayed_job.queue']).must_equal 'foobar_queue'
      end
    end

    describe 'when priority is set' do
      let(:job_params) { { priority: 123 } }

      it 'span tags include priority' do
        job_run
        _(span.attributes['delayed_job.priority']).must_equal 123
      end
    end

    describe 'when the job looks like Active Job' do
      let(:job_enqueue) { Delayed::Job.enqueue(@active_job_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_run
        _(span.attributes['delayed_job.name']).must_equal 'UnderlyingJobClass'
      end
    end

    describe 'when the job raises an error' do
      let(:job_enqueue) { Delayed::Job.enqueue(@error_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_run
        _(span.attributes['delayed_job.name']).must_equal 'ErrorPayload'
        _(span.attributes['error']).must_equal true
        _(span.attributes['error.kind']).must_equal 'ArgumentError'
        _(span.attributes['message']).must_equal 'This job failed'
        _(span.events.size).must_equal 4
        _(span.events[3].name).must_equal 'exception'
        _(span.events[3].timestamp).must_be_kind_of Time
      end
    end
  end

  # TODO: do we need to call #shutdown??
  # describe 'execute callback' do
  #   let(:worker) { double(:worker, name: 'worker') }
  #
  #   before do
  #     allow(exporter).to receive(:shutdown).and_call_original
  #   end
  #
  #   it 'execution callback yields control' do
  #     result = nil
  #     Delayed::Worker.lifecycle.run_callbacks(:execute, worker) do |b|
  #       result = b
  #     end
  #     _(result).must_equal worker
  #   end
  #
  #   it 'shutdown happens after yielding' do
  #     Delayed::Worker.lifecycle.run_callbacks(:execute, worker) do
  #       expect(exporter).not_to have_received(:shutdown)
  #     end
  #
  #     expect(exporter).to have_received(:shutdown)
  #   end
  # end
end
