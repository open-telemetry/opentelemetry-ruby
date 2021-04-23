# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Patches::ActiveJobCallbacks do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:send_span) { spans.find { |s| s.name == 'TestJob send' } }
  let(:process_span) { spans.find { |s| s.name == 'TestJob process' } }

  before { exporter.reset }

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
      # We need to ensure that the no-op Test Job actually runs in the background thread
      sleep 1

      _(send_span.kind).must_equal(:producer)
      _(process_span.kind).must_equal(:consumer)

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
        sleep 1

        [send_span, process_span].each do |span|
          _(span.attributes['net.transport']).must_equal('inproc')
        end

        ::ActiveJob::Base.queue_adapter = :inline
      end
    end

    describe 'messaging.active_job.priority' do
      it 'is unset for unprioritized jobs' do
        TestJob.perform_later

        [send_span, process_span].each do |span|
          assert_nil(span.attributes['messaging.active_job.priority'])
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
          assert_nil(span.attributes['messaging.active_job.scheduled_at'])
        end
      end

      it 'is set correctly for jobs that do wait' do
        ::ActiveJob::Base.queue_adapter = :async

        job = TestJob.set(wait: 0.5.second).perform_later
        sleep 1

        # Only the sending span is a 'scheduled' thing
        _(send_span.attributes['messaging.active_job.scheduled_at']).must_equal(job.scheduled_at)
        assert(send_span.attributes['messaging.active_job.scheduled_at'])

        # The processing span isn't a 'scheduled' thing
        assert_nil(process_span.attributes['messaging.active_job.scheduled_at'])

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
        sleep 1

        [send_span, process_span].each do |span|
          _(span.attributes['messaging.system']).must_equal('async')
        end

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
        sleep 1

        # 1 enqueue, 2 perform
        _(spans.count).must_equal(3)

        span = spans.last
        _(span.kind).must_equal(:consumer)
        _(span.attributes['messaging.active_job.executions']).must_equal(2)

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
end
