# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch'
require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/client'

describe OpenTelemetry::Instrumentation::Elasticsearch::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  let(:host) { ENV.fetch('TEST_ELASTICSEARCH_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_ELASTICSEARCH_PORT', '9200').to_i }
  let(:server) { "http://#{host}:#{port}" }
  let(:client) { Elasticsearch::Client.new(url: server) }
  let(:url) { "http://#{host}:#{port}/#{path}" }

  before do
    exporter.reset
    instrumentation.install
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'search query' do
    let(:path) { '_search?q=test' }
    it 'produces correct traces' do
      stub_request(:get, url).to_return(status: 200)

      client.search q: 'test'

      _(span.name).must_equal 'elasticsearch.query'
      _(span.attributes['http.host']).must_equal host
      _(span.attributes['net.peer.port']).must_equal port
      _(span.attributes[http.target']).must_equal '_search'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['elasticsearch.params']).must_equal '{"q":"test"}'
      _(span.attributes['elasticsearch.body']).must_equal ''
      _(span.attributes['http.status_code']).must_equal 200
    end
  end

  describe 'cluster health' do
    let(:path) { '_cluster/health' }
    it 'produces correct traces' do
      stub_request(:get, url).to_return(status: 200)

      client.cluster.health

      _(span.name).must_equal 'elasticsearch.query'
      _(span.attributes['out.host']).must_equal host
      _(span.attributes['out.port']).must_equal port
      _(span.attributes['elasticsearch.url']).must_equal path
      _(span.attributes['elasticsearch.method']).must_equal 'GET'
      _(span.attributes['elasticsearch.params']).must_equal '{}'
      _(span.attributes['elasticsearch.body']).must_equal ''
      _(span.attributes['http.status_code']).must_equal 200
    end
  end

  describe 'update query' do
    let(:path) { 'foo/bar/1/_update' }
    let(:body) { { key1: 'value1', key2: 'value2' } }
    it 'produces correct traces' do
      stub_request(:post, url).with(body: body).to_return(status: 201)

      client.update(index: 'foo', type: 'bar', id: '1', body: body)

      _(span.name).must_equal 'elasticsearch.query'
      _(span.attributes['out.host']).must_equal host
      _(span.attributes['out.port']).must_equal port
      _(span.attributes['elasticsearch.url']).must_equal path
      _(span.attributes['elasticsearch.method']).must_equal 'POST'
      _(span.attributes['elasticsearch.params']).must_equal '{}'
      _(span.attributes['elasticsearch.body']).must_equal '{"key1":"value1","key2":"value2"}'
      _(span.attributes['http.status_code']).must_equal 201
    end
  end
end
