# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'mysql2'

require 'opentelemetry/sdk'

require 'minitest/autorun'

require 'pry'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

def with_env(new_env)
  env_to_reset = ENV.select { |k, _| new_env.key?(k) }
  keys_to_delete = new_env.keys - ENV.keys
  new_env.each_pair { |k, v| ENV[k] = v }
  yield
  env_to_reset.each_pair { |k, v| ENV[k] = v }
  keys_to_delete.each { |k| ENV.delete(k) }
end
