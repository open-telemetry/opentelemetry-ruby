# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry-instrumentation-redis'

require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq'
require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq/patches/poller'

describe OpenTelemetry::Instrumentation::Sidekiq::Patches::Poller do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:redis_instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:config) { {} }
  let(:poller) { MockLoader.new.poller }

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

  describe '#enqueue' do
    it 'does not trace' do
      poller.enqueue
      _(spans.size).must_equal(0)
    end

    describe 'when enqueue tracing is enabled' do
      let(:config) { { trace_poller_enqueue: true } }

      it 'traces' do
        poller.enqueue
        span_names = spans.map(&:name)
        _(span_names).must_include('Sidekiq::Scheduled::Poller#enqueue')
        # Inline Lua uses a different redis client method in 6.3+ https://github.com/mperham/sidekiq/pull/5044
        _(span_names).must_include('ZRANGEBYSCORE') if Gem.loaded_specs['sidekiq'].version < Gem::Version.new('6.3')
      end

      describe 'when peer_service config is set' do
        let(:config) { { trace_poller_enqueue: true, peer_service: 'MySidekiqService' } }
        it 'add peer.service info' do
          poller.enqueue
          span = spans.last
          _(span.attributes['peer.service']).must_equal 'MySidekiqService'
        end
      end
    end
  end unless ENV['OMIT_SERVICES']

  describe '#wait' do
    it 'does not trace' do
      poller.stub(:random_poll_interval, 0.0) do
        poller.send(:wait)
      end

      _(spans.size).must_equal(0)
    end

    describe 'when wait tracing is enabled' do
      let(:config) { { trace_poller_wait: true } }

      it 'traces' do
        poller.stub(:random_poll_interval, 0.0) do
          poller.send(:wait)
        end

        span_names = spans.map(&:name)
        _(span_names).must_include('Sidekiq::Scheduled::Poller#wait')
      end
    end
  end
end
