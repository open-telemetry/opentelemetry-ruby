# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Internal do
  class OneOffExporter
    def export(spans, timeout: nil); end

    def force_flush(timeout: nil); end

    def shutdown(timeout: nil); end
  end

  describe '#valid_exporter?' do
    it 'is true for a NoopSpanExporter' do
      exporter = OpenTelemetry::SDK::Trace::Export::NoopSpanExporter.new
      _(OpenTelemetry::SDK::Internal.valid_exporter?(exporter)).must_equal true
    end

    it 'is defines exporters via their method signatures' do
      exporter = OneOffExporter.new
      _(OpenTelemetry::SDK::Internal.valid_exporter?(exporter)).must_equal true
    end

    it 'is false for other objects' do
      _(OpenTelemetry::SDK::Internal.valid_exporter?({})).must_equal false
    end
  end
end
