# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end

port = ENV['TEST_REDIS_PORT'] || '16379'
password = ENV['REDIS_PASSWORD'] || 'passw0rd'
redis = Redis.new(port: port, password: password)
redis.set('mykey', 'hello world')
