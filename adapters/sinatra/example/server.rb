#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Sinatra'
end

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
