# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

ENV['OTEL_RUBY_BSP_START_THREAD_ON_BOOT'] = 'false'

require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 85

require 'opentelemetry-test-helpers'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-base'
require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'pry'

OpenTelemetry.logger = Logger.new(File::NULL)
