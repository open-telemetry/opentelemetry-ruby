# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter '/test/'
  end

  SimpleCov.minimum_coverage 85
end

require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/otlp_logs'
require 'minitest/autorun'
require 'webmock/minitest'
require 'minitest/stub_const'

OpenTelemetry.logger = Logger.new(File::NULL)
