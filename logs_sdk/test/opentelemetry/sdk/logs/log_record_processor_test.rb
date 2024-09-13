# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::LogRecordProcessor do
  let(:processor)  { OpenTelemetry::SDK::Logs::LogRecordProcessor.new }
  let(:log_record) { nil }
  let(:context)    { nil }

  it 'implements #on_emit' do
    processor.on_emit(log_record, context)
  end

  it 'implements #force_flush' do
    processor.force_flush
  end

  it 'returns a success code when #force_flush is called' do
    assert(OpenTelemetry::SDK::Logs::Export::SUCCESS, processor.force_flush)
  end

  it 'implements #shutdown' do
    processor.shutdown
  end

  it 'returns a success code when #shutdown is called' do
    assert(OpenTelemetry::SDK::Logs::Export::SUCCESS, processor.shutdown)
  end
end
