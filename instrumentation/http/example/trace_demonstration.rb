# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'opentelemetry-api', path: '../../../api'
  gem 'opentelemetry-instrumentation-base', path: '../../../instrumentation/base'
  gem 'opentelemetry-instrumentation-http', path: '../../../instrumentation/http'
  gem 'opentelemetry-sdk', path: '../../../sdk'
  gem 'http'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-http'
require 'http'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::HTTP'
end

# A basic HTTP example
HTTP.get('https://github.com')
