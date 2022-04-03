# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 85

require 'opentelemetry-test-helpers'
require 'opentelemetry-instrumentation-base'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

OpenTelemetry.logger = Logger.new(File::NULL)
