# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
end

tracer = OpenTelemetry.tracer_provider.tracer('default')

tracer.in_span('outer_span') do
  future = Concurrent::Future.new do
    tracer.in_span('inner_span') {}
  end
  future.execute
  future.wait
end

tracer.in_span('outer_span') do
  future = Concurrent::Promises.future do
    tracer.in_span('inner_span') {}
  end
  future.result
end

# Worker: an example Async worker
class Worker
  include Concurrent::Async
  def initialize(tracer)
    @tracer = tracer
  end

  def action
    @tracer.in_span('async:inner_span') {}
  end
end

worker = Worker.new(tracer)

tracer.in_span('async:outer_span') do
  worker.await.action
  worker.async.action.wait
end
