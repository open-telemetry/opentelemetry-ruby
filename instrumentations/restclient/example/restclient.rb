# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentations::RestClient'
end

RestClient.get('http://example.com')
