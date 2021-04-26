# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'koala'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  c.use 'OpenTelemetry::Instrumentation::Koala'
end

graph = Koala::Facebook::API.new('token')
graph.get_object('me')
