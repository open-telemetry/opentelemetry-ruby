# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::NoopSpanExporter do
  export = OpenTelemetry::SDK::Trace::Export

  let(:spans)    { [OpenTelemetry::Trace::Span.new, OpenTelemetry::Trace::Span.new] }
  let(:exporter) { export::NoopSpanExporter.new }

  it 'accepts an Array of Spans as arg to #export and succeeds' do
    _(exporter.export(spans)).must_equal export::SUCCESS
  end

  it 'accepts an Enumerable of Spans as arg to #export and succeeds' do
    enumerable = Struct.new(:span0, :span1).new(spans[0], spans[1])

    _(exporter.export(enumerable)).must_equal export::SUCCESS
  end

  it 'accepts calls to #shutdown' do
    exporter.shutdown
  end

  it 'fails to export after shutdown' do
    exporter.shutdown
    _(exporter.export(spans)).must_equal export::FAILURE
  end
end
