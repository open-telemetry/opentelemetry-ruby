#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

require 'active_record'
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: ENV.fetch('TEST_POSTGRES_HOST', '127.0.0.1'),
  port: ENV.fetch('TEST_POSTGRES_PORT', '5432'),
  user: ENV.fetch('TEST_POSTGRES_USER', 'postgres'),
  database: ENV.fetch('TEST_POSTGRES_DB', 'postgres'),
  password: ENV.fetch('TEST_POSTGRES_PASSWORD', 'postgres')
)

require 'que'
Que.connection = ActiveRecord
Que.migrate!(version: 4)

# Job for testing
class TestJob < Que::Job
  def run
    puts 'Executing TestJob'
  end
end

ENV['OTEL_TRACES_EXPORTER'] = 'console'
require 'opentelemetry-instrumentation-que'
require 'opentelemetry/sdk'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Que'
end

puts 'Enqueing a new job'
TestJob.enqueue

# Start Que worker (based on bin/que)
locker = Que::Locker.new({})

# Process jobs for 5 seconds and then stop the worker
sleep 5
locker.stop!
