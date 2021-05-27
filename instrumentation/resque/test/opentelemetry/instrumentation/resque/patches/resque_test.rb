# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/resque'
require_relative '../../../../../lib/opentelemetry/instrumentation/resque/patches/resque_module'

describe OpenTelemetry::Instrumentation::Resque::Patches::ResqueModule do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Resque::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:enqueue_span) { exporter.finished_spans.first }
  let(:config) { {} }

  class DummyJob
    @queue = :super_urgent

    def self.perform(*args); end
  end

  before do
    instrumentation.install(config)
    exporter.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#enqueue' do
    it 'traces' do
      ::Resque.enqueue(DummyJob)

      _(enqueue_span.name).must_equal('super_urgent send')
      _(enqueue_span.attributes['messaging.system']).must_equal('resque')
      _(enqueue_span.attributes['messaging.resque.job_class']).must_equal('DummyJob')
      _(enqueue_span.attributes['messaging.destination']).must_equal('super_urgent')
      _(enqueue_span.attributes['messaging.destination_kind']).must_equal('queue')
    end

    describe 'when job_class_span_names is enabled' do
      let(:config) { { job_class_span_names: true } }

      it 'uses the job class name for the span name' do
        ::Resque.enqueue(DummyJob)

        _(enqueue_span.name).must_equal('DummyJob send')
      end
    end
  end
end unless ENV['OMIT_SERVICES']
