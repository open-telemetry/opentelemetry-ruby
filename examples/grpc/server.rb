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

class HelloServiceServer < Api::HelloService::Service
  def say_hello(hello_req, _unused_call)
    Api::HelloResponse.new(reply: "Hello #{hello_req.greeting}")
  end
end

def main
  tracer = OpenTelemetry.tracer_provider.tracer('grpc', 'semver:1.0')

  s = GRPC::RpcServer.new(
    interceptors: [GRPCTrace::UnaryServerInterceptor.new(tracer)]
  )

  s.add_http2_port(':7777', :this_port_is_insecure)
  s.handle(HelloServiceServer)
  # Runs the server with SIGHUP, SIGINT and SIGQUIT signal handlers to
  #   gracefully shutdown.
  # User could also choose to run server via call to run_till_terminated
  s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT'])
end

main
