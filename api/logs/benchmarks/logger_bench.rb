# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ips'
require 'opentelemetry-logs-sdk'

logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new
logger = logger_provider.logger(name: 'bench', version: '1.0')

attributes = {
  'user.id' => '12345',
  'service.name' => 'bench_service'
}

context_with_span = OpenTelemetry::Trace.context_with_span(
  OpenTelemetry::Trace.non_recording_span(
    OpenTelemetry::Trace::SpanContext.new(
      trace_id: Random.bytes(16),
      span_id: Random.bytes(8),
      trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
    )
  )
)

Benchmark.ips do |x|
  x.report 'sdk logger#on_emit' do
    logger.on_emit
  end

  x.report 'sdk logger#on_emit with body' do
    logger.on_emit(body: 'something happened')
  end

  x.report 'sdk logger#on_emit with attributes' do
    logger.on_emit(attributes: attributes)
  end

  x.report 'sdk logger#on_emit with body and attributes' do
    logger.on_emit(body: 'something happened', attributes: attributes)
  end

  x.report 'sdk logger#on_emit with trace context' do
    logger.on_emit(context: context_with_span)
  end

  x.compare!
end
