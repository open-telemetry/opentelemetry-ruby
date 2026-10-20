# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

noop_meter     = OpenTelemetry::Metrics::Meter.new
noop_counter   = noop_meter.create_counter('bench.noop.counter')
noop_histogram = noop_meter.create_histogram('bench.noop.histogram')
noop_gauge     = noop_meter.create_gauge('bench.noop.gauge')
noop_updown    = noop_meter.create_up_down_counter('bench.noop.updown')

Benchmark.ips do |x|
  x.report('noop counter#add')                 { noop_counter.add(1) }
  x.report('noop histogram#record')            { noop_histogram.record(1) }
  x.report('noop gauge#record')                { noop_gauge.record(1) }
  x.report('noop up_down_counter#add')         { noop_updown.add(1) }
  x.compare!
end
