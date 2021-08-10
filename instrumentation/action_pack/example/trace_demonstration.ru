# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-action_pack'
end

require 'action_controller/railtie'

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# https://github.com/rails/rails/blob/v6.0.0/guides/bug_report_templates/action_controller_gem.rb
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  secrets.secret_key_base = 'secret_key_base'
  config.eager_load = false
  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger
end

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActionPack'
end

Rails.application.initialize!

run Rails.application

# To run this example run the `rackup` command with this file
# Example: rackup trace_request_demonstration.ru
# Navigate to http://localhost:9292/
# Spans for the requests will appear in the console
