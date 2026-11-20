# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'thread'

describe OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter do
  it 'waits for an in-flight export before completing shutdown' do
    exporter = OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter.new
    entered_export = Queue.new
    release_export = Queue.new
    log_record_data = Logs::LogRecordData.new

    blocked_records = Object.new
    blocked_records.define_singleton_method(:to_a) do
      entered_export << true
      release_export.pop
      [log_record_data]
    end

    export_thread = Thread.new { exporter.export(blocked_records) }
    entered_export.pop

    shutdown_started = Queue.new
    shutdown_thread = Thread.new do
      shutdown_started << true
      exporter.shutdown
    end
    shutdown_started.pop

    begin
      assert_nil shutdown_thread.join(0.05), 'shutdown should wait for the in-flight export'
    ensure
      release_export << true
    end

    assert_equal OpenTelemetry::SDK::Logs::Export::SUCCESS, export_thread.value
    assert_equal OpenTelemetry::SDK::Logs::Export::SUCCESS, shutdown_thread.value
    assert_equal OpenTelemetry::SDK::Logs::Export::FAILURE, exporter.export([])
  end
end
