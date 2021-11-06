#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
end

# Example application for the Sinatra instrumentation
class App < Sinatra::Base
  set :bind, '0.0.0.0'
  set :show_exceptions, false

  template :example_render do
    'Example Render'
  end

  get '/example' do
    'Sinatra Instrumentation Example'
  end

  # Uses `render` method
  get '/example_render' do
    erb :example_render
  end

  get '/thing/:id' do
    'Thing 1'
  end

  run! if app_file == $PROGRAM_NAME
end
