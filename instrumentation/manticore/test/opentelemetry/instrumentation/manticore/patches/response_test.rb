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
  let(:client) { Manticore::Client.new }

  before do
    exporter.reset
    local_server.start_server
  end

  describe 'tracing' do
    before do
      exporter.reset
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

    describe 'when Manticore makes a two parallel requests' do
      it 'creates two spans for each requests' do
        response = <<-HEREDOC
HTTP/1.1 200 OK
Server: RubyLocalServer


{"message":"parallel requests"}
        HEREDOC
        local_server.save_mock('GET', '/parallel', response)
        f1 = client.parallel.get('http://localhost:31000/parallel')
        f2 = client.parallel.get('http://localhost:31000/parallel')
        [f1, f2].each do |f|
          f.on_complete do |e|
            spans = exporter.finished_spans.select { |e| e.attributes['http.target'] == '/parallel' }
            _(exporter.finished_spans.size).must_equal(2)
          end
        end
      end
    end
    describe 'when Manticore makes a two batch requests' do
      it 'creates two span for each requests' do
        response = <<-HEREDOC
HTTP/1.1 200 OK
Server: RubyLocalServer


{"message":"batch requests"}
        HEREDOC
        local_server.save_mock('GET', '/batch', response)
        f1 = client.batch.get('http://localhost:31000/batch')
        f2 = client.batch.get('http://localhost:31000/batch')
        [f1, f2].each do |f|
          f.on_complete do |e|
            spans = exporter.finished_spans.select { |e| e.attributes['http.target'] == '/batch' }
            _(exporter.finished_spans.size).must_equal(2)
          end
        end
      end
    end
    describe 'when Manticore makes two future requests' do
      it 'creates at least two spans for each requests' do
        response = <<-HEREDOC
HTTP/1.1 200 OK
Server: RubyLocalServer


{"message":"future requests"}
        HEREDOC
        local_server.save_mock('GET', '/futures', response)
        f1 = client.background.get('http://localhost:31000/futures')
        f2 = client.background.get('http://localhost:31000/futures')
        [f1, f2].each do |f|
          f.on_complete do |e|
            spans = exporter.finished_spans.select { |e| e.attributes['http.target'] == '/futures' }
            _(exporter.finished_spans.size).must_equal(2)
          end
        end
      end
    end

    it 'accepts allowed_request_headers from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({ "allowed_request_headers" => ['Connection'] })
      ::Manticore.get('http://localhost:31000/allowed_request_headers').body
      # Manticore default behavior is to keep connection alive via the header 'Connection'
      _(span.attributes['http.request.header.Connection']).wont_be_empty
    end

    it 'accepts allowed_response_headers from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({ "allowed_response_headers" => ['server'] })
      response = <<-HEREDOC
HTTP/1.1 200 OK
Server: RubyLocalServer


default good response
      HEREDOC
      local_server.save_mock('GET', '/allowed_response_headers', response)
      ::Manticore.get('http://localhost:31000/allowed_response_headers').body
      _(span.attributes['http.response.header.server']).must_equal('RubyLocalServer')
    end

    describe 'when manticore raises ManticoreException' do
      it 'sets failure span attributes' do
        allow(client.client).to receive(:execute).and_raise(Manticore::ManticoreException)
        client.get('http://localhost:31000/raise_exception').code
        span_exception = span.events.first.attributes
        _(span_exception['exception.type']).must_equal('Manticore::ManticoreException')
        _(span_exception['exception.stacktrace']).wont_be_nil
      end
    end
  end
end
