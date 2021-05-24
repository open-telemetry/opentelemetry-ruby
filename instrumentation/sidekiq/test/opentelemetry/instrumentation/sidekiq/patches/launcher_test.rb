# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry-instrumentation-redis'

require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq'
require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq/patches/launcher'

describe OpenTelemetry::Instrumentation::Sidekiq::Patches::Launcher do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
  let(:redis_instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:config) { {} }
  let(:launcher) { MockLoader.new.launcher }

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

  # The method being tested here is `❤`
  describe '#heartbeat' do
    it 'does not trace' do
      launcher.send(:❤)
      _(spans.size).must_equal(0)
    end

    describe 'when heartbeat tracing is enabled' do
      let(:config) { { trace_launcher_heartbeat: true } }

      it 'traces' do
        launcher.send(:❤)
        span_names = spans.map(&:name)
        _(span_names).must_include('Sidekiq::Launcher#heartbeat')
        _(span_names).must_include('PIPELINED')
      end

      describe 'when peer_service config is set' do
        let(:config) { { trace_launcher_heartbeat: true, peer_service: 'MySidekiqService' } }
        it 'add peer.service info' do
          launcher.send(:❤)
          span = spans.last
          _(span.attributes['peer.service']).must_equal 'MySidekiqService'
        end
      end
    end
  end
end
