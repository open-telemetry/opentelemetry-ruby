# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

sdk_meter     = build_sdk_meter
sdk_counter   = sdk_meter.create_counter('bench.sdk.counter')
sdk_histogram = sdk_meter.create_histogram('bench.sdk.histogram')
sdk_gauge     = sdk_meter.create_gauge('bench.sdk.gauge')
sdk_updown    = sdk_meter.create_up_down_counter('bench.sdk.updown')

Benchmark.ips do |x|
  x.report('SDK counter#add')                 { sdk_counter.add(1) }
  x.report('SDK histogram#record')            { sdk_histogram.record(1) }
  x.report('SDK gauge#record')                { sdk_gauge.record(1) }
  x.report('SDK up_down_counter#add')         { sdk_updown.add(1) }
  x.compare!
end
