# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../../lib/opentelemetry/instrumentation/redis/patches/client'

describe OpenTelemetry::Instrumentation::Redis::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:password) { 'passw0rd' }
  let(:redis_host) { ENV['TEST_REDIS_HOST'] }
  let(:redis_port) { ENV['TEST_REDIS_PORT'].to_i }
  let(:last_span) { exporter.finished_spans.last }

  # Instantiate the Redis client with the correct password. Note that this
  # will generate one extra span on connect because the Redis client will
  # send an AUTH command before doing anything else.
  def redis_with_auth(redis_options = {})
    redis_options[:password] = password
    redis_options[:host] = redis_host
    redis_options[:port] = redis_port
    redis = ::Redis.new(redis_options)
    redis
  end

  before do
    # ensure obfuscation is off if it was previously set in a different test
    config = { db_statement: :include }
    instrumentation.install(config)
    exporter.reset
  end

  # Force re-install of instrumentation
  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#process' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      ::Redis.new(host: redis_host, port: redis_port).auth(password)

      _(last_span.attributes['peer.service']).must_equal 'readonly:redis'
    end

    it 'context attributes take priority' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      redis = redis_with_auth

      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(last_span.attributes['peer.service']).must_equal 'foo'
    end

    it 'after authorization with Redis server' do
      ::Redis.new(host: redis_host, port: redis_port).auth(password)

      _(last_span.name).must_equal 'AUTH'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'after requests' do
      redis = redis_with_auth
      _(redis.set('K', 'x')).must_equal 'OK'
      _(redis.get('K')).must_equal 'x'

      _(exporter.finished_spans.size).must_equal 3

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['net.peer.port']).must_equal redis_port

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal 'GET K'
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      _(get_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'reflects db index' do
      redis = redis_with_auth(db: 1)
      redis.get('K')

      _(exporter.finished_spans.size).must_equal 3

      select_span = exporter.finished_spans[1]
      _(select_span.name).must_equal 'SELECT'
      _(select_span.attributes['db.system']).must_equal 'redis'
      _(select_span.attributes['db.statement']).must_equal('SELECT 1')
      _(select_span.attributes['net.peer.name']).must_equal redis_host
      _(select_span.attributes['net.peer.port']).must_equal redis_port

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      _(get_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'merges context attributes' do
      redis = redis_with_auth
      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(exporter.finished_spans.size).must_equal 2

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['peer.service']).must_equal 'foo'
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'records exceptions' do
      expect do
        redis = redis_with_auth
        redis.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(last_span.status.description).must_equal(
        'ERR unknown command `THIS_IS_NOT_A_REDIS_FUNC`, with args beginning with: `THIS_IS_NOT_A_VALID_ARG`,'
      )
    end

    it 'records net.peer.name and net.peer.port attributes' do
      expect do
        ::Redis.new(host: 'example.com', port: 8321, timeout: 0.01).auth(password)
      end.must_raise Redis::CannotConnectError

      _(last_span.name).must_equal 'AUTH'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
      _(last_span.attributes['net.peer.name']).must_equal 'example.com'
      _(last_span.attributes['net.peer.port']).must_equal 8321
    end

    it 'traces pipelined commands' do
      redis = redis_with_auth
      redis.pipelined do |r|
        r.set('v1', '0')
        r.incr('v1')
        r.get('v1')
      end

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'traces pipelined commands on commit' do
      redis = redis_with_auth
      redis.queue([:set, 'v1', '0'])
      redis.queue([:incr, 'v1'])
      redis.queue([:get, 'v1'])
      redis.commit

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'records floats' do
      redis = redis_with_auth
      redis.hmset('hash', 'f1', 1_234_567_890.0987654321)

      _(last_span.name).must_equal 'HMSET'
      _(last_span.attributes['db.statement']).must_equal 'HMSET hash f1 1234567890.0987654'
    end

    it 'records nil' do
      redis = redis_with_auth
      redis.set('K', nil)

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K '
    end

    it 'records empty string' do
      redis = redis_with_auth
      redis.set('K', '')

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K '
    end

    it 'truncates long db.statements' do
      redis = redis_with_auth
      the_long_value = 'y' * 100
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.queue([:set, 'v1', the_long_value])
      redis.commit

      expected_db_statement = <<~HEREDOC.chomp
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy...
      HEREDOC

      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.statement'].size).must_equal 500
      _(last_span.attributes['db.statement']).must_equal expected_db_statement
    end

    it 'encodes invalid byte sequences for db.statement' do
      redis = redis_with_auth

      # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
      redis.set('K', "x\255")

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K x'
    end

    describe 'when trace_root_spans is disabled' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(trace_root_spans: false)
      end

      it 'traces redis spans with a parent' do
        redis = redis_with_auth
        OpenTelemetry.tracer_provider.tracer('tester').in_span('a root!') do
          redis.set('a', 'b')
        end

        redis_span = exporter.finished_spans.find { |s| s.name == 'SET' }
        _(redis_span.name).must_equal 'SET'
        _(redis_span.attributes['db.statement']).must_equal 'SET ? ?'
      end

      it 'does not trace redis spans without a parent' do
        redis = redis_with_auth
        redis.set('a', 'b')

        _(exporter.finished_spans.size).must_equal 0
      end
    end

    describe 'when db_statement is :omit' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :omit)
      end

      it 'omits db.statement attribute' do
        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(redis.get('K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal 'AUTH'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
      end
    end

    describe 'when db_statement is :obfuscate' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :obfuscate)
      end

      it 'obfuscates arguments in db.statement' do
        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(redis.get('K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal 'AUTH'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'AUTH ?'
        )

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'SET ? ?'
        )

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'GET ?'
        )
      end
    end
  end
end unless ENV['OMIT_SERVICES']
