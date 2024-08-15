# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::Export::LogRecordExporter do
  export = OpenTelemetry::SDK::Logs::Export

  let(:log_record_data1) { OpenTelemetry::SDK::Logs::LogRecordData.new({ name: 'name1' }) }
  let(:log_record_data2) { OpenTelemetry::SDK::Logs::LogRecordData.new({ name: 'name2' }) }
  let(:log_records)      { [log_record_data1, log_record_data2] }
  let(:exporter)         { export::LogRecordExporter.new }

  it 'accepts an Array of LogRecordData as arg to #export and succeeds' do
    _(exporter.export(log_records)).must_equal export::SUCCESS
  end

  it 'accepts an Enumerable of LogRecordData as arg to #export and succeeds' do
    enumerable = Struct.new(:log_record0, :log_record1).new(log_records[0], log_records[1])

    _(exporter.export(enumerable)).must_equal export::SUCCESS
  end

  it 'accepts calls to #shutdown' do
    exporter.shutdown
  end

  it 'fails to export after shutdown' do
    exporter.shutdown
    _(exporter.export(log_records)).must_equal export::FAILURE
  end

  it 'returns SUCCESS when #force_flush is called' do
    assert(export::SUCCESS, exporter.force_flush)
  end
end
