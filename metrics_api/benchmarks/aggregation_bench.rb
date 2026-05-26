# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

def histogram_with_agg(aggregation)
  provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
  provider.add_view('bench.agg.histogram', aggregation: aggregation)
  provider.add_metric_reader(new_reader)
  provider.meter('bench').create_histogram('bench.agg.histogram')
end

explicit_hist    = histogram_with_agg(Agg::ExplicitBucketHistogram.new)
exponential_hist = histogram_with_agg(Agg::ExponentialBucketHistogram.new)
sum_hist         = histogram_with_agg(Agg::Sum.new)
last_value_hist  = histogram_with_agg(Agg::LastValue.new)
drop_hist        = histogram_with_agg(Agg::Drop.new)

Benchmark.ips do |x|
  x.report('histogram ExplicitBucketHistogram')    { explicit_hist.record(42) }
  x.report('histogram ExponentialBucketHistogram') { exponential_hist.record(42) }
  x.report('histogram Sum aggregation')            { sum_hist.record(42) }
  x.report('histogram LastValue aggregation')      { last_value_hist.record(42) }
  x.report('histogram Drop aggregation')           { drop_hist.record(42) }
  x.compare!
end
