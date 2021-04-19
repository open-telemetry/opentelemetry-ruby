# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end

Redis.new.set('mykey', 'hello world')
