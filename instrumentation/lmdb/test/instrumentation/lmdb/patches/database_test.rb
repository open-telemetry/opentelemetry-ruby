# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/lmdb'
require_relative '../../../../lib/opentelemetry/instrumentation/lmdb/patches/database'

describe OpenTelemetry::Instrumentation::LMDB::Patches::Database do
  let(:instrumentation) { OpenTelemetry::Instrumentation::LMDB::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }
  let(:config) { {} }
  let(:db_path) { File.join(File.dirname(__FILE__), '..', 'tmp', 'test') }
  let(:lmdb) { LMDB.new(db_path) }

  before do
    exporter.reset
    instrumentation.install(config)
    FileUtils.rm_rf(db_path)
    FileUtils.mkdir_p(db_path)
  end

  after do
    FileUtils.rm_rf(db_path)
    lmdb.close
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#clear' do
    it 'traces' do
      lmdb.database.clear
      _(span.name).must_equal('CLEAR')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system']).must_equal('lmdb')
      _(span.attributes['db.statement']).must_equal('CLEAR')
    end

    it 'omits db.statement attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database.clear

      _(span.kind).must_equal(:client)
      _(span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.statement')
    end
  end

  describe '#put' do
    it 'traces' do
      lmdb.database['foo'] = 'bar'
      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system']).must_equal('lmdb')
      _(span.attributes['db.statement']).must_equal('PUT foo bar')
    end

    it 'truncates long statements' do
      lmdb.database['foo'] = 'bar' * 200
      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system']).must_equal('lmdb')
      _(span.attributes['db.statement'].size).must_equal(500)
    end

    describe 'when peer_service config is set' do
      let(:config) { { peer_service: 'otel:lmdb' } }

      it 'adds peer.service attribute' do
        lmdb.database['foo'] = 'bar'
        _(span.name).must_equal('PUT foo')
        _(span.kind).must_equal(:client)
        _(span.attributes['db.system']).must_equal('lmdb')
        _(span.attributes['db.statement']).must_equal('PUT foo bar')
        _(span.attributes['peer.service']).must_equal('otel:lmdb')
      end
    end

    it 'omits db.statement attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.statement')
    end
  end

  describe '#get' do
    it 'traces' do
      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(last_span.name).must_equal('GET foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes['db.statement']).must_equal('GET foo')
    end

    it 'omits db.statement attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(last_span.name).must_equal('GET foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.statement')
    end
  end

  describe '#delete' do
    it 'traces' do
      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes['db.statement']).must_equal('DELETE foo')
    end

    it 'traces with value supplied' do
      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo', 'bar')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes['db.statement']).must_equal('DELETE foo bar')
    end

    it 'omits db.statement attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.statement')
    end
  end
end
