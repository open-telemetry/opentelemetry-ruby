# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../test_helper'

describe OpenTelemetry::SDK do
  describe '#metric_exporter' do
    export = OpenTelemetry::SDK::Metrics::Export
    let(:exporter) { export::MetricExporter.new }

    it 'verify basic exporter function' do
      _(exporter.export(nil)).must_equal export::SUCCESS
      _(exporter.shutdown).must_equal export::SUCCESS
      _(exporter.force_flush).must_equal export::SUCCESS
      _(exporter.collect).must_equal []
    end
  end
end
