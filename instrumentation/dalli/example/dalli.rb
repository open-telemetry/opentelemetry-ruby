# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Dalli'
end

Dalli.new(ENV['MEMCACHED_HOST'], {}).set('mykey', 'hello world')
