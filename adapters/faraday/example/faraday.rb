require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Faraday'
end

# Demonstrate disabling span reporting:
#
# require_relative '../lib/opentelemetry/adapters/faraday/middlewares/tracer_middleware'
# class NoOp < OpenTelemetry::Adapters::Faraday::Middlewares::TracerMiddleware
#   def disable_span_reporting?(env)
#     env.url.to_s =~ /example.com/
#   end
# end
# OpenTelemetry::Adapters::Faraday.install(tracer_middleware: NoOp)

conn = Faraday.new('http://example.com')
conn.get '/'
