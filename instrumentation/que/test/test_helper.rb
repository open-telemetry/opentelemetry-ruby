# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'

require 'minitest/autorun'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

require 'que'

class TestJobSync < Que::Job
  self.run_synchronously = true
end

class TestJobAsync < Que::Job
end

class JobThatFails < Que::Job
  def run
    raise 'oh no'
  end
end

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

def prepare_que
  require 'active_record'
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    host: ENV.fetch('TEST_POSTGRES_HOST', '127.0.0.1'),
    port: ENV.fetch('TEST_POSTGRES_PORT', '5432'),
    user: ENV.fetch('TEST_POSTGRES_USER', 'postgres'),
    database: database_name,
    password: ENV.fetch('TEST_POSTGRES_PASSWORD', 'postgres')
  )

  Que.connection = ActiveRecord
  Que.migrate!(version: 4)

  # Make sure the que_jobs table is empty before running tests.
  ActiveRecord::Base.connection.execute('TRUNCATE que_jobs')
end

def database_name
  ENV.fetch('TEST_POSTGRES_DB', 'postgres')
end
