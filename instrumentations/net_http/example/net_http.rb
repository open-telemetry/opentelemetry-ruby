# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'net/http'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentations::Net::HTTP'
end

Net::HTTP.get(URI('http://example.com'))
