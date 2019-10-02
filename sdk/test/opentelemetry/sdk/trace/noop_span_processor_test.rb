# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::NoopSpanProcessor do
  let(:processor) { OpenTelemetry::SDK::Trace::NoopSpanProcessor.instance }
  let(:span)      { nil }

  it 'implements #on_start' do
    processor.on_start(span)
  end

  it 'implements #on_finish' do
    processor.on_finish(span)
  end

  it 'implements #shutdown' do
    processor.shutdown
  end
end
