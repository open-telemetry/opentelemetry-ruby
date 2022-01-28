# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/trilogy'
require_relative '../../../../lib/opentelemetry/instrumentation/trilogy/patches/client'

describe OpenTelemetry::Instrumentation::Trilogy do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:config) { {} }
  let(:driver_options) do
    {
      host: host,
      port: port,
      username: username,
      password: password,
      ssl: false
    }
  end
  let(:client) do
    ::Trilogy.new(driver_options)
  end

  let(:host) { ENV.fetch('TEST_MYSQL_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_MYSQL_PORT', '3306').to_i }
  let(:database) { ENV.fetch('TEST_MYSQL_DB', 'mysql') }
  let(:username) { ENV.fetch('TEST_MYSQL_USER', 'root') }
  let(:password) { ENV.fetch('TEST_MYSQL_PASSWORD', 'root') }

  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Trilogy'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:mysql')
      client.query('SELECT 1')

      _(span.attributes[::OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE]).must_equal 'readonly:mysql'
    end

    it 'omits peer service by default' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({})
      client.query('SELECT 1')

      _(span.attributes.keys).wont_include(::OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE)
    end
  end

  describe '#compatible?' do
    describe 'when an unsupported version is installed' do
      it 'is incompatible' do
        stub_const('Trilogy::VERSION', '2.0.0.beta') do
          _(instrumentation.compatible?).must_equal false
        end

        stub_const('Trilogy::VERSION', '3.0.0') do
          _(instrumentation.compatible?).must_equal false
        end
      end
    end

    describe 'when supported version is installed' do
      it 'is compatible' do
        stub_const('Trilogy::VERSION', '2.0.0') do
          _(instrumentation.compatible?).must_equal true
        end

        stub_const('Trilogy::VERSION', '3.0.0.rc1') do
          _(instrumentation.compatible?).must_equal true
        end
      end
    end
  end

  describe 'tracing' do
    before do
      instrumentation.install(config)
    end

    describe 'with default options' do
      it 'obfuscates sql' do
        client.query('SELECT 1')

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_be_nil
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
      end

      it 'extracts statement type' do
        explain_sql = 'EXPLAIN SELECT 1'
        client.query(explain_sql)

        _(span.name).must_equal 'explain'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'EXPLAIN SELECT ?'
      end

      it 'uses component.name and instance.name as span.name fallbacks with invalid sql' do
        expect do
          client.query('DESELECT 1')
        end.must_raise Trilogy::DatabaseError

        _(span.name).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'DESELECT ?'
      end
    end

    describe 'when quering for the connected host' do
      it 'spans will include the net.peer.name attribute' do
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'select @@hostname'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)

        client.query('SELECT 1')

        last_span = exporter.finished_spans.last

        _(last_span.name).must_equal 'select'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).wont_equal(host)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal client.connected_host
      end
    end

    describe 'when quering using unix domain socket' do
      let(:client) do
        ::Trilogy.new(
          username: username,
          password: password,
          ssl: false
        )
      end

      it 'spans will include the net.peer.name attribute' do
        skip 'requires setup of a mysql host using uds connections'
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'select @@hostname'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_match(/sock/)

        client.query('SELECT 1')

        last_span = exporter.finished_spans.last

        _(last_span.name).must_equal 'select'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).wont_equal(/sock/)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal client.connected_host
      end
    end

    describe 'when queries fail' do
      it 'sets span status to error' do
        expect do
          client.query('SELECT INVALID')
        end.must_raise Trilogy::DatabaseError

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_be_nil
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT INVALID'

        _(span.status.code).must_equal(
          OpenTelemetry::Trace::Status::ERROR
        )
        _(span.events.first.name).must_equal 'exception'
        _(span.events.first.attributes['exception.type']).must_equal 'Trilogy::DatabaseError'
        _(span.events.first.attributes['exception.message']).wont_be_nil
        _(span.events.first.attributes['exception.stacktrace']).wont_be_nil
      end
    end

    describe 'when db_statement is set to include' do
      let(:config) { { db_statement: :include } }

      it 'includes the db query statement' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal sql
      end
    end

    describe 'when db_statement is set to obfuscate' do
      let(:config) { { db_statement: :obfuscate } }

      it 'obfuscates SQL parameters in db.statement' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal obfuscated_sql
      end
    end

    describe 'when db_statement is set to omit' do
      let(:config) { { db_statement: :omit } }

      it 'does not include SQL statement as db.statement attribute' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_be_nil
      end
    end
  end
end
