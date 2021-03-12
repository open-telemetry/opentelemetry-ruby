# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'active_record'
require 'opentelemetry-instrumentation-active_record'
require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'webmock/minitest'
require 'pry'

# Global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
  c.add_span_processor span_processor
end

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  host: ENV.fetch('TEST_MYSQL_HOST') { '127.0.0.1' },
  username: ENV.fetch('TEST_MYSQL_USER') { 'root' },
  password: ENV.fetch('TEST_MYSQL_PASSWORD') { 'root' },
  database: ENV.fetch('TEST_MYSQL_DB') { 'mysql' }
)

# Create User model
class User < ActiveRecord::Base; end

# Get the current version so we can create a test table
segments = Gem.loaded_specs['activerecord'].version.segments
migration_version = "#{segments[0]}.#{segments[1]}".to_f

# Simple migration to create a table to test against
class CreateUserTable < ActiveRecord::Migration[migration_version]
  def change
    create_table :users, &:timestamps
  end
end

begin
  CreateUserTable.migrate(:up)
rescue ActiveRecord::StatementInvalid => e
  raise e unless e.message == "Mysql2::Error: Table 'users' already exists"
end

Minitest.after_run { CreateUserTable.migrate(:down) }
