# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'grpc'

require_relative './lib/integration_test_pb'
require_relative './lib/integration_test_services_pb'

require 'minitest/autorun'
require 'webmock/minitest'

require 'pry'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

class IntegrationServer < Integrationtest::IntegrationTest::Service
  def echo_one(message, _call)
    message
  end

  def echo_stream(message, _call)
    [message, message, message].each
  end

  def echo_many(call)
    last_message = nil
    call.each_remote_read do |message|
      last_message = message
    end

    last_message
  end

  def echo_chat(messages)
    messages
  end
end

def run_rpc_request(method, *args)
  rpc_server = ::GRPC::RpcServer.new
  rpc_server.add_http2_port('127.0.0.1:50051', :this_port_is_insecure)
  rpc_server.handle(IntegrationServer.new)
  rpc_server_thread = Thread.new { rpc_server.run_till_terminated }

  rpc_client = Integrationtest::IntegrationTest::Stub.new('127.0.0.1:50051', :this_channel_is_insecure)

  result = nil

  case method
  when :echo_one, :echo_many
    result = rpc_client.send(method, *args)
  when :echo_stream
    result = rpc_client.send(method, *args).to_a
  when :echo_chat
    result = []
    rpc_client.send(method, *args) { |r| result << r }
  end

  rpc_server.stop && rpc_server_thread.join

  result
end
