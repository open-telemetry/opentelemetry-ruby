# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'mysql2'

require_relative '../../../../lib/opentelemetry/adapters/mysql2'
require_relative '../../../../lib/opentelemetry/adapters/mysql2/patches/client'

# This test suite requires a running mysql container and dedicated test container
# To run tests:
# 1. Build the opentelemetry/opentelemetry-ruby image
# - docker-compose build
# 2. Bundle install
# - docker-compose run ex-adapter-mysql2-test bundle install
# 3. Run test suite
# - docker-compose run ex-adapter-mysql2-test bundle exec rake test
describe OpenTelemetry::Adapters::Mysql2::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Mysql2::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    adapter.instance_variable_set(:@installed, false)
  end

  describe 'tracing' do
    let(:client) do
      ::Mysql2::Client.new(
        host: host,
        port: port,
        database: database,
        username: 'root',
        password: password
      )
    end

    let(:host) { ENV.fetch('TEST_MYSQL_HOST') { '127.0.0.1' } }
    let(:port) { ENV.fetch('TEST_MYSQL_PORT') { '3306' } }
    let(:database) { ENV.fetch('TEST_MYSQL_DB') { 'mysql' } }
    let(:username) { ENV.fetch('TEST_MYSQL_USER') { 'root' } }
    let(:password) { ENV.fetch('TEST_MYSQL_PASSWORD') { 'root' } }

    before do
      adapter.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after requests' do
      client.query('SELECT 1')

      _(span.name).must_equal 'select'
      _(span.attributes['db.type']).must_equal 'mysql'
      _(span.attributes['db.instance']).must_equal 'mysql'
      _(span.attributes['db.statement']).must_equal 'SELECT 1'
      _(span.attributes['db.url']).must_equal "mysql://#{host}:#{port}"
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_s
    end

    it 'after error' do
      expect do
        client.query('SELECT INVALID')
      end.must_raise Mysql2::Error

      _(span.name).must_equal 'select'
      _(span.attributes['db.type']).must_equal 'mysql'
      _(span.attributes['db.instance']).must_equal 'mysql'
      _(span.attributes['db.statement']).must_equal 'SELECT INVALID'
      _(span.attributes['db.url']).must_equal "mysql://#{host}:#{port}"
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_s

      _(span.status.canonical_code).must_equal(
        OpenTelemetry::Trace::Status::UNKNOWN_ERROR
      )
      _(span.events.first.name).must_equal 'error'
      _(span.events.first.attributes['error.type']).must_equal 'Mysql2::Error'
      assert(!span.events.first.attributes['error.message'].nil?)
      assert(!span.events.first.attributes['error.stack'].nil?)
    end

    it 'extracts statement type that begins the query' do
      base_sql = 'SELECT 1'
      explain = 'EXPLAIN'
      explain_sql = "#{explain} #{base_sql}"
      client.query(explain_sql)

      _(span.name).must_equal 'explain'
      _(span.attributes['db.type']).must_equal 'mysql'
      _(span.attributes['db.instance']).must_equal 'mysql'
      _(span.attributes['db.statement']).must_equal explain_sql
      _(span.attributes['db.url']).must_equal "mysql://#{host}:#{port}"
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_s
    end

    it 'uses component.name and instance.name as span.name fallbacks with invalid sql' do
      expect do
        client.query('DESELECT 1')
      end.must_raise Mysql2::Error

      _(span.name).must_equal 'mysql.mysql'
      _(span.attributes['db.type']).must_equal 'mysql'
      _(span.attributes['db.instance']).must_equal 'mysql'
      _(span.attributes['db.statement']).must_equal 'DESELECT 1'
      _(span.attributes['db.url']).must_equal "mysql://#{host}:#{port}"
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_s

      _(span.status.canonical_code).must_equal(
        OpenTelemetry::Trace::Status::UNKNOWN_ERROR
      )
      _(span.events.first.name).must_equal 'error'
      _(span.events.first.attributes['error.type']).must_equal 'Mysql2::Error'
      assert(!span.events.first.attributes['error.message'].nil?)
      assert(!span.events.first.attributes['error.stack'].nil?)
    end
  end
end
