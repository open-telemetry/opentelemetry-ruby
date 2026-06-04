# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ips'
require 'opentelemetry-logs-sdk'

small_attrs  = 1.upto(1).each_with_object({}) { |i, h| h["key.#{i}"] = "value_#{i}" }
medium_attrs = 1.upto(3).each_with_object({}) { |i, h| h["key.#{i}"] = "value_#{i}" }
large_attrs  = 1.upto(8).each_with_object({}) { |i, h| h["key.#{i}"] = "value_#{i}" }

Benchmark.ips do |x|
  x.report 'LogRecord.new with 1 attributes' do
    OpenTelemetry::SDK::Logs::LogRecord.new(attributes: small_attrs)
  end

  x.report 'LogRecord.new with 3 attributes' do
    OpenTelemetry::SDK::Logs::LogRecord.new(attributes: medium_attrs)
  end

  x.report 'LogRecord.new with 8 attributes' do
    OpenTelemetry::SDK::Logs::LogRecord.new(attributes: large_attrs)
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report 'LogRecord.new (minimal)' do
    OpenTelemetry::SDK::Logs::LogRecord.new
  end

  x.report 'LogRecord.new with body' do
    OpenTelemetry::SDK::Logs::LogRecord.new(body: 'something happened')
  end

  x.report 'LogRecord.new with attributes' do
    OpenTelemetry::SDK::Logs::LogRecord.new(attributes: small_attrs)
  end

  x.report 'LogRecord.new with body and attributes' do
    OpenTelemetry::SDK::Logs::LogRecord.new(
      body: 'something happened',
      attributes: small_attrs
    )
  end

  x.compare!
end
