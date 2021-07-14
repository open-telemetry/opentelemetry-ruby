# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Ethon'
end

Ethon::Easy.new(url: 'http://example.com').perform
