# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'bench_helper'

def counter_with(exemplar_filter:, exemplar_reservoir: nil)
  meter = build_sdk_meter(exemplar_filter: exemplar_filter)
  meter.create_counter('bench.exemplar.counter', exemplar_reservoir: exemplar_reservoir)
end

def histogram_with(exemplar_filter:, exemplar_reservoir: nil)
  meter = build_sdk_meter(exemplar_filter: exemplar_filter)
  meter.create_histogram('bench.exemplar.histogram', exemplar_reservoir: exemplar_reservoir)
end

noop_res_counter   = counter_with(exemplar_filter: Ex::AlwaysOnExemplarFilter,
                                  exemplar_reservoir: Ex::NoopExemplarReservoir.new)
simple_res_counter = counter_with(exemplar_filter: Ex::AlwaysOnExemplarFilter,
                                  exemplar_reservoir: Ex::SimpleFixedSizeExemplarReservoir.new)

aligned_histogram = histogram_with(exemplar_filter: Ex::AlwaysOnExemplarFilter,
                                   exemplar_reservoir: Ex::AlignedHistogramBucketExemplarReservoir.new)
simple_histogram  = histogram_with(exemplar_filter: Ex::AlwaysOnExemplarFilter,
                                   exemplar_reservoir: Ex::SimpleFixedSizeExemplarReservoir.new)
noop_histogram    = histogram_with(exemplar_filter: Ex::AlwaysOnExemplarFilter,
                                   exemplar_reservoir: Ex::NoopExemplarReservoir.new)

Benchmark.ips do |x|
  x.report('counter  Noop reservoir')             { noop_res_counter.add(1) }
  x.report('counter  SimpleFixedSize reservoir')  { simple_res_counter.add(1) }
  x.report('histogram AlignedHistogramBucket')    { aligned_histogram.record(42) }
  x.report('histogram SimpleFixedSize reservoir') { simple_histogram.record(42) }
  x.report('histogram Noop reservoir')            { noop_histogram.record(42) }
  x.compare!
end
