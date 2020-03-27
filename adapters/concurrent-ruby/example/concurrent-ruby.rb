# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::ConcurrentRuby'
end

tracer = OpenTelemetry.tracer_provider.tracer('default')

tracer.in_span('outer_span') do
  future = Concurrent::Future.new do
    tracer.in_span('inner_span') {}
  end
  future.execute
  future.wait
end
