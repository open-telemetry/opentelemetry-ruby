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

always_off_counter  = counter_with(exemplar_filter: Ex::AlwaysOffExemplarFilter)
always_on_counter   = counter_with(exemplar_filter: Ex::AlwaysOnExemplarFilter)
trace_based_counter = counter_with(exemplar_filter: Ex::TraceBasedExemplarFilter)

Benchmark.ips do |x|
  x.report('counter#add AlwaysOff filter')  { always_off_counter.add(1) }
  x.report('counter#add AlwaysOn filter')   { always_on_counter.add(1) }
  x.report('counter#add TraceBased filter') { trace_based_counter.add(1) }
  x.compare!
end
