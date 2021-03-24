# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/sidekiq'

class SimpleEnqueueingJob
  include Sidekiq::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Sidekiq::Worker

  def perform; end
end

describe OpenTelemetry::Instrumentation::Sidekiq::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:root_span) { spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID } }
  let(:config) { {} }

  before { exporter.reset }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Sidekiq'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      Gem.stub(:loaded_specs, 'sidekiq' => Gem::Specification.new { |s| s.version = '4.2.8' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'tracing' do
    before do
      instrumentation.install(config)
    end

    after do
      # Need to reset install state to uptake config
      instrumentation.instance_variable_set(:@installed, false)
    end

    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after performing a simple job' do
      job_id = SimpleJob.perform_async
      SimpleJob.drain

      _(exporter.finished_spans.size).must_equal 2

      _(root_span.name).must_equal 'default send'
      _(root_span.kind).must_equal :producer
      _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(root_span.attributes['messaging.system']).must_equal 'sidekiq'
      _(root_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
      _(root_span.attributes['messaging.message_id']).must_equal job_id
      _(root_span.attributes['messaging.destination']).must_equal 'default'
      _(root_span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(root_span.events.size).must_equal(1)
      _(root_span.events[0].name).must_equal('created_at')

      child_span = exporter.finished_spans.last
      _(child_span.name).must_equal 'default process'
      _(child_span.kind).must_equal :consumer
      _(child_span.parent_span_id).must_equal root_span.span_id
      _(child_span.attributes['messaging.system']).must_equal 'sidekiq'
      _(child_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
      _(child_span.attributes['messaging.message_id']).must_equal job_id
      _(child_span.attributes['messaging.destination']).must_equal 'default'
      _(child_span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(child_span.attributes['peer.service']).must_be_nil
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

    describe 'uses job class for span names' do
      let(:config) { { enable_job_class_span_names: true } }

      it 'after performing a simple job' do
        job_id = SimpleJob.perform_async
        SimpleJob.drain

        _(root_span.name).must_equal 'SimpleJob enqueue'
        _(root_span.kind).must_equal :producer
        _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
        _(root_span.attributes['messaging.system']).must_equal 'sidekiq'
        _(root_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
        _(root_span.attributes['messaging.message_id']).must_equal job_id
        _(root_span.attributes['messaging.destination']).must_equal 'default'
        _(root_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(root_span.events.size).must_equal(1)
        _(root_span.events[0].name).must_equal('created_at')

        child_span = exporter.finished_spans.last
        _(child_span.name).must_equal 'SimpleJob process'
        _(child_span.kind).must_equal :consumer
        _(child_span.parent_span_id).must_equal root_span.span_id
        _(child_span.attributes['messaging.system']).must_equal 'sidekiq'
        _(child_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
        _(child_span.attributes['messaging.message_id']).must_equal job_id
        _(child_span.attributes['messaging.destination']).must_equal 'default'
        _(child_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(child_span.events.size).must_equal(2)
        _(child_span.events[0].name).must_equal('created_at')
        _(child_span.events[1].name).must_equal('enqueued_at')

        _(child_span.trace_id).must_equal root_span.trace_id
      end
    end

    describe 'when peer_service config is set' do
      let(:config) { { peer_service: 'MySidekiqService' } }

      it 'after performing a simple job' do
        job_id = SimpleJob.perform_async
        SimpleJob.drain

        _(root_span.name).must_equal 'default send'
        _(root_span.kind).must_equal :producer
        _(root_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
        _(root_span.attributes['messaging.system']).must_equal 'sidekiq'
        _(root_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
        _(root_span.attributes['messaging.message_id']).must_equal job_id
        _(root_span.attributes['messaging.destination']).must_equal 'default'
        _(root_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(root_span.attributes['peer.service']).must_equal 'MySidekiqService'
        _(root_span.events.size).must_equal(1)
        _(root_span.events[0].name).must_equal('created_at')

        child_span = exporter.finished_spans.last
        _(child_span.name).must_equal 'default process'
        _(child_span.kind).must_equal :consumer
        _(child_span.parent_span_id).must_equal root_span.span_id
        _(child_span.attributes['messaging.system']).must_equal 'sidekiq'
        _(child_span.attributes['messaging.sidekiq.job_class']).must_equal 'SimpleJob'
        _(child_span.attributes['messaging.message_id']).must_equal job_id
        _(child_span.attributes['messaging.destination']).must_equal 'default'
        _(child_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(child_span.attributes['peer.service']).must_equal 'MySidekiqService'
        _(child_span.events.size).must_equal(2)
        _(child_span.events[0].name).must_equal('created_at')
        _(child_span.events[1].name).must_equal('enqueued_at')

        _(child_span.trace_id).must_equal root_span.trace_id
      end
    end
  end
end
