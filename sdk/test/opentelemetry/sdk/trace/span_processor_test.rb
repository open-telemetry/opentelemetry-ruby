# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::SpanProcessor do
  let(:processor) { OpenTelemetry::SDK::Trace::SpanProcessor.new }
  let(:span)      { nil }
  let(:context)   { nil }

  it 'implements #on_start' do
    processor.on_start(span, context)
  end

  it 'implements #on_finishing' do
    processor.on_finishing(span)
  end

  it 'implements #on_finish' do
    processor.on_finish(span)
  end

  it 'implements #force_flush' do
    processor.force_flush
  end

  it 'implements #shutdown' do
    processor.shutdown
  end
end
