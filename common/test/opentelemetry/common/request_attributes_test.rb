# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::HTTP::RequestAttributes do
  subject { Class.new.extend(OpenTelemetry::Common::HTTP::RequestAttributes) }

  it 'returns http attributes matching the spec given input' do
    attributes = subject.from_request(method: 'GET', config: {}, uri: URI('http://example.com/foo?bar=baz'))
    _(attributes).must_equal(
      'http.method' => 'GET',
      'http.scheme' => 'http',
      'http.url' => 'http://example.com/foo?bar=baz',
      'http.target' => '/foo?bar=baz',
      'net.peer.name' => 'example.com',
      'net.peer.port' => 80
    )
  end

  it 'returns http attributes matching the spec given input' do
    attributes = subject.from_request(method: 'GET', config: {}, uri: URI('http://example.com/foo?bar=baz'))
    _(attributes).must_equal(
      'http.method' => 'GET',
      'http.scheme' => 'http',
      'http.url' => 'http://example.com/foo?bar=baz',
      'http.target' => '/foo?bar=baz',
      'net.peer.name' => 'example.com',
      'net.peer.port' => 80
    )
  end

  describe 'if hide_query_params config option provided' do
    it 'hides query params in attributes' do
      attributes = subject.from_request(method: 'GET', config: { hide_query_params: true }, uri: URI('http://example.com/foo?bar=baz'))
      _(attributes).must_equal(
        'http.method' => 'GET',
        'http.scheme' => 'http',
        'http.url' => 'http://example.com/foo?',
        'http.target' => '/foo?',
        'net.peer.name' => 'example.com',
        'net.peer.port' => 80
      )
    end

    it 'does not alter input uri' do
      uri = URI('http://example.com/foo?bar=baz')
      subject.from_request(method: 'GET', config: { hide_query_params: true }, uri: uri)
      _(uri.query).must_equal('bar=baz')
    end
  end
end
