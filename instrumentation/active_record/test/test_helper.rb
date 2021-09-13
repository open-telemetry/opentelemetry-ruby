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
  adapter: 'sqlite3',
  database: 'db/development.sqlite3'
)

# Create User model
class User < ActiveRecord::Base
  validate :name_if_present

  scope :recently_created, -> { where('created_at > ?', Time.now - 3600) }

  def name_if_present
    errors.add(:base, 'must be otel') if name.present? && name != 'otel'
  end
end

class SuperUser < ActiveRecord::Base; end

# Get the current version so we can create a test table
segments = Gem.loaded_specs['activerecord'].version.segments
migration_version = "#{segments[0]}.#{segments[1]}".to_f

# Simple migration to create a table to test against
class CreateUserTable < ActiveRecord::Migration[migration_version]
  def change
    create_table :users do |t|
      t.string 'name'
      t.integer 'counter'
      t.timestamps
    end

    create_table :super_users do |t|
      t.string 'name'
      t.integer 'counter'
      t.timestamps
    end
  end
end

begin
  CreateUserTable.migrate(:up)
rescue ActiveRecord::StatementInvalid => e
  raise e unless e.message == "Mysql2::Error: Table 'users' already exists"
end

Minitest.after_run { CreateUserTable.migrate(:down) }
