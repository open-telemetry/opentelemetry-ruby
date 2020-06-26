# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentations/redis'
require_relative '../../../../lib/opentelemetry/instrumentations/redis/patches/client'

describe OpenTelemetry::Instrumentations::Redis::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentations::Redis::Instrumentation.instance }
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

    it 'after authorization with Redis server' do
      ::Redis.new.auth('password')

      _(span.name).must_equal 'AUTH'
      _(span.attributes['db.type']).must_equal 'redis'
      _(span.attributes['db.instance']).must_equal '0'
      _(span.attributes['db.statement']).must_equal 'AUTH ?'
      _(span.attributes['db.url']).must_equal 'redis://127.0.0.1:6379'
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
      _(set_span.attributes['db.type']).must_equal 'redis'
      _(set_span.attributes['db.instance']).must_equal '0'
      _(set_span.attributes['db.statement']).must_equal(
        'SET K ' + 'x' * 47 + '...'
      )
      _(set_span.attributes['db.url']).must_equal 'redis://127.0.0.1:6379'
      _(set_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(set_span.attributes['net.peer.port']).must_equal 6379

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.type']).must_equal 'redis'
      _(get_span.attributes['db.instance']).must_equal '0'
      _(get_span.attributes['db.statement']).must_equal 'GET K'
      _(get_span.attributes['db.url']).must_equal 'redis://127.0.0.1:6379'
      _(get_span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(get_span.attributes['net.peer.port']).must_equal 6379
    end

    it 'after error' do
      expect do
        ::Redis.new.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      _(span.attributes['db.type']).must_equal 'redis'
      _(span.attributes['db.instance']).must_equal '0'
      _(span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(span.attributes['db.url']).must_equal 'redis://127.0.0.1:6379'
      _(span.attributes['net.peer.name']).must_equal '127.0.0.1'
      _(span.attributes['net.peer.port']).must_equal 6379
      _(span.status.canonical_code).must_equal(
        OpenTelemetry::Trace::Status::UNKNOWN_ERROR
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
      _(span.attributes['db.type']).must_equal 'redis'
      _(span.attributes['db.instance']).must_equal '0'
      _(span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(span.attributes['db.url']).must_equal 'redis://example.com:8321'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 8321
    end
  end
end
