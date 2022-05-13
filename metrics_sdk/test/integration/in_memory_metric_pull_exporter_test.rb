# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    before { reset_metrics_sdk }

    it 'emits metrics' do
      meter = OpenTelemetry.meter_provider.meter('test')
      instrument = meter.create_counter('b_counter')

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      instrument.add(1)
      instrument.add(2, attributes: { 'a' => 'b' })
      instrument.add(3, attributes: { 'b' => 'c' })
      instrument.add(4, attributes: { 'd' => 'e' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots.last[0]
      _(last_snapshot.instrument.name).must_equal('b_counter')
      _(last_snapshot.instrument.instrumentation_library.name).must_equal('test')
    end
  end
end
