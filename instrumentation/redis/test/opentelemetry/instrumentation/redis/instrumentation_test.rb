# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../lib/opentelemetry/instrumentation/redis/patches/client'

describe OpenTelemetry::Instrumentation::Redis::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      ::Redis.new.auth('password')

      _(span.attributes['peer.service']).must_equal 'readonly:redis'
    end

    it 'context attributes take priority' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      redis = ::Redis.new

      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(span.attributes['peer.service']).must_equal 'foo'
    end

    it 'after authorization with Redis server' do
      ::Redis.new.auth('password')

      _(span.name).must_equal 'AUTH'
      _(span.attributes['db.system']).must_equal 'redis'
      _(span.attributes['db.statement']).must_equal 'AUTH ?'
      _(span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(span.attributes['net.peer.port']).must_equal 6379
    end

    it 'after requests' do
      redis = ::Redis.new
      _(redis.set('K', 'x' * 500)).must_equal 'OK'
      _(redis.get('K')).must_equal 'x' * 500

      _(exporter.finished_spans.size).must_equal 2

      set_span = exporter.finished_spans.first
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal(
        'SET K ' + 'x' * 47 + '...'
      )
      _(set_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(set_span.attributes['net.peer.port']).must_equal 6379

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal 'GET K'
      _(get_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(get_span.attributes['net.peer.port']).must_equal 6379
    end

    it 'reflects db index' do
      redis = ::Redis.new(db: 1)
      redis.get('K')

      _(exporter.finished_spans.size).must_equal 2

      select_span = exporter.finished_spans.first
      _(select_span.name).must_equal 'SELECT'
      _(select_span.attributes['db.system']).must_equal 'redis'
      _(select_span.attributes['db.statement']).must_equal('SELECT 1')
      _(select_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(select_span.attributes['net.peer.port']).must_equal 6379

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(get_span.attributes['net.peer.port']).must_equal 6379
    end

    it 'merges context attributes' do
      redis = ::Redis.new
      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(exporter.finished_spans.size).must_equal 1

      set_span = exporter.finished_spans.first
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['peer.service']).must_equal 'foo'
      _(set_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(set_span.attributes['net.peer.port']).must_equal 6379
    end

    it 'after error' do
      expect do
        ::Redis.new.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      _(span.attributes['db.system']).must_equal 'redis'
      _(span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(span.attributes['net.peer.port']).must_equal 6379
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: Redis::CommandError'
      )
    end

    it 'after pipeline' do
      ::Redis.new(host: 'example.com', port: '8321').pipelined do |redis|
        redis.set('v1', '0')
        redis.incr('v1')
        redis.get('v1')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'pipeline'
      _(span.attributes['db.system']).must_equal 'redis'
      _(span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 8321
    end
  end
end
