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
  let(:unmodified_client) { @unmodified_client }
  let(:client) { Elasticsearch::Client.new(url: server) }

  before do
    exporter.reset
    @unmodified_client = ::Elasticsearch::Transport.dup
  end

  after do
    ::Elasticsearch.send(:remove_const, :Transport)
    ::Elasticsearch.const_set('Transport', unmodified_client)
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'traces produce and consuming' do
    stub_request(:get, 'http://127.0.0.1:9200/_search?q=test').to_return(status: 200)

    client.search q: 'test'

    _(span.name).must_equal 'elasticsearch.query'
    _(span.attributes['out.host']).must_equal host
    _(span.attributes['out.port']).must_equal port
    _(span.attributes['elasticsearch.url']).must_equal '_search'
    _(span.attributes['elasticsearch.method']).must_equal 'GET'
    _(span.attributes['elasticsearch.params']).must_equal '{"q":"test"}'
    _(span.attributes['elasticsearch.body']).must_equal nil
    _(span.attributes['http.status_code']).must_equal 200
  end
end
