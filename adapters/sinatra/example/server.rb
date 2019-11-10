#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'sinatra/base'
require 'opentelemetry/sdk'
require_relative '../lib/opentelemetry/adapters/sinatra'

# Set preferred tracer implementation:
SDK = OpenTelemetry::SDK

factory = OpenTelemetry.tracer_factory = SDK::Trace::TracerFactory.new
factory.add_span_processor(
  SDK::Trace::Export::SimpleSpanProcessor.new(
    SDK::Trace::Export::ConsoleSpanExporter.new
  )
)

OpenTelemetry::Adapters::Sinatra.install(name: 'sinatra-example', version: '1.0')

class App < Sinatra::Base
  set :bind, '0.0.0.0'
  set :show_exceptions, false

  template :example_render do
    'Example Render'
  end

  get '/example' do
    'Sinatra Adapter Example'
  end

  # Uses `render` method
  get '/example_render' do
    erb :example_render
  end

  get '/thing/:id' do
    'Thing 1'
  end

  run! if app_file == $0
end
