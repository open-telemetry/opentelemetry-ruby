# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if ENV['ENABLE_COVERAGE'].to_i.positive?
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'opentelemetry/sdk'
require 'opentelemetry-propagator-ottrace'

OpenTelemetry.logger = Logger.new(File::NULL)
