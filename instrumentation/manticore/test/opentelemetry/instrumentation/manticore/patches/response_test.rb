# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../local_server'
require_relative '../../../../../lib/opentelemetry/instrumentation/manticore'
require_relative '../../../../../lib/opentelemetry/instrumentation/manticore/patches/response'

describe OpenTelemetry::Instrumentation::Manticore::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Manticore::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:local_server) { LocalServer }
  let(:client) {Manticore::Client.new}

  before do
    exporter.reset
    local_server.start_server
  end

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal(0)
    end

    describe 'when request is returned with success code' do
      it 'stores attributes correctly' do
        ::Manticore.get('http://localhost:31000/success').body
        _(exporter.finished_spans.size).must_equal(1)
        _(span.name).must_equal('HTTP GET')
        _(span.attributes['http.method']).must_equal('GET')
        _(span.attributes['http.scheme']).must_equal('http')
        _(span.attributes['http.target']).must_equal('/success')
        _(span.attributes['http.url']).must_equal('http://localhost')
        _(span.attributes['http.status_code']).must_equal(200)
        _(span.attributes['http.status_text']).must_equal("OK")
        _(span.attributes['net.peer.name']).must_equal('localhost')
        _(span.attributes['net.peer.port']).must_equal(31000)
      end
    end
    describe 'when request is returned with failure code' do
      it 'stores attributes correctly' do
        response = <<-HEREDOC
        HTTP/1.1 500 Internal Server Error

        default good response
        HEREDOC
        local_server.save_mock('GET', '/failure', response)
        ::Manticore.get('http://localhost:31000/failure').body
        _(exporter.finished_spans.size).must_equal(1)
        _(span.name).must_equal('HTTP GET')
        _(span.attributes['http.method']).must_equal('GET')
        _(span.attributes['http.status_code']).must_equal(500)
        _(span.attributes['http.url']).must_equal('http://localhost')
        _(span.attributes['http.target']).must_equal('/failure')
      end
    end

    describe 'when Manticore requests two requests in parallel' do
      it 'creates two spans' do
        client.parallel.get('http://localhost:31000/success')
        client.parallel.get('http://localhost:31000/success')
        client.execute!
        _(exporter.finished_spans.size).must_equal(2)
      end
    end

    it 'accepts record_request_headers_list from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({ "record_request_headers_list" => ['Connection'] })
      ::Manticore.get('http://localhost:31000/record_request_headers_list').body
      # Manticore default behavior is to keep connection alive via the header 'Connection'
      _(span.attributes['http.request.Connection']).wont_be_empty
    end

    it 'accepts record_response_headers_list from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({ "record_response_headers_list" => ['server'] })
      response = <<-HEREDOC
      HTTP/1.1 200 OK
      Server: RubyLocalServer


      default good response
      HEREDOC
      local_server.save_mock('GET', '/record_response_headers_list', response)
      ::Manticore.get('http://localhost:31000/record_response_headers_list').body
      _(span.attributes['http.response.server']).must_equal('RubyLocalServer')
    end

    describe 'when manticore raises ManticoreException' do
      it 'sets failure span attributes' do
        allow(client.client).to receive(:execute).and_raise(Manticore::ManticoreException)
        client.get('http://localhost:31000/raise_exception').code
        _(span.attributes['http.exception']).must_equal('Manticore::ManticoreException')
        _(span.attributes['http.status_code']).must_equal(500)
        _(span.attributes['http.status_text']).must_equal('Internal Server Error')
        _(span.attributes['http.target']).must_equal('/raise_exception')
      end
    end
  end
end
