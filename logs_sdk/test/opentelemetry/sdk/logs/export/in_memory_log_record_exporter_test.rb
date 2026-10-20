# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter do
  export = OpenTelemetry::SDK::Logs::Export

  let(:log_record_data1) { OpenTelemetry::SDK::Logs::LogRecordData.new }
  let(:log_record_data2) { OpenTelemetry::SDK::Logs::LogRecordData.new }
  let(:exporter)         { export::InMemoryLogRecordExporter.new }

  it 'accepts an Array of LogRecordDatas as argument to #export' do
    exporter.export([log_record_data1, log_record_data2])

    emitted_log_records = exporter.emitted_log_records

    assert_equal(log_record_data1, emitted_log_records[0])
    assert_equal(log_record_data2, emitted_log_records[1])
  end

  it 'accepts an Enumerable of LogRecordDatas as argument to #export' do
    # An anonymous Struct serves as a handy implementor of Enumerable
    enumerable = Struct.new(:log_record_data1, :log_record_data2).new
    enumerable.log_record_data1 = log_record_data1
    enumerable.log_record_data2 = log_record_data2

    exporter.export(enumerable)

    emitted_log_records = exporter.emitted_log_records

    assert_equal(log_record_data1, emitted_log_records[0])
    assert_equal(log_record_data2, emitted_log_records[1])
  end

  it 'freezes the return of #emitted_log_records' do
    exporter.export([log_record_data1])

    assert_predicate(exporter.emitted_log_records, :frozen?)
  end

  it 'allows additional calls to #export after #emitted_log_records' do
    exporter.export([log_record_data1])
    emitted_log_records1 = exporter.emitted_log_records

    exporter.export([log_record_data2])
    emitted_log_records2 = exporter.emitted_log_records

    assert_equal(1, emitted_log_records1.length)
    assert_equal(2, emitted_log_records2.length)

    assert_equal(emitted_log_records2[0], emitted_log_records1[0])
  end

  it 'returns success from #export' do
    assert_equal(export::SUCCESS, exporter.export([log_record_data1]))
  end

  it 'returns success from #force_flush' do
    assert_equal(export::SUCCESS, exporter.force_flush)
  end

  it 'returns error from #export after #shutdown called' do
    exporter.export([log_record_data1])
    exporter.shutdown

    assert_equal(export::FAILURE, exporter.export([log_record_data2]))
  end

  it 'returns an empty array from #export after #shutdown called' do
    exporter.export([log_record_data1])
    exporter.shutdown

    assert_equal(0, exporter.emitted_log_records.length)
  end

  it 'records nothing if stopped' do
    exporter.instance_variable_set(:@stopped, true)
    exporter.export([log_record_data1])

    assert_equal(0, exporter.emitted_log_records.length)
  end

  it 'clears the emitted log records on #reset' do
    exporter.instance_variable_set(:@emitted_log_records, [log_record_data1])
    exporter.reset

    assert_empty(exporter.instance_variable_get(:@emitted_log_records))
  end
end
