# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry/common/http/request_attributes'

describe OpenTelemetry::Common::HTTP::RequestAttributes do
  subject { OpenTelemetry::Common::HTTP::RequestAttributes }

  it 'returns http attributes matching the spec given input' do
    attributes = subject.from_request('GET', URI('http://example.com/foo?bar=baz'))
    _(attributes).must_equal(
      'http.method' => 'GET',
      'http.scheme' => 'http',
      'http.url' => 'http://example.com/foo?bar=baz',
      'http.target' => '/foo?bar=baz',
      'peer.hostname' => 'example.com',
      'peer.port' => 80
    )
  end

  it 'returns http attributes matching the spec given input' do
    attributes = subject.from_request('GET', URI('http://example.com/foo?bar=baz'))
    _(attributes).must_equal(
      'http.method' => 'GET',
      'http.scheme' => 'http',
      'http.url' => 'http://example.com/foo?bar=baz',
      'http.target' => '/foo?bar=baz',
      'peer.hostname' => 'example.com',
      'peer.port' => 80
    )
  end

  describe 'if hide_query_params config option provided' do
    it 'hides query params in attributes' do
      attributes = subject.from_request('GET', URI('http://example.com/foo?bar=baz'), hide_query_params: true)
      _(attributes).must_equal(
        'http.method' => 'GET',
        'http.scheme' => 'http',
        'http.url' => 'http://example.com/foo?',
        'http.target' => '/foo?',
        'peer.hostname' => 'example.com',
        'peer.port' => 80
      )
    end

    it 'does not alter input uri' do
      uri = URI('http://example.com/foo?bar=baz')
      subject.from_request('GET', uri, hide_query_params: true)
      _(uri.query).must_equal('bar=baz')
    end
  end
end
