# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Logs::LogsExporter do
  it 'waits for an in-flight export before completing shutdown' do
    exporter = OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
    log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
    entered_export = Queue.new
    release_export = Queue.new

    send_bytes = lambda do |_bytes, **_options|
      entered_export << true
      release_export.pop
      OpenTelemetry::SDK::Logs::Export::SUCCESS
    end

    exporter.stub(:send_bytes, send_bytes) do
      export_thread = Thread.new { exporter.export([log_record_data]) }
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
    end

    assert_equal OpenTelemetry::SDK::Logs::Export::FAILURE, exporter.export([log_record_data])
  end

  it 'returns TIMEOUT when shutdown exceeds its deadline and closes after export finishes' do
    exporter = OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
    log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
    entered_export = Queue.new
    release_export = Queue.new
    connection_closed = Queue.new

    send_bytes = lambda do |_bytes, **_options|
      entered_export << true
      release_export.pop
      OpenTelemetry::SDK::Logs::Export::SUCCESS
    end

    exporter.stub(:send_bytes, send_bytes) do
      exporter.stub(:finish_http_connection, -> { connection_closed << true }) do
        export_thread = Thread.new { exporter.export([log_record_data]) }
        entered_export.pop

        begin
          assert_equal OpenTelemetry::SDK::Logs::Export::TIMEOUT, exporter.shutdown(timeout: 0.01)
          assert_equal 0, connection_closed.size
        ensure
          release_export << true
        end

        assert_equal OpenTelemetry::SDK::Logs::Export::SUCCESS, export_thread.value
        assert_equal true, connection_closed.pop
        assert_equal OpenTelemetry::SDK::Logs::Export::FAILURE, exporter.export([log_record_data])
      end
    end
  end
end
