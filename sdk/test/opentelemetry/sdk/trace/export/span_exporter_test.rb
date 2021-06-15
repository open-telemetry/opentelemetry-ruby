# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::SpanExporter do
  export = OpenTelemetry::SDK::Trace::Export

  let(:span_data1) { OpenTelemetry::SDK::Trace::SpanData.new(name: 'name1') }
  let(:span_data2) { OpenTelemetry::SDK::Trace::SpanData.new(name: 'name2') }
  let(:spans)      { [span_data1, span_data2] }
  let(:exporter)   { export::SpanExporter.new }

  it 'accepts an Array of SpanData as arg to #export and succeeds' do
    _(exporter.export(spans)).must_equal export::SUCCESS
  end

  it 'accepts an Enumerable of SpanData as arg to #export and succeeds' do
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
