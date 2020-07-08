# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sidekiq'
end

class SimpleJob
  include Sidekiq::Worker

  def perform
    puts "Workin'"
  end
end

SimpleJob.perform_async
