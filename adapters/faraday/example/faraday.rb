require 'rubygems'
require 'bundler/setup'

require 'faraday'
require 'opentelemetry/sdk'
require_relative '../lib/opentelemetry/adapters/faraday'

# Set preferred tracer implementation:
SDK = OpenTelemetry::SDK

factory = OpenTelemetry.tracer_factory = SDK::Trace::TracerFactory.new
factory.add_span_processor(
  SDK::Trace::Export::SimpleSpanProcessor.new(
    SDK::Trace::Export::ConsoleSpanExporter.new
  )
)

OpenTelemetry::Adapters::Faraday.install(name: 'faraday-example', version: '1.0')

conn = Faraday.new('http://example.com')
conn.get '/'
