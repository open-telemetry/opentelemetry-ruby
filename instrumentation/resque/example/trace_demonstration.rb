# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'opentelemetry-api'
  gem 'opentelemetry-instrumentation-base'
  gem 'opentelemetry-instrumentation-resque'
  gem 'opentelemetry-sdk'
  gem 'resque'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-resque'
require 'resque'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Resque'
end

# A basic Sidekiq job worker example
class SimpleJob
  @queue = :demo

  def self.perform(*args)
    puts "Workin'"
  end
end

Resque.enqueue(SimpleJob)

Resque.reserve(:demo).perform
