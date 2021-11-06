# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry-instrumentation-redis'

require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq'
require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq/patches/processor'

describe OpenTelemetry::Instrumentation::Sidekiq::Patches::Processor do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:redis_instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:config) { {} }
  let(:manager) { MockLoader.new.manager }
  let(:processor) { manager.workers.first }

  before do
    # Clear spans
    exporter.reset
    redis_instrumentation.install
    instrumentation.install(config)
  end

  after do
    # Force re-install of instrumentation
    redis_instrumentation.instance_variable_set(:@installed, false)
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#process_one' do
    it 'does not trace' do
      processor.send(:process_one)
      _(spans.size).must_equal(0)
    end

    describe 'when process_one tracing is enabled' do
      let(:config) { { trace_processor_process_one: true } }

      it 'traces' do
        processor.send(:process_one)
        span_names = spans.map(&:name)
        _(span_names).must_include('Sidekiq::Processor#process_one')
        _(span_names).must_include('BRPOP')
      end

      describe 'when peer_service config is set' do
        let(:config) { { trace_processor_process_one: true, peer_service: 'MySidekiqService' } }
        it 'add peer.service info' do
          processor.send(:process_one)
          span = spans.last
          _(span.attributes['peer.service']).must_equal 'MySidekiqService'
        end
      end
    end
  end unless ENV['OMIT_SERVICES']
end
