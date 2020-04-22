#!/usr/bin/env ruby

api_dir = File.expand_path('./api', __dir__)
$LOAD_PATH.unshift(api_dir) unless $LOAD_PATH.include?(api_dir)
lib_dir = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)


require 'rubygems'
require 'bundler/setup'
require 'grpc'
require 'opentelemetry/sdk'

require 'hello_service_services_pb'
require 'grpctrace'

# configure SDK with defaults
OpenTelemetry::SDK.configure

def call_say_hello(conn)
  metadata = {
    'timestamp' => Time.now.to_i.to_s,
    'client-id' => 'web-api-client-us-east-1',
    'user-id' => 'some-test-user-id'
  }
  response = conn.say_hello(
    Api::HelloRequest.new(greeting: 'world'),
    metadata: metadata
  )
  puts "Response from server: #{response.reply}"
end

def main
  tracer = OpenTelemetry.tracer_provider.tracer('grpc', 'semver:1.0')

  conn = Api::HelloService::Stub.new(
    'localhost:7777',
    :this_channel_is_insecure,
    interceptors: [GRPCTrace::UnaryClientInterceptor.new(tracer)]
  )

  call_say_hello(conn)
end

main
