# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentations::Excon'
end

Excon.get('http://example.com')
