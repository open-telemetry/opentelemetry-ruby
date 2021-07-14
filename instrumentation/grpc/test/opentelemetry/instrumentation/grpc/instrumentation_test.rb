# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/grpc'

describe OpenTelemetry::Instrumentation::GRPC do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GRPC::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::GRPC'
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

  describe 'integration tests' do
    let(:exporter) { EXPORTER }
    let(:client_span) { exporter.finished_spans.find { |s| s.kind == :client } }
    let(:server_span) { exporter.finished_spans.find { |s| s.kind == :server } }

    let(:hello_world) { Integrationtest::Message.new(text: 'Hello, world!') }

    before do
      instrumentation.install({})
      exporter.reset
    end

    describe 'unary requests' do
      it 'creates spans with the expected attributes' do
        run_rpc_request(:echo_one, hello_world)

        # TODO: Can we actually get these to harmonize?
        _(client_span.name).must_equal('integrationtest.IntegrationTest/EchoOne')
        _(server_span.name).must_equal('integrationtest.IntegrationTest/echo_one')

        _(client_span.attributes['rpc.method']).must_equal('EchoOne')
        _(server_span.attributes['rpc.method']).must_equal('echo_one')

        [client_span, server_span].each do |span|
          _(span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
          _(span.attributes['rpc.system']).must_equal('grpc')
          _(span.attributes['rpc.service']).must_equal('integrationtest.IntegrationTest')

          # all events should have the name 'message'
          _(span.events.map(&:name).uniq).must_equal(['message'])
        end

        client_sequence = [['SENT', 1], ['RECEIVED', 1]]
        client_span.events.each_with_index do |event, idx|
          type, id = client_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end

        server_sequence = [['RECEIVED', 1], ['SENT', 1]]
        server_span.events.each_with_index do |event, idx|
          type, id = server_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end
      end
    end

    describe 'server streaming requests' do
      it 'creates spans with the expected attributes' do
        run_rpc_request(:echo_stream, hello_world)

        _(client_span.name).must_equal('integrationtest.IntegrationTest/EchoStream')
        _(server_span.name).must_equal('integrationtest.IntegrationTest/echo_stream')

        _(client_span.attributes['rpc.method']).must_equal('EchoStream')
        _(server_span.attributes['rpc.method']).must_equal('echo_stream')

        [client_span, server_span].each do |span|
          _(span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
          _(span.attributes['rpc.system']).must_equal('grpc')
          _(span.attributes['rpc.service']).must_equal('integrationtest.IntegrationTest')

          # all events should have the name 'message'
          _(span.events.map(&:name).uniq).must_equal(['message'])
        end

        client_sequence = [
          ['SENT', 1],
          ['RECEIVED', 1],
          ['RECEIVED', 2],
          ['RECEIVED', 3]
        ]
        client_span.events.each_with_index do |event, idx|
          type, id = client_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end

        server_sequence = [
          ['RECEIVED', 1],
          ['SENT', 1],
          ['SENT', 2],
          ['SENT', 3]
        ]
        server_span.events.each_with_index do |event, idx|
          type, id = server_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end
      end
    end

    describe 'client streaming requests' do
      it 'creates spans with the expected attributes' do
        run_rpc_request(:echo_many, [hello_world, hello_world, hello_world])

        _(client_span.name).must_equal('integrationtest.IntegrationTest/EchoMany')
        _(server_span.name).must_equal('integrationtest.IntegrationTest/echo_many')

        _(client_span.attributes['rpc.method']).must_equal('EchoMany')
        _(server_span.attributes['rpc.method']).must_equal('echo_many')

        [client_span, server_span].each do |span|
          _(span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
          _(span.attributes['rpc.system']).must_equal('grpc')
          _(span.attributes['rpc.service']).must_equal('integrationtest.IntegrationTest')

          # all events should have the name 'message'
          _(span.events.map(&:name).uniq).must_equal(['message'])
        end

        client_sequence = [
          ['SENT', 1],
          ['SENT', 2],
          ['SENT', 3],
          ['RECEIVED', 1]
        ]
        client_span.events.each_with_index do |event, idx|
          type, id = client_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end

        server_sequence = [
          ['RECEIVED', 1],
          ['RECEIVED', 2],
          ['RECEIVED', 3],
          ['SENT', 1]
        ]
        server_span.events.each_with_index do |event, idx|
          type, id = server_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end
      end
    end

    describe 'bidirectional streaming requests' do
      it 'creates spans with the expected attributes' do
        run_rpc_request(:echo_chat, [hello_world, hello_world, hello_world])

        _(client_span.name).must_equal('integrationtest.IntegrationTest/EchoChat')
        _(server_span.name).must_equal('integrationtest.IntegrationTest/echo_chat')

        _(client_span.attributes['rpc.method']).must_equal('EchoChat')
        _(server_span.attributes['rpc.method']).must_equal('echo_chat')

        [client_span, server_span].each do |span|
          _(span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
          _(span.attributes['rpc.system']).must_equal('grpc')
          _(span.attributes['rpc.service']).must_equal('integrationtest.IntegrationTest')

          # all events should have the name 'message'
          _(span.events.map(&:name).uniq).must_equal(['message'])
        end

        # This is due to the way we're handling client responses: we read them all off in a sequence immediately and so they
        # end up being ordered from the client's perspective.
        client_sequence = [
          ['SENT', 1],
          ['SENT', 2],
          ['SENT', 3],
          ['RECEIVED', 1],
          ['RECEIVED', 2],
          ['RECEIVED', 3]
        ]
        client_span.events.each_with_index do |event, idx|
          type, id = client_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end

        # However, on the server, we receive and send responses in the order you might otherwise expect.
        # I recognize this is a little janky, but the message/event handling does work as expected when you run the example
        # scripts for this instrumentation, so I think it's correct.
        server_sequence = [
          ['RECEIVED', 1],
          ['SENT', 1],
          ['RECEIVED', 2],
          ['SENT', 2],
          ['RECEIVED', 3],
          ['SENT', 3]
        ]
        server_span.events.each_with_index do |event, idx|
          type, id = server_sequence[idx]
          _(event.attributes['message.type']).must_equal(type)
          _(event.attributes['message.id']).must_equal(id)
        end
      end
    end
  end
end
