# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == "ruby"
  require "simplecov"
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end

require 'opentelemetry-test-helpers'
require 'opentelemetry'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new(File::NULL)
