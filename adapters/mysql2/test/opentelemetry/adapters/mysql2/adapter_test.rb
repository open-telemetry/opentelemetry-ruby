# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'mysql2'

require_relative '../../../../lib/opentelemetry/adapters/mysql2'
require_relative '../../../../lib/opentelemetry/adapters/mysql2/patches/client'

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
      result = client.query('SELECT 1')

      _(span.name).must_equal 'mysql.mysql'
      _(span.attributes['db.type']).must_equal 'mysql'
      _(span.attributes['db.instance']).must_equal 'mysql'
      _(span.attributes['db.statement']).must_equal 'SELECT 1'
      _(span.attributes['db.url']).must_equal 'mysql://mysql:3306'
      _(span.attributes['net.peer.name']).must_equal 'mysql'
      _(span.attributes['net.peer.port']).must_equal '3306'
    end

    # it 'after error' do
    # end
  end
end
