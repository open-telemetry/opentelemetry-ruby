# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/delayed_job'
require_relative '../../../../../lib/opentelemetry/instrumentation/delayed_job/plugins/tracer_plugin'

describe OpenTelemetry::Instrumentation::DelayedJob::Plugins::TracerPlugin do
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
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    OpenTelemetry.propagation = @orig_propagation

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

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.name).must_equal 'default send'
      _(span.attributes['messaging.system']).must_equal 'delayed_job'
      _(span.attributes['messaging.destination']).must_equal 'default'
      _(span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(span.attributes['messaging.delayed_job.name']).must_equal 'BasicPayload'
      _(span.attributes['messaging.delayed_job.priority']).must_equal 0
      _(span.attributes['messaging.operation']).must_equal 'send'
      _(span.attributes['messaging.message_id']).must_be_kind_of String

      _(span.events.size).must_equal 2
      _(span.events[0].name).must_equal 'created_at'
      _(span.events[0].timestamp).must_be_kind_of Integer
      _(span.events[1].name).must_equal 'run_at'
      _(span.events[1].timestamp).must_be_kind_of Integer
    end

    describe 'when queue name is set' do
      let(:job_params) { { queue: 'foobar_queue' } }

      it 'span tags include queue name' do
        job_enqueue
        _(span.attributes['messaging.destination']).must_equal 'foobar_queue'
        _(span.attributes['messaging.destination_kind']).must_equal 'queue'
      end
    end

    describe 'when priority is set' do
      let(:job_params) { { priority: 123 } }

      it 'span tags include priority' do
        job_enqueue
        _(span.attributes['messaging.delayed_job.priority']).must_equal 123
      end
    end

    describe 'when the job looks like Active Job' do
      let(:job_enqueue) { Delayed::Job.enqueue(@active_job_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_enqueue
        _(span.attributes['messaging.delayed_job.name']).must_equal 'UnderlyingJobClass'
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
      _(exporter.finished_spans.first.name).must_equal 'default send'
      job_run
      _(exporter.finished_spans.size).must_equal 2

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.name).must_equal 'default process'
      _(span.attributes['messaging.system']).must_equal 'delayed_job'
      _(span.attributes['messaging.destination']).must_equal 'default'
      _(span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(span.attributes['messaging.delayed_job.name']).must_equal 'BasicPayload'
      _(span.attributes['messaging.delayed_job.priority']).must_equal 0
      _(span.attributes['messaging.delayed_job.attempts']).must_equal 0
      _(span.attributes['messaging.delayed_job.locked_by']).must_be_kind_of String
      _(span.attributes['messaging.operation']).must_equal 'process'
      _(span.attributes['messaging.message_id']).must_be_kind_of String

      _(span.events.size).must_equal 3
      _(span.events[0].name).must_equal 'created_at'
      _(span.events[0].timestamp).must_be_kind_of Integer
      _(span.events[1].name).must_equal 'run_at'
      _(span.events[1].timestamp).must_be_kind_of Integer
      _(span.events[2].name).must_equal 'locked_at'
      _(span.events[2].timestamp).must_be_kind_of Integer
    end

    describe 'when queue name is set' do
      let(:job_params) { { queue: 'foobar_queue' } }

      it 'span tags include queue name' do
        job_run
        _(span.attributes['messaging.destination']).must_equal 'foobar_queue'
        _(span.attributes['messaging.destination_kind']).must_equal 'queue'
      end
    end

    describe 'when priority is set' do
      let(:job_params) { { priority: 123 } }

      it 'span tags include priority' do
        job_run
        _(span.attributes['messaging.delayed_job.priority']).must_equal 123
      end
    end

    describe 'when the job looks like Active Job' do
      let(:job_enqueue) { Delayed::Job.enqueue(@active_job_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_run
        _(span.attributes['messaging.delayed_job.name']).must_equal 'UnderlyingJobClass'
      end
    end

    describe 'when the job raises an error' do
      let(:job_enqueue) { Delayed::Job.enqueue(@error_payload.new, job_params) }

      it 'has resource name equal to underlying ActiveJob class name' do
        job_run
        _(span.attributes['messaging.delayed_job.name']).must_equal 'ErrorPayload'
        _(span.events.size).must_equal 4
        _(span.events[3].name).must_equal 'exception'
        _(span.events[3].timestamp).must_be_kind_of Integer
        _(span.events[3].attributes['exception.type']).must_equal 'ArgumentError'
        _(span.events[3].attributes['exception.message']).must_equal 'This job failed'
      end
    end
  end
end
