# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

# No view registered
no_view_counter = build_sdk_meter.create_counter('bench.view.counter')

# One matching view
match_counter = build_sdk_meter(
  views: [['bench.view.counter', { aggregation: Agg::Sum.new }]]
).create_counter('bench.view.counter')

# One non-matching view (different instrument name)
nomatch_counter = build_sdk_meter(
  views: [['other.counter', { aggregation: Agg::Sum.new }]]
).create_counter('bench.view.counter')

# Three matching views
multi_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
3.times { multi_provider.add_view('bench.view.counter', aggregation: Agg::Sum.new) }
multi_provider.add_metric_reader(new_reader)
multi_counter = multi_provider.meter('bench').create_counter('bench.view.counter')

Benchmark.ips do |x|
  x.report('counter#add (no view registered)')  { no_view_counter.add(1) }
  x.report('counter#add (1 non-matching view)') { nomatch_counter.add(1) }
  x.report('counter#add (1 matching view)')     { match_counter.add(1) }
  x.report('counter#add (3 matching views)')    { multi_counter.add(1) }
  x.compare!
end
