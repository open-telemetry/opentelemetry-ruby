# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rails', path: '../../rails'
  gem 'opentelemetry-instrumentation-action_view', path: '../'
end

require 'active_support/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  secrets.secret_key_base = 'secret_key_base'

  config.eager_load = false

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get '/' => 'test#index'
  end
end

# A minimal test controller
class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index; end
end

# Simple setup for demonstration purposes, simple span processor should not be
# used in a production environment
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)

OpenTelemetry::SDK.configure do |c|
  # At present, the Rails instrumentation is required.
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::ActionView'
  c.add_span_processor(span_processor)
end

Rails.application.initialize!

run Rails.application

# To run this example run the `rackup` command with this file
# Example: rackup trace_request_demonstration.ru
# Navigate to http://localhost:9292/
# Spans for the requests will appear in the console
