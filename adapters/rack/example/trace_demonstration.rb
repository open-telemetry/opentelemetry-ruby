require 'rubygems'
require 'bundler/setup'

require 'opentelemetry/sdk'

require 'rack'
require_relative '../lib/opentelemetry/adapters/rack'

# Set preferred tracer implementation:
SDK = OpenTelemetry::SDK

# global initialization:
factory = OpenTelemetry.tracer_factory = SDK::Trace::TracerFactory.new
factory.add_span_processor(
  SDK::Trace::Export::SimpleSpanProcessor.new(
    SDK::Trace::Export::ConsoleSpanExporter.new
  )
)

# setup fake rack application:
builder = Rack::Builder.new do
  # can't use TracerMiddleware constant before calling Adapters::Rack.install:
  #use OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware
end
app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['All responses are OK']] }
builder.run app

# demonstrate rack configuration options:
config = {}
config[:retain_middleware_names] = true
config[:application] = builder
config[:record_frontend_span] = true
OpenTelemetry::Adapters::Rack::Adapter.instance.install(config)

# integrate/activate tracing middleware:
builder.use OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware

puts Rack::MockRequest.new(builder).get('/')
