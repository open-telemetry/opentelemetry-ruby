# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/dalli'
require_relative '../../../../lib/opentelemetry/instrumentation/dalli/patches/server'

describe OpenTelemetry::Instrumentation::Dalli::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Dalli::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:host) { ENV.fetch('TEST_MEMCACHED_HOST') { '127.0.0.1' } }
  let(:port) { (ENV.fetch('TEST_MEMCACHED_PORT') { 11_211 }).to_i }
  let(:dalli) { ::Dalli::Client.new("#{host}:#{port}", {}) }

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

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:memcached')
      dalli.set('foo', 'bar')

      _(span.attributes['peer.service']).must_equal 'readonly:memcached'
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after dalli#set' do
      dalli.set('foo', 'bar')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'set'
      _(span.attributes['db.system']).must_equal 'memcached'
      _(span.attributes['db.statement']).must_equal 'set foo bar 0 0'
      _(span.attributes['net.peer.name']).must_equal host
      _(span.attributes['net.peer.port']).must_equal port
    end

    it 'after dalli#set' do
      dalli.get('foo')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'get'
      _(span.attributes['db.system']).must_equal 'memcached'
      _(span.attributes['db.statement']).must_equal 'get foo'
      _(span.attributes['net.peer.name']).must_equal host
      _(span.attributes['net.peer.port']).must_equal port
    end

    it 'after dalli#get_multi' do
      dalli.get_multi('foo', 'bar')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'getkq'
      _(span.attributes['db.system']).must_equal 'memcached'
      _(span.attributes['db.statement']).must_equal 'getkq foo bar'
      _(span.attributes['net.peer.name']).must_equal host
      _(span.attributes['net.peer.port']).must_equal port
    end

    it 'after error' do
      dalli.set('foo', 'bar')
      exporter.reset

      dalli.instance_variable_get(:@ring).servers.first.stub(:write, ->(_bytes) { raise Dalli::DalliError }) do
        dalli.get_multi('foo', 'bar')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'getkq'
      _(span.attributes['db.system']).must_equal 'memcached'
      _(span.attributes['db.statement']).must_equal 'getkq foo bar'
      _(span.attributes['net.peer.name']).must_equal host
      _(span.attributes['net.peer.port']).must_equal port

      span_event = span.events.first
      _(span_event.name).must_equal 'exception'
      _(span_event.attributes['exception.type']).must_equal 'Dalli::DalliError'
      _(span_event.attributes['exception.message']).must_equal 'Dalli::DalliError'
    end

    it 'omits db.statement' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      dalli.set('foo', 'bar')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'set'
      _(span.attributes).wont_include 'db.statement'
    end

    it 'obfuscates db.statement' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :obfuscate)

      dalli.set('foo', 'bar')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'set'
      _(span.attributes['db.statement']).must_equal 'set ?'
    end
  end
end unless ENV['OMIT_SERVICES']
