# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'active_support/core_ext/kernel/reporting'
require 'delayed_job'
require 'delayed_job_active_record'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

module TestHelper
  extend self

  def setup_active_record
    ::ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ::ActiveRecord::Schema.define do
      create_table 'delayed_jobs', force: :cascade do |t|
        t.integer 'priority', default: 0, null: false
        t.integer 'attempts', default: 0, null: false
        t.text 'handler', null: false
        t.text 'last_error'
        t.datetime 'run_at'
        t.datetime 'locked_at'
        t.datetime 'failed_at'
        t.string 'locked_by'
        t.string 'queue'
        t.datetime 'created_at'
        t.datetime 'updated_at'
      end
    end
  end

  def teardown_active_record
    ::ActiveRecord::Base.connection.close
  end
end
