# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch'

describe OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation do
  let(:http_instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:instrumentation) { OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }
  let(:config) { {} }
  let(:es_client) { Elasticsearch::Client.new }

  # Before running these tests, start Elasticsearch by running
  # docker-compose up elasticsearch
  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentations
    http_instrumentation.instance_variable_set(:@installed, false)
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Elasticsearch'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  it 'creates new spans when create_es_spans is true' do
    instrumentation.install(create_es_spans: true)
    es_client.search(q: 'wat')
    _(
      exporter.finished_spans.count do |s|
        s.name.include?("Elasticsearch")
      end
    ).must_equal 2
  end

  it 'annotates HTTP spans when create_es_spans is false' do
    http_instrumentation.install
    instrumentation.install(create_es_spans: false)
    es_client.search(q: 'wat')
    _(
      exporter.finished_spans.count do |span|
        span.name.include?("HTTP") && span.attributes["db.system"] == "elasticsearch"
      end
    ).must_equal(2)
  end
end
