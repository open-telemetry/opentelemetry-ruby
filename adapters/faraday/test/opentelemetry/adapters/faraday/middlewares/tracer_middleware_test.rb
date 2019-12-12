# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Adapter so .install method is found:
require_relative '../../../../../lib/opentelemetry/adapters/faraday'
require_relative '../../../../../lib/opentelemetry/adapters/faraday/middlewares/tracer_middleware'

describe OpenTelemetry::Adapters::Faraday::Middlewares::TracerMiddleware do
  let(:adapter) { OpenTelemetry::Adapters::Faraday }
  let(:exporter) { EXPORTER }

  let(:client) do
    ::Faraday.new('http://example.com') do |builder|
      builder.adapter(:test) do |stub|
        stub.get('/success') { |_| [200, {}, 'OK'] }
        stub.get('/failure') { |_| [500, {}, 'OK'] }
        stub.get('/not_found') { |_| [404, {}, 'OK'] }
      end
    end
  end

  before do
    adapter.install
    exporter.reset
  end

  describe 'first span' do
    let(:span) { exporter.finished_spans.first }

    it 'has http 200 attributes' do
      client.get('/success')

      _(span.attributes['component']).must_equal 'http'
      _(span.attributes['http.method']).must_equal :get
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
    end

    it 'has http.status_code 404' do
      client.get('/not_found')

      _(span.attributes['component']).must_equal 'http'
      _(span.attributes['http.method']).must_equal :get
      _(span.attributes['http.status_code']).must_equal 404
      _(span.attributes['http.url']).must_equal 'http://example.com/not_found'
    end

    it 'has http.status_code 500' do
      client.get('/failure')

      _(span.attributes['component']).must_equal 'http'
      _(span.attributes['http.method']).must_equal :get
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
    end
  end
end
