# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'

INVALID_SPAN_ID = ("\0" * 8).b
INVALID_TRACE_ID = ("\0" * 16).b

def generate_trace_id
  loop do
    id = Random.bytes(16)
    return id unless id == INVALID_TRACE_ID
  end
end

def generate_trace_id_while
  id = Random.bytes(16)
  id = Random.bytes(16) while id == INVALID_TRACE_ID
  id
end

def generate_span_id
  loop do
    id = Random.bytes(8)
    return id unless id == INVALID_SPAN_ID
  end
end

def generate_span_id_while
  id = Random.bytes(8)
  id = Random.bytes(8) while id == INVALID_SPAN_ID
  id
end

Benchmark.ipsa do |x|
  x.report('generate_trace_id') { generate_trace_id }
  x.report('generate_trace_id_while') { generate_trace_id_while }
  x.compare!
end

Benchmark.ipsa do |x|
  x.report('generate_span_id') { generate_span_id }
  x.report('generate_span_id_while') { generate_span_id_while }
  x.compare!
end
