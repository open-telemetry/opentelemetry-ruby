# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'httpclient'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::HttpClient'
end

http = HTTPClient.new
http.receive_timeout = 1
http.get('http://example.com')
