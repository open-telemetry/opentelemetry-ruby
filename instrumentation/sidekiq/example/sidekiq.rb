# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sidekiq'
end

# A basic Sidekiq job worker example
class SimpleJob
  include Sidekiq::Worker

  def perform
    puts "Workin'"
  end
end

SimpleJob.perform_async
