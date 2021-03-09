# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/http_client'
require_relative '../../../../lib/opentelemetry/instrumentation/http_client/patches/session'

describe OpenTelemetry::Instrumentation::HttpClient::Patches::Session do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HttpClient::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    instrumentation.install({})
  end

  # Force re-install of instrumentation
  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#connect' do
    it 'emits span on connect' do
      WebMock.allow_net_connect!
      TCPServer.open('localhost', 0) do |server|
        Thread.start { server.accept }
        port = server.addr[1]

        assert_raises(HTTPClient::ReceiveTimeoutError) do
          http = HTTPClient.new
          http.receive_timeout = 0.01
          http.get("http://username:password@localhost:#{port}/example")
        end
      end

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'HTTP CONNECT'
      _(span.attributes['http.url']).must_match(%r{http://localhost:})
    ensure
      WebMock.disable_net_connect!
    end
  end
end
