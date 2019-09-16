# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::NoopSpanProcessor do
  let(:subject) { OpenTelemetry::SDK::Trace::NoopSpanProcessor.instance }
  let(:span)    { nil }

  it 'implements #on_start' do
    subject.on_start(span)
  end

  it 'implements #on_end' do
    subject.on_end(span)
  end

  it 'implements #shutdown' do
    subject.shutdown
  end
end
