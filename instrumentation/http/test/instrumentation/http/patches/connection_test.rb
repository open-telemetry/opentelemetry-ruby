# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/http'
require_relative '../../../../lib/opentelemetry/instrumentation/http/patches/connection'

describe OpenTelemetry::Instrumentation::HTTP::Patches::Connection do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }
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

        assert_raises(::HTTP::TimeoutError) do
          ::HTTP.timeout(connect: 0.1, write: 0.1, read: 0.1).get("http://localhost:#{port}/example")
        end
      end

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'HTTP CONNECT'
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).wont_be_nil
    ensure
      WebMock.disable_net_connect!
    end
  end
end
