# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'bundler/setup'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')

require 'opentelemetry-sdk'
require 'opentelemetry-exporter-otlp'
require 'opentelemetry/otelconfig'
require 'opentelemetry/test_helpers'

require 'minitest/autorun'
require 'minitest/spec'
require 'tempfile'

# Writes +yaml+ to a Tempfile and yields its path, then deletes the file.
def with_config(yaml)
  tmp = Tempfile.new(['otel-config', '.yaml'])
  tmp.write(yaml)
  tmp.close
  yield tmp.path
ensure
  tmp.unlink
end

# Reset after every test across all spec files.
Minitest::Spec.after do
  tp = OpenTelemetry.tracer_provider
  tp.shutdown if tp.respond_to?(:shutdown)

  OpenTelemetry::TestHelpers.reset_opentelemetry
end

# Shared minimal tracer_provider YAML used by end-to-end tests.
TRACER_PROVIDER_YAML = <<~PROVIDER
  tracer_provider:
    processors:
      - simple:
          exporter:
            console:
PROVIDER
