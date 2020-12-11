# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/faraday/instrumentation'

describe OpenTelemetry::Instrumentation::Faraday do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    instrumentation.install
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
