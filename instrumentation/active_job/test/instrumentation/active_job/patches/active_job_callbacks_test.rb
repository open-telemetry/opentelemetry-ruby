# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Patches::ActiveJobCallbacks do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  # Technically these are the defaults. But ActiveJob seems to act oddly if you re-install
  # the instrumentation over and over again - so we manipulate instance variables to
  # reset between tests, and that means we should set the defaults here.
  let(:config) { { propagation_style: :link, force_flush: false, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:send_span) { spans.find { |s| s.name == 'default send' } }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }

  before do
    instrumentation.instance_variable_set(:@config, config)
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@config, config)
  end

  describe 'perform_later' do
    it 'traces enqueuing and processing the job' do
      TestJob.perform_later

      _(send_span).wont_be_nil
      _(process_span).wont_be_nil
    end
  end

  describe 'perform_now' do
    it 'only traces processing the job' do
      TestJob.perform_now

      _(send_span).must_be_nil
      _(process_span).wont_be_nil
    end
  end

  describe 'compatibility' do
    it 'works with positional args' do
      _(PositionalOnlyArgsJob.perform_now('arg1')).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with keyword args' do
      _(KeywordOnlyArgsJob.perform_now(keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with mixed args' do
      _(MixedArgsJob.perform_now('arg1', 'arg2', keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end
  end

  describe 'exception handling' do
    it 'sets span status to error' do
      _ { ExceptionJob.perform_now }.must_raise StandardError, 'This job raises an exception'
      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(process_span.status.description).must_equal 'Unhandled exception of type: StandardError'
    end

    it 'records the exception' do
      _ { ExceptionJob.perform_now }.must_raise StandardError, 'This job raises an exception'
      _(process_span.events.first.name).must_equal 'exception'
      _(process_span.events.first.attributes['exception.type']).must_equal 'StandardError'
      _(process_span.events.first.attributes['exception.message']).must_equal 'This job raises an exception'
    end
  end

  describe 'span kind' do
    it 'sets correct span kinds for inline jobs' do
      TestJob.perform_later

      _(send_span.kind).must_equal(:client)
      _(process_span.kind).must_equal(:server)
    end

    it 'sets correct span kinds for all other jobs' do
      # Change the queue adapter so we get the right behavior
      ::ActiveJob::Base.queue_adapter = :async

      TestJob.perform_later
      ::ActiveJob::Base.queue_adapter.shutdown

      _(send_span.kind).must_equal(:producer)
      _(process_span.kind).must_equal(:consumer)
    ensure
      ::ActiveJob::Base.queue_adapter = :inline
    end
  end

  describe 'attributes' do
    it 'sets the messaging.operation attribute only when processing the job' do
      TestJob.perform_later

      _(send_span.attributes['messaging.operation']).must_be_nil
      _(process_span.attributes['messaging.operation']).must_equal('process')
    end

    describe 'net.transport' do
      it 'is sets correctly for inline jobs' do
        TestJob.perform_later

        [send_span, process_span].each do |span|
          _(span.attributes['net.transport']).must_equal('inproc')
        end
      end

      it 'is set correctly for async jobs' do
        ::ActiveJob::Base.queue_adapter = :async

        TestJob.perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        [send_span, process_span].each do |span|
          _(span.attributes['net.transport']).must_equal('inproc')
        end

      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'messaging.active_job.priority' do
      it 'is unset for unprioritized jobs' do
        TestJob.perform_later

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.priority']).must_be_nil
        end
      end

      it 'is set for jobs with a priority' do
        TestJob.set(priority: 1).perform_later

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.priority']).must_equal(1)
        end
      end
    end

    describe 'messaging.active_job.scheduled_at' do
      it 'is unset for jobs that do not specify a wait time' do
        TestJob.perform_later

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.scheduled_at']).must_be_nil
        end
      end

      it 'is set correctly for jobs that do wait' do
        ::ActiveJob::Base.queue_adapter = :async

        job = TestJob.set(wait: 0.second).perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        # Only the sending span is a 'scheduled' thing
        _(send_span.attributes['messaging.active_job.scheduled_at']).must_equal(job.scheduled_at)
        assert(send_span.attributes['messaging.active_job.scheduled_at'])

        # The processing span isn't a 'scheduled' thing
        _(process_span.attributes['messaging.active_job.scheduled_at']).must_be_nil

      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'messaging.system' do
      it 'is set correctly for the inline adapter' do
        TestJob.perform_later

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.system']).must_equal('inline')
        end
      end

      it 'is set correctly for the async adapter' do
        ::ActiveJob::Base.queue_adapter = :async

        TestJob.perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.system']).must_equal('async')
        end

      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'messaging.active_job.executions' do
      it 'is 1 for a normal job that does not retry' do
        TestJob.perform_now
        _(process_span.attributes['messaging.active_job.executions']).must_equal(1)
      end

      it 'tracks correctly for jobs that do retry' do
        ::ActiveJob::Base.queue_adapter = :async

        RetryJob.perform_now
        ::ActiveJob::Base.queue_adapter.shutdown

        # 1 enqueue, 2 perform
        _(spans.count).must_equal(3)

        span = spans.last
        _(span.kind).must_equal(:consumer)
        _(span.attributes['messaging.active_job.executions']).must_equal(2)

      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    it 'generally sets other attributes as expected' do
      job = TestJob.perform_later

      [send_span, process_span].each do |span|
        _(span.attributes['messaging.destination_kind']).must_equal('queue')
        _(span.attributes['messaging.system']).must_equal('inline')
        _(span.attributes['messaging.message_id']).must_equal(job.job_id)
      end
    end
  end

  describe 'span_naming option' do
    describe 'when queue - default' do
      it 'names spans according to the job queue' do
        TestJob.set(queue: :foo).perform_later
        send_span = exporter.finished_spans.find { |s| s.name == 'foo send' }
        _(send_span).wont_be_nil

        process_span = exporter.finished_spans.find { |s| s.name == 'foo process' }
        _(process_span).wont_be_nil
      end
    end

    describe 'when job_class' do
      let(:config) { { propagation_style: :link, span_naming: :job_class } }

      it 'names span according to the job class' do
        TestJob.set(queue: :foo).perform_later
        send_span = exporter.finished_spans.find { |s| s.name == 'TestJob send' }
        _(send_span).wont_be_nil

        process_span = exporter.finished_spans.find { |s| s.name == 'TestJob process' }
        _(process_span).wont_be_nil
      end
    end
  end

  describe 'force_flush option' do
    let(:mock_tracer_provider) do
      mock_tracer_provider = MiniTest::Mock.new
      mock_tracer_provider.expect(:force_flush, true)

      mock_tracer_provider
    end

    describe 'false - default' do
      it 'does not forcibly flush the tracer' do
        OpenTelemetry.stub(:tracer_provider, mock_tracer_provider) do
          TestJob.perform_later
        end

        # We *do not* actually force flush in this case, so we expect the mock
        # to fail validation - we will not actually call the mocked force_flush method.
        expect { mock_tracer_provider.verify }.must_raise MockExpectationError
      end
    end

    describe 'true' do
      let(:config) { { propagation_style: :link, force_flush: true, span_naming: :job_class } }
      it 'does forcibly flush the tracer' do
        OpenTelemetry.stub(:tracer_provider, mock_tracer_provider) do
          TestJob.perform_later
        end

        # Nothing should raise, the mock should be successful, we should have flushed.
        mock_tracer_provider.verify
      end
    end
  end

  describe 'propagation_style option' do
    describe 'link - default' do
      # The inline job adapter executes the job immediately upon enqueuing it
      # so we can't actually use that in these tests - the actual Context.current at time
      # of execution *will* be the context where the job was enqueued, because rails
      # ends up doing job.around_enqueue { job.around_perform { block } } inline.
      it 'creates span links in separate traces' do
        ::ActiveJob::Base.queue_adapter = :async

        TestJob.perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        _(send_span.trace_id).wont_equal(process_span.trace_id)

        _(process_span.total_recorded_links).must_equal(1)
        _(process_span.links[0].span_context.trace_id).must_equal(send_span.trace_id)
        _(process_span.links[0].span_context.span_id).must_equal(send_span.span_id)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end

      it 'propagates baggage' do
        ::ActiveJob::Base.queue_adapter = :async

        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end
        ::ActiveJob::Base.queue_adapter.shutdown

        _(send_span.trace_id).wont_equal(process_span.trace_id)

        _(process_span.total_recorded_links).must_equal(1)
        _(process_span.links[0].span_context.trace_id).must_equal(send_span.trace_id)
        _(process_span.links[0].span_context.span_id).must_equal(send_span.span_id)
        _(process_span.attributes['success']).must_equal(true)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'when configured to do parent/child spans' do
      let(:config) { { propagation_style: :child, span_naming: :queue } }

      it 'creates a parent/child relationship' do
        ::ActiveJob::Base.queue_adapter = :async

        TestJob.perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        _(process_span.total_recorded_links).must_equal(0)

        _(send_span.trace_id).must_equal(process_span.trace_id)
        _(process_span.parent_span_id).must_equal(send_span.span_id)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end

      it 'propagates baggage' do
        ::ActiveJob::Base.queue_adapter = :async

        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end
        ::ActiveJob::Base.queue_adapter.shutdown

        _(process_span.total_recorded_links).must_equal(0)

        _(send_span.trace_id).must_equal(process_span.trace_id)
        _(process_span.parent_span_id).must_equal(send_span.span_id)
        _(process_span.attributes['success']).must_equal(true)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'when explicitly configure for no propagation' do
      let(:config) { { propagation_style: :none, span_naming: :queue } }

      it 'skips link creation and does not create parent/child relationship' do
        ::ActiveJob::Base.queue_adapter = :async

        TestJob.perform_later
        ::ActiveJob::Base.queue_adapter.shutdown

        _(process_span.total_recorded_links).must_equal(0)

        _(send_span.trace_id).wont_equal(process_span.trace_id)
        _(process_span.parent_span_id).wont_equal(send_span.span_id)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end

      it 'still propagates baggage' do
        ::ActiveJob::Base.queue_adapter = :async

        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end
        ::ActiveJob::Base.queue_adapter.shutdown

        _(process_span.total_recorded_links).must_equal(0)

        _(send_span.trace_id).wont_equal(process_span.trace_id)
        _(process_span.parent_span_id).wont_equal(send_span.span_id)
        _(process_span.attributes['success']).must_equal(true)
      ensure
        ::ActiveJob::Base.queue_adapter = :inline
      end
    end
  end
end
