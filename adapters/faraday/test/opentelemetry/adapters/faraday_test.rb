# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/adapters/faraday/adapter'

describe OpenTelemetry::Adapters::Faraday do
  let(:adapter) { OpenTelemetry::Adapters::Faraday::Adapter.instance }
  let(:exporter) { EXPORTER }

  before do
    adapter.install
    exporter.reset
  end

  describe 'tracing' do
    before do
      stub_request(:any, 'example.com')
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      ::Faraday.new('http://example.com').get('/')

      _(exporter.finished_spans.size).must_equal 1
    end
  end
end
