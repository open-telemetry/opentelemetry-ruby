# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Ethon'
end

Ethon::Easy.new(url: 'http://example.com').perform
