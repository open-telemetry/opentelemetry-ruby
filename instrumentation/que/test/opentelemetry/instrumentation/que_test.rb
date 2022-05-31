# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-instrumentation-pg'

describe OpenTelemetry::Instrumentation::Que do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Que::Instrumentation.instance }
  let(:pg_instrumentation) { OpenTelemetry::Instrumentation::PG::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:config) { { propagation_style: :link } }

  before do
    prepare_que
    pg_instrumentation.install
    instrumentation.install
    instrumentation.instance_variable_set(:@config, config)
    exporter.reset
  end

  describe 'enqueuing a job' do
    it 'creates a span' do
      TestJobAsync.enqueue

      _(finished_spans.size).must_equal(1)

      span = finished_spans.last
      _(span.kind).must_equal(:producer)
    end

    it 'names the created span' do
      TestJobAsync.enqueue

      span = finished_spans.last
      _(span.name).must_equal('TestJobAsync send')
    end

    it 'records attributes' do
      TestJobAsync.enqueue

      attributes = finished_spans.last.attributes
      _(attributes['messaging.system']).must_equal('que')
      _(attributes['messaging.destination']).must_equal('default')
      _(attributes['messaging.destination_kind']).must_equal('queue')
      _(attributes['messaging.operation']).must_equal('send')
      _(attributes['messaging.message_id']).must_be_instance_of(Integer)
      _(attributes['messaging.que.job_class']).must_equal('TestJobAsync')
      _(attributes['messaging.que.priority']).must_equal(100)
    end
  end

  describe 'processing a job' do
    before do
      job = TestJobAsync.enqueue
      exporter.reset
      Que.run_job_middleware(job) { job.tap(&:_run) }
    end

    it 'creates a span' do
      _(finished_spans.size).must_equal(1)

      span = finished_spans.last
      _(span.kind).must_equal(:consumer)
    end

    it 'names the created span' do
      span = finished_spans.last
      _(span.name).must_equal('TestJobAsync process')
    end

    it 'records attributes' do
      attributes = finished_spans.last.attributes
      _(attributes['messaging.system']).must_equal('que')
      _(attributes['messaging.destination']).must_equal('default')
      _(attributes['messaging.destination_kind']).must_equal('queue')
      _(attributes['messaging.operation']).must_equal('process')
      _(attributes['messaging.message_id']).must_be_instance_of(Integer)
      _(attributes['messaging.que.job_class']).must_equal('TestJobAsync')
      _(attributes['messaging.que.priority']).must_equal(100)
      _(attributes['messaging.que.attempts']).must_equal(0)
    end
  end

  describe 'processing a job that fails' do
    before do
      job = JobThatFails.enqueue
      exporter.reset
      Que.run_job_middleware(job) { job.tap(&:_run) }
    end

    it 'marks the span as failed' do
      span = finished_spans.last
      _(span.status.ok?).must_equal(false)
    end
  end

  # Sync job is usually used for testing. It bypasses the whole job storage
  # part and executes the job immediately. We'll still create a span for
  # creating a job and one for processing the job.
  describe 'enqueuing a sync job' do
    it 'creates two spans' do
      TestJobSync.enqueue

      _(finished_spans.size).must_equal(2)

      span1 = finished_spans.last
      _(span1.kind).must_equal(:producer)

      span2 = finished_spans.first
      _(span2.kind).must_equal(:consumer)
    end

    it 'names the created span' do
      TestJobSync.enqueue

      span1 = finished_spans.last
      _(span1.name).must_equal('TestJobSync send')

      span2 = finished_spans.first
      _(span2.name).must_equal('TestJobSync process')
    end

    it 'records attributes' do
      TestJobSync.enqueue

      attributes = finished_spans.first.attributes
      _(attributes['messaging.system']).must_equal('que')
      _(attributes['messaging.destination']).must_equal('default')
      _(attributes['messaging.destination_kind']).must_equal('queue')
      _(attributes['messaging.operation']).must_equal('process')
      _(attributes['messaging.que.job_class']).must_equal('TestJobSync')
      _(attributes['messaging.que.priority']).must_equal(100)
    end
  end

  describe 'span propagation' do
    describe 'when propagation_style is set to link' do
      it 'stores tracing information in the last parameter' do
        job_class = Class.new(Que::Job) do
          def self.run(first, second); end
        end
        first = 'first-argument'
        second = 'second-argument'
        job_class.enqueue(first, second, job_options: { job_class: 'LastHashParameter' })

        model = last_record_in_database
        _(model.data['tags'].size).must_equal(1)
        _(model.data['tags'][0]).must_match(/traceparent:/)
      end

      it 'keeps original tags' do
        job_class = Class.new(Que::Job) do
          def self.run(first, second); end
        end
        first = 'first-argument'
        second = 'second-argument'
        job_class.enqueue(first, second, job_options: { job_class: 'LastHashParameterWithTags', tags: ['high-priority'] })

        model = last_record_in_database
        _(model.data['tags'].size).must_equal(2)
        _(model.data['tags'][0]).must_equal('high-priority')
        _(model.data['tags'][1]).must_match(/traceparent:/)
      end

      it 'links spans together' do
        job = TestJobAsync.enqueue
        Que.run_job_middleware(job) { job.tap(&:_run) }

        _(finished_spans.size).must_equal(2)

        send_span = finished_spans.first
        process_span = finished_spans.last

        _(send_span.trace_id).wont_equal(process_span.trace_id)

        _(process_span.total_recorded_links).must_equal(1)
        _(process_span.links[0].span_context.trace_id).must_equal(send_span.trace_id)
        _(process_span.links[0].span_context.span_id).must_equal(send_span.span_id)
      end
    end

    describe 'when propagation_style is set to child' do
      let(:config) { { propagation_style: :child } }

      it 'links spans together using parent/child relationship' do
        job = TestJobAsync.enqueue
        Que.run_job_middleware(job) { job.tap(&:_run) }

        _(finished_spans.size).must_equal(2)

        send_span = finished_spans.first
        process_span = finished_spans.last

        _(send_span.trace_id).must_equal(process_span.trace_id)
        _(process_span.parent_span_id).must_equal(send_span.span_id)
        _(process_span.total_recorded_links).must_equal(0)
      end
    end

    describe 'when propagation_style is set to none' do
      let(:config) { { propagation_style: :none } }

      it 'does not store tracing information' do
        job_class = Class.new(Que::Job) do
          def self.run(first, second); end
        end
        first = 'first-argument'
        second = 'second-argument'
        job_class.enqueue(first, second, job_options: { job_class: 'PropagationStyleSetToNone' })

        model = last_record_in_database
        _(model.data['tags']).must_be_nil
      end

      it 'does not link spans together' do
        job = TestJobAsync.enqueue
        Que.run_job_middleware(job) { job.tap(&:_run) }

        _(finished_spans.size).must_equal(2)

        send_span = finished_spans.first
        process_span = finished_spans.last

        _(send_span.trace_id).wont_equal(process_span.trace_id)
        _(send_span.total_recorded_links).must_equal(0)
        _(process_span.total_recorded_links).must_equal(0)
      end
    end
  end

  describe 'que poller' do
    describe 'when trace_poller is enabled' do
      let(:config) { { trace_poller: true } }

      it 'traces calls to Que::Poller#poll' do
        spans = run_one_locker_cycle
        spans = spans.sort_by(&:name)

        root_span = spans.detect { |span| span.name == 'Que::Poller#poll' }
        _(root_span.parent_span_id).must_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)

        other_spans = spans - [root_span]
        _(other_spans.count.positive?).must_equal(true)

        other_spans.each do |other_span|
          _(other_span.parent_span_id).must_equal(root_span.span_id)
        end
      end
    end

    describe 'when trace_poller is disabled' do
      let(:config) { { trace_poller: false } }

      it 'does not create any spans' do
        spans = run_one_locker_cycle
        _(spans).must_equal([])
      end
    end
  end

  def finished_spans(include_pg: false)
    if include_pg
      exporter.finished_spans
    else
      exporter.finished_spans.reject { |span| span.name =~ /#{database_name}/ }
    end
  end

  def last_record_in_database
    require 'que/active_record/model'
    Que::ActiveRecord::Model.last
  end

  def run_one_locker_cycle
    poll_interval = 0.1 # in seconds
    locker = Que::Locker.new(poll_interval: poll_interval, wait_period: 0.001)

    # Clear all the startup spans
    sleep 0.05
    exporter.reset

    sleep poll_interval
    finished_spans = finished_spans(include_pg: true)
    locker.stop!

    finished_spans
  end
end unless ENV['OMIT_SERVICES']
