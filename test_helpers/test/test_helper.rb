# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-sdk'
require 'opentelemetry-test-helpers'
require 'minitest/autorun'
require 'pry'

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end
